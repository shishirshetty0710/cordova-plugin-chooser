import UIKit
import MobileCoreServices
import Foundation


@objc(Chooser)
class Chooser : CDVPlugin {
	var commandCallback: String?

	class File {
		var name: String
		var mimeType: String
		var uri: String
		init(name: String, mimeType: String, uri: String) {
			self.name = name
			self.mimeType = mimeType
			self.uri = uri
		}
	}

	@objc(getFile:)
	func getFile (command: CDVInvokedUrlCommand) {
		self.commandCallback = command.callbackId

		let accept = command.arguments.first as! String
		self.getFilesInternal(accept: accept, allowMultiple: false)
	}

	@objc(getFiles:)
	func getFiles (command: CDVInvokedUrlCommand) {
		self.commandCallback = command.callbackId

		let accept = command.arguments.first as! String
		self.getFilesInternal(accept: accept, allowMultiple: true)
	}

	func getFilesInternal (accept: String, allowMultiple: Bool) {
		let mimeTypes = accept.components(separatedBy: ",")

		let utis = mimeTypes.map { (mimeType: String) -> String in
			switch mimeType {
				case "audio/*":
					return kUTTypeAudio as String
				case "font/*":
					return "public.font"
				case "image/*":
					return kUTTypeImage as String
				case "text/*":
					return kUTTypeText as String
				case "video/*":
					return kUTTypeVideo as String
				default:
					break
			}

			if mimeType.range(of: "*") == nil {
				let utiUnmanaged = UTTypeCreatePreferredIdentifierForTag(
					kUTTagClassMIMEType,
					mimeType as CFString,
					nil
				)

				if let uti = (utiUnmanaged?.takeRetainedValue() as? String) {
					if !uti.hasPrefix("dyn.") {
						return uti
					}
				}
			}

			return kUTTypeData as String
		}

		self.callPicker(utis: utis, allowMultiple: allowMultiple)
	}

	func callPicker (utis: [String], allowMultiple: Bool) {
		let picker = UIDocumentPickerViewController(documentTypes: utis, in: .import)
		picker.delegate = self
		self.viewController.present(picker, animated: false) {
			if #available(iOS 11.0, *) {
				picker.allowsMultipleSelection = allowMultiple;
			}
		}
	}

	func detectMimeType (_ url: URL) -> String {
		if let uti = UTTypeCreatePreferredIdentifierForTag(
			kUTTagClassFilenameExtension,
			url.pathExtension as CFString,
			nil
		)?.takeRetainedValue() {
			if let mimetype = UTTypeCopyPreferredTagWithClass(
				uti,
				kUTTagClassMIMEType
			)?.takeRetainedValue() as? String {
				return mimetype
			}
		}

		return "application/octet-stream"
	}

	func documentWasSelected (urls: [URL]) {
		var error: NSError?

		let result:NSMutableDictionary = NSMutableDictionary()
		let arr::NSMutableArray = NSMutableArray()

		do {
			for url in urls {
				let file:NSMutableDictionary = NSMutableDictionary()
				file.setValue(url.lastPathComponent, forKey: "name")
				file.setValue(self.detectMimeType(url), forKey: "mimeType")
				file.setValue(url.absoluteString, forKey: "uri")
				arr.addObject(file)
			}
			result.setObject(arr, "result")

			if let message = try String(
				data: JSONSerialization.data(
					withJSONObject: result,
					options: []
				),
				encoding: String.Encoding.utf8
			) {
				self.send(message)
			}
			else {
				self.sendError("Serializing result failed.")
			}
		}
		catch let error {
			self.sendError(error.localizedDescription)
		}

		if let error = error {
			self.sendError(error.localizedDescription)
		}
	}

	func send (_ message: String, _ status: CDVCommandStatus = CDVCommandStatus_OK) {
		if let callbackId = self.commandCallback {
			self.commandCallback = nil

			let pluginResult = CDVPluginResult(
				status: status,
				messageAs: message
			)

			self.commandDelegate!.send(
				pluginResult,
				callbackId: callbackId
			)
		}
	}

	func sendError (_ message: String) {
		self.send(message, CDVCommandStatus_ERROR)
	}
}

extension Chooser : UIDocumentPickerDelegate {
	@available(iOS 11.0, *)
	func documentPicker (
		_ controller: UIDocumentPickerViewController,
		didPickDocumentsAt urls: [URL]
	) {
		self.documentWasSelected(urls: urls)
	}

	func documentPicker (
		_ controller: UIDocumentPickerViewController,
		didPickDocumentAt url: URL
	) {
		let urls = [url]
		self.documentWasSelected(urls: urls)
	}

	func documentPickerWasCancelled (_ controller: UIDocumentPickerViewController) {
		self.send("RESULT_CANCELED")
	}
}
