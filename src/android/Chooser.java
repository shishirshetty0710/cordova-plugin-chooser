package com.cyph.cordova;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;
import android.util.Base64;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.lang.Exception;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;


public class Chooser extends CordovaPlugin {
	private static final String ACTION_OPEN = "getFile";
	private static final String ACTION_OPEN_MANY = "getFiles";
	private static final int PICK_FILE_REQUEST = 1;
	private static final String TAG = "Chooser";
	private CallbackContext callback;

	@Override
	public boolean execute (String action, JSONArray args, CallbackContext callbackContext) {
		try {
			if (action.equals(Chooser.ACTION_OPEN)) {
				this.chooseFile(callbackContext, args.getString(0), false);
				return true;
			} else if (action.equals(Chooser.ACTION_OPEN_MANY)) {
				this.chooseFile(callbackContext, args.getString(0), true);
				return true;
			}
		}
		catch (JSONException err) {
			this.callback.error("Execute failed: " + err.toString());
		}

		return false;
	}

	private void chooseFile (CallbackContext callbackContext, String accept, boolean allowMultiple) {
		Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
		intent.setType("*/*");
		if (!accept.equals("*/*")) {
			intent.putExtra(Intent.EXTRA_MIME_TYPES, accept.split(","));
		}
		intent.addCategory(Intent.CATEGORY_OPENABLE);
		intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, allowMultiple);
		intent.putExtra(Intent.EXTRA_LOCAL_ONLY, true);

		Intent chooser = Intent.createChooser(intent, "Select File");
		cordova.startActivityForResult(this, chooser, Chooser.PICK_FILE_REQUEST);

		PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
		pluginResult.setKeepCallback(true);
		this.callback = callbackContext;
		callbackContext.sendPluginResult(pluginResult);
	}

	@Override
	public void onActivityResult (int requestCode, int resultCode, Intent data) {
		try {
			if (requestCode == Chooser.PICK_FILE_REQUEST && this.callback != null) {
				if (resultCode == Activity.RESULT_OK) {
					if (null != data) {
						ContentResolver contentResolver =
							this.cordova.getActivity().getContentResolver();

						JSONObject result = new JSONObject();
						JSONArray arr = new JSONArray();

						if (null != data.getClipData()) {
							for (int i = 0; i < data.getClipData().getItemCount(); i++) {
								Uri uri = data.getClipData().getItemAt(i).getUri();
								JSONObject file = getFileFromUri(contentResolver, uri);
								arr.put(file);
							}
						} else {
							Uri uri = data.getData();
							JSONObject file = getFileFromUri(contentResolver, uri);
							arr.put(file);
						}

						result.put("result", arr);
						this.callback.success(result.toString());
					} else {
						this.callback.error("File URI was null.");
					}					
				}
				else if (resultCode == Activity.RESULT_CANCELED) {
					this.callback.success("RESULT_CANCELED");
				}
				else {
					this.callback.error(resultCode);
				}
			}
		}
		catch (Exception err) {
			this.callback.error("Failed to read file: " + err.toString());
		}
	}

	private static JSONObject getFileFromUri (ContentResolver contentResolver, Uri uri) throws JSONException {
		JSONObject result = new JSONObject();

		String name = Chooser.getDisplayName(contentResolver, uri);

		String mediaType = contentResolver.getType(uri);
		if (mediaType == null || mediaType.isEmpty()) {
			mediaType = "application/octet-stream";
		}

		result.put("name", name);
		result.put("mediaType", mediaType);
		result.put("uri", uri.toString());
		return result;
	}
	
	/** @see https://stackoverflow.com/a/23270545/459881 */
	private static String getDisplayName (ContentResolver contentResolver, Uri uri) {
		String[] projection = {MediaStore.MediaColumns.DISPLAY_NAME};
		Cursor metaCursor = contentResolver.query(uri, projection, null, null, null);

		if (metaCursor != null) {
			try {
				if (metaCursor.moveToFirst()) {
					return metaCursor.getString(0);
				}
			} finally {
				metaCursor.close();
			}
		}

		return "File";
	}
}
