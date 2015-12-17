package cn.reactnative.modules.qq;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.tencent.connect.common.Constants;
import com.tencent.connect.share.QQShare;
import com.tencent.tauth.IUiListener;
import com.tencent.tauth.Tencent;
import com.tencent.tauth.UiError;

import org.json.JSONObject;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Date;

/**
 * Created by tdzl2_000 on 2015-10-10.
 */
public class QQModule extends ReactContextBaseJavaModule implements IUiListener, ActivityEventListener {
    private String appId;
    private Tencent api;
    public QQModule(ReactApplicationContext context) {
        super(context);
        ApplicationInfo appInfo = null;
        try {
            appInfo = context.getPackageManager().getApplicationInfo(context.getPackageName(), PackageManager.GET_META_DATA);
        } catch (PackageManager.NameNotFoundException e) {
            throw new Error(e);
        }
        if (!appInfo.metaData.containsKey("QQ_APPID")){
            throw new Error("meta-data QQ_APPID not found in AndroidManifest.xml");
        }
        this.appId = appInfo.metaData.get("QQ_APPID").toString();

        context.addActivityEventListener(this);
    }

    private Activity getMainActivity(){
        ReactContext context = getReactApplicationContext();
        Field[] fields = ReactContext.class.getDeclaredFields();
        for (Field field : fields){
            if (field.getName().equals("mCurrentActivity")){
                field.setAccessible(true);
                try {
                    return (Activity)field.get(context);
                }catch (Throwable e){
                    Log.e("ReactNative", e.getMessage(), e);
                }
            }
        }
        return null;
    }

    @Override
    public String getName() {
        return "RCTQQAPI";
    }

    @ReactMethod
    public void login(String scopes, Callback resolve, Callback reject){
        _setCallback(new PromiseCallback(resolve, reject));
        if (!api.isSessionValid()){
            api.login(getMainActivity(), scopes == null ? "get_simple_userinfo" : scopes, this);
        } else {
            _resolve();
        }
    }

    @ReactMethod
    public void shareToQQ(ReadableMap data, Callback resolve, Callback reject){
        _setCallback(new PromiseCallback(resolve, reject));

        _shareToQQ(data, 0);
    }

    @ReactMethod
    public void shareToQzone(ReadableMap data, Callback resolve, Callback reject){
        _setCallback(new PromiseCallback(resolve, reject));

        _shareToQQ(data, 1);
    }

    private void _shareToQQ(ReadableMap data, int scene) {
        Bundle bundle = new Bundle();
        if (data.hasKey("title")){
            bundle.putString(QQShare.SHARE_TO_QQ_TITLE, data.getString("title"));
        }
        if (data.hasKey("description")){
            bundle.putString(QQShare.SHARE_TO_QQ_SUMMARY, data.getString("description"));
        }
        if (data.hasKey("webpageUrl")){
            bundle.putString(QQShare.SHARE_TO_QQ_TARGET_URL, data.getString("webpageUrl"));
        }
        if (data.hasKey("imageUrl")){
            if (scene == 0) {
                bundle.putString(QQShare.SHARE_TO_QQ_IMAGE_URL, data.getString("imageUrl"));
            }
            else if (scene == 1) {
                ArrayList<String> out = new ArrayList<>();
                out.add(data.getString("imageUrl"));
                bundle.putStringArrayList(QQShare.SHARE_TO_QQ_IMAGE_URL, out);
            }
        }
        if (data.hasKey("appName")){
            bundle.putString(QQShare.SHARE_TO_QQ_APP_NAME, data.getString("appName"));
        }

        if (!data.hasKey("type") || data.getString("type").equals("news")){
            bundle.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_DEFAULT);
        } else if (data.getString("type").equals("image")){
            bundle.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_IMAGE);

        } else if (data.getString("type").equals("audio")) {
            bundle.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_AUDIO);
            if (data.hasKey("flashUrl")){
                bundle.putString(QQShare.SHARE_TO_QQ_AUDIO_URL, data.getString("flashUrl"));
            }
        } else if (data.getString("type").equals("app")){
            bundle.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_APP);
        }

        if (scene == 0 ) {
            api.shareToQQ(getMainActivity(), bundle, this);
        }
        else if (scene == 1) {
            api.shareToQzone(getMainActivity(), bundle, this);
        }
    }

    @Override
    public void initialize() {
        if (api == null) {
            api = Tencent.createInstance(appId, getReactApplicationContext().getApplicationContext());
        }
        super.initialize();
    }

    @Override
    public void onCatalystInstanceDestroy() {
        if (api != null){
            api = null;
        }
        super.onCatalystInstanceDestroy();
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        Tencent.onActivityResultData(requestCode, resultCode, data, this);
    }

    @Override
    public void onComplete(Object o) {
        try {
            JSONObject obj = (JSONObject)(o);
//            Log.e("QQModule", obj.toString());

            WritableMap map = Arguments.createMap();
            map.putString("openid", obj.getString("openid"));
            map.putString("access_token", obj.getString("access_token"));
            map.putString("oauth_consumer_key", this.appId);
            map.putDouble("expires_in", (new Date().getTime() + obj.getLong("expires_in")));

            _resolve(map);
        } catch (Exception e){
            WritableMap map = Arguments.createMap();
            map.putInt("err", Constants.ERROR_UNKNOWN);
            map.putString("errMsg", e.getLocalizedMessage());
            _reject(map);
        }
    }

    @Override
    public void onError(UiError uiError) {
        WritableMap map = Arguments.createMap();
        map.putInt("err", uiError.errorCode);
        map.putString("errMsg", uiError.errorMessage);
        map.putString("errDetail", uiError.errorDetail);
        _reject(map);
    }

    @Override
    public void onCancel() {
        WritableMap map = Arguments.createMap();
        map.putInt("err", -1001);
        map.putString("errMsg", "Canceled.");
        _reject(map);
    }

    private class PromiseCallback{
        private PromiseCallback(Callback resolve, Callback reject){
            this.resolve = resolve;
            this.reject = reject;
        }
        private Callback resolve;
        private Callback reject;
    }
    private PromiseCallback callback;

    private void _setCallback(PromiseCallback callback){
        if (this.callback != null){
            WritableMap event = Arguments.createMap();
            event.putInt("err", Constants.ERROR_UNKNOWN);
            _reject(event);
        }
        this.callback = callback;
    }
    private void _reject(WritableMap event){
        if (callback != null){
            callback.reject.invoke(event);
            callback = null;
        }
    }

    private void _resolve(){
        if (callback != null){
            callback.resolve.invoke();
            callback = null;
        }
    }

    private void _resolve(Object event){
        if (callback != null){
            callback.resolve.invoke(event);
            callback = null;
        }
    }
}
