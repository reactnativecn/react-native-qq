/**
 * Created by Yun on 2015-12-12.
 */
import {NativeModules, NativeAppEventEmitter} from 'react-native';

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

export const isQQInstalled = QQAPI.isQQInstalled;
export const isQQSupportApi = QQAPI.isQQSupportApi;

// Save callback and wait for future event.
let savedCallback = undefined;
function waitForResponse(r, type) {
    return new Promise((resolve, reject) => {
        let res = JSON.parse(r.result);
		if(res.ret==0){
			resolve(res);
		}else{
			reject(type+' err');
		}
    });
}

NativeAppEventEmitter.addListener('QQ_Resp', resp => {
    const callback = savedCallback;
    savedCallback = undefined;
    callback && callback(resp);
});

export function login(scopes) {
    return QQAPI.login(scopes)
        .then((r) => waitForResponse(r, "login"));
}

export function shareToQQ(data={}) {
    return QQAPI.shareToQQ(data)
        .then((r) => waitForResponse(r, "qqshare"));
}

export function shareToQzone(data={}) {
    return QQAPI.shareToQzone(data)
        .then((r) => waitForResponse(r, "qqzoneshare"));
}

export function logout(){
    QQAPI.logout()
}




