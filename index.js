/**
 * Created by Yun on 2015-12-12.
 */
import {NativeModules, NativeAppEventEmitter} from 'react-native';
import promisify from 'es6-promisify';

const {QQAPI} = NativeModules;

function translateError(err, result) {
    if (!err) {
        return this.resolve(result);
    }
    if (typeof err === 'object') {
        if (err instanceof Error) {
            return this.reject(ret);
        }
        return this.reject(Object.assign(new Error(err.message), { errCode: err.errCode }));
    } else if (typeof err === 'string') {
        return this.reject(new Error(err));
    }
    this.reject(Object.assign(new Error(), { origin: err }));
}

function wrapCheckApi(nativeFunc) {
    if (!nativeFunc) {
        return undefined;
    }

    const promisified = promisify(nativeFunc, translateError);
    return (...args) => {
        return promisified(...args);
    };
}

export const isQQInstalled = wrapCheckApi(QQAPI.isQQInstalled);
export const isQQSupportApi = wrapCheckApi(QQAPI.isQQSupportApi);

function wrapApi(nativeFunc) {
    if (!nativeFunc) {
        return undefined;
    }
    const promisified = promisify(nativeFunc, translateError);
    return (...args) => {
        return promisified(...args);
    };
}

// Save callback and wait for future event.
let savedCallback = undefined;
function waitForResponse(type) {
    return new Promise((resolve, reject) => {
        if (savedCallback) {
            savedCallback('User canceled.');
        }
        savedCallback = result => {
            if (result.type !== type) {
                return;
            }
            savedCallback = undefined;
            if (result.errCode !== 0) {
                const err = new Error(result.errMsg);
                err.errCode = result.errCode;
                reject(err);
            } else {
                const {type, ...r} = result
                resolve(r);
            }
        };
    });
}

NativeAppEventEmitter.addListener('QQ_Resp', resp => {
    const callback = savedCallback;
    savedCallback = undefined;
    callback && callback(resp);
});

const nativeSendAuthRequest = wrapApi(QQAPI.login);
const nativeShareToQQRequest = wrapApi(QQAPI.shareToQQ);
const nativeShareToQzoneRequest = wrapApi(QQAPI.shareToQzone);


export function login(scopes) {
    return nativeSendAuthRequest(scopes)
        .then(() => waitForResponse("QQAuthorizeResponse"));
}

export function shareToQQ(data={}) {
    return nativeShareToQQRequest(data)
        .then(() => waitForResponse("QQShareResponse"));
}

export function shareToQzone(data={}) {
    return nativeShareToQzoneRequest(data)
        .then(() => waitForResponse("QQShareResponse"));
}

export function logout(){
    QQAPI.logout()
}




