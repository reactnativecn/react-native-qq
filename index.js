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

function translateError(e){
  if (typeof(e) === 'object'){
    if(e instanceof  Error)
    {
      throw e;
    }
    else {
      let error = new Error(e.errMsg || "login error")
      error.code = e.err
      throw error;
    }
  }
  else {
    throw new Error("unkown qq login error")
  }
}

export function login(scopes){
  return new Promise((resolve, reject)=>{
    nativeQQAPI.login(scopes, resolve, reject)
  }).catch(translateError)
}

export function logout(){
  nativeQQAPI.logout()
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



