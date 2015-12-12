/**
 * Created by Yun on 2015-12-12.
 */
import {NativeModules} from 'react-native';

let nativeQQAPI = NativeModules.QQAPI;

if (!nativeQQAPI){
  setTimeout(()=>{
    throw new Error("Cannot get native modules of react-native-qq.");
  }, 100);
}

export class QQAPIError extends Error {
  constructor(err, msg){
    super(msg || "Error occured with QQ API.");
    this.err = err;
  }
}

function translateError(e){
  if (typeof(e) == 'object' && !(e instanceof  Error)){
    throw new QQAPIError(e.err, e.errMsg);
  }
}

export function login(scopes){
  return new Promise((resolve, reject)=>{
    nativeQQAPI.login(scopes, resolve, reject)
  }).catch(translateError)
}

export function shareToQQ(data){
  return new Promise((resolve, reject)=>{
    nativeQQAPI.shareToQQ(data, resolve, reject);
  }).catch(translateError)
}

export function shareToQzone(data){
  return new Promise((resolve, reject)=>{
    nativeQQAPI.shareToQzone(data, resolve, reject);
  }).catch(translateError)
}
