module.exports = {
    getFile: function (accept, successCallback, failureCallback) {
        var result = new Promise(function (resolve, reject) {
            cordova.exec(
                function (json) {
                    if (json === 'RESULT_CANCELED') {
                        resolve();
                        return;
                    }

                    try {
                        var o = JSON.parse(json);
                        resolve(o);
                    }
                    catch (err) {
                        reject(err);
                    }
                },
                reject,
                'Chooser',
                'getFile',
                [(typeof accept === 'string' ? accept.replace(/\s/g, '') : undefined) || '*/*']
            );
        });

        if (typeof successCallback === 'function') {
            result.then(successCallback);
        }
        if (typeof failureCallback === 'function') {
            result.catch(failureCallback);
        }

        return result;
    },

    getFiles: function(accept, successCallback, failureCallback) {
        var result = new Promise(function (resolve, reject) {
            cordova.exec(
                function (json) {
                    if (json === 'RESULT_CANCELED') {
                        resolve();
                        return;
                    }

                    try {
                        var o = JSON.parse(json);
                        resolve(o);
                    }
                    catch (err) {
                        reject(err);
                    }
                },
                reject,
                'Chooser',
                'getFiles',
                [(typeof accept === 'string' ? accept.replace(/\s/g, '') : undefined) || '*/*']
            );
        });

        if (typeof successCallback === 'function') {
            result.then(successCallback);
        }
        if (typeof failureCallback === 'function') {
            result.catch(failureCallback);
        }

        return result;
    }
};
