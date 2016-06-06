package cn.reactnative.modules.qq;

import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.UiThreadUtil;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.RCTNativeAppEventEmitter;
import com.tencent.connect.common.Constants;
import com.tencent.connect.share.QQShare;
import com.tencent.tauth.IUiListener;
import com.tencent.tauth.Tencent;
import com.tencent.tauth.UiError;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Date;

/**
 * Created by tdzl2_000 on 2015-10-10.
 */
public class QQModule extends ReactContextBaseJavaModule implements IUiListener, ActivityEventListener {
    private String appId;
    private Tencent api;
    private final static String INVOKE_FAILED = "QQ API invoke returns false.";
    private boolean isLogin;

    private static final String RCTQQShareTypeNews = "news";
    private static final String RCTQQShareTypeImage = "image";
    private static final String RCTQQShareTypeText = "text";
    private static final String RCTQQShareTypeVideo = "video";
    private static final String RCTQQShareTypeAudio = "audio";

    private static final String RCTQQShareType = "type";
    private static final String RCTQQShareText = "text";
    private static final String RCTQQShareTitle = "title";
    private static final String RCTQQShareDescription = "description";
    private static final String RCTQQShareWebpageUrl = "webpageUrl";
    private static final String RCTQQShareImageUrl = "imageUrl";

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
    }

    @Override
    public void initialize() {
        super.initialize();

        if (api == null) {
            api = Tencent.createInstance(appId, getReactApplicationContext().getApplicationContext());
        }
        getReactApplicationContext().addActivityEventListener(this);
    }

    @Override
    public void onCatalystInstanceDestroy() {

        if (api != null){
            api = null;
        }
        getReactApplicationContext().removeActivityEventListener(this);

        super.onCatalystInstanceDestroy();
    }

    @Override
    public String getName() {
        return "RCTQQAPI";
    }

    @ReactMethod
    public void login(String scopes, Callback callback){
        this.isLogin = true;
        if (!api.isSessionValid()){
            api.login(getCurrentActivity(), scopes == null ? "get_simple_userinfo" : scopes, this);
            callback.invoke();
        } else {
            callback.invoke(INVOKE_FAILED);
        }
    }

    @ReactMethod
    public void shareToQQ(final ReadableMap data, final Callback callback){
        UiThreadUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                _shareToQQ(data, 0, callback);
            }
        });
    }

    @ReactMethod
    public void shareToQzone(final ReadableMap data, final Callback callback)
    {
        UiThreadUtil.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                _shareToQQ(data, 1, callback);
            }
        });
    }

    private void _shareToQQ(ReadableMap data, int scene, Callback callback) {
        this.isLogin = false;
        Bundle bundle = new Bundle();
        if (data.hasKey(RCTQQShareTitle)){
            bundle.putString(QQShare.SHARE_TO_QQ_TITLE, data.getString(RCTQQShareTitle));
        }
        if (data.hasKey(RCTQQShareDescription)){
            bundle.putString(QQShare.SHARE_TO_QQ_SUMMARY, data.getString(RCTQQShareDescription));
        }
        if (data.hasKey(RCTQQShareWebpageUrl)){
            bundle.putString(QQShare.SHARE_TO_QQ_TARGET_URL, data.getString(RCTQQShareWebpageUrl));
        }
        if (data.hasKey(RCTQQShareImageUrl)){
            if (scene == 0) {
                bundle.putString(QQShare.SHARE_TO_QQ_IMAGE_URL, data.getString(RCTQQShareImageUrl));
            }
            else if (scene == 1) {
                ArrayList<String> out = new ArrayList<>();
                out.add(data.getString(RCTQQShareImageUrl));
                bundle.putStringArrayList(QQShare.SHARE_TO_QQ_IMAGE_URL, out);
            }
        }
        if (data.hasKey("appName")){
            bundle.putString(QQShare.SHARE_TO_QQ_APP_NAME, data.getString("appName"));
        }

        String type = RCTQQShareTypeNews;
        if (data.hasKey(RCTQQShareType)) {
            type = data.getString(RCTQQShareType);
        }

        if (type.equals(RCTQQShareTypeNews)){
            bundle.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_DEFAULT);
        } else if (type.equals(RCTQQShareTypeImage)){
            bundle.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_IMAGE);
        } else if (type.equals(RCTQQShareTypeAudio)) {
            bundle.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_AUDIO);
            if (data.hasKey("flashUrl")){
                bundle.putString(QQShare.SHARE_TO_QQ_AUDIO_URL, data.getString("flashUrl"));
            }
        } else if (type.equals("app")){
            bundle.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_APP);
        }

        Log.e("QQShare", bundle.toString());
        if (scene == 0 ) {
            api.shareToQQ(getCurrentActivity(), bundle, this);
        }
        else if (scene == 1) {
            api.shareToQzone(getCurrentActivity(), bundle, this);
        }
        callback.invoke();
    }

    private String _getType() {
        return (this.isLogin?"QQAuthorizeResponse":"QQShareResponse");
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        Tencent.onActivityResultData(requestCode, resultCode, data, this);
    }

    @Override
    public void onComplete(Object o) {
        try {
            JSONObject obj = (JSONObject)(o);

            WritableMap map = Arguments.createMap();
            map.putInt("errCode", 0);
            map.putString("type", _getType());
            if (isLogin) {
                map.putString("openid", obj.getString(Constants.PARAM_OPEN_ID));
                map.putString("access_token", obj.getString(Constants.PARAM_ACCESS_TOKEN));
                map.putString("oauth_consumer_key", this.appId);
                map.putDouble("expires_in", (new Date().getTime() + obj.getLong(Constants.PARAM_EXPIRES_IN)));
            }

            getReactApplicationContext()
                    .getJSModule(RCTNativeAppEventEmitter.class)
                    .emit("QQ_Resp", map);

        } catch (Exception e){
            WritableMap map = Arguments.createMap();
            map.putInt("errCode", Constants.ERROR_UNKNOWN);
            map.putString("errMsg", e.getLocalizedMessage());
            map.putString("type", _getType());

            getReactApplicationContext()
                    .getJSModule(RCTNativeAppEventEmitter.class)
                    .emit("QQ_Resp", map);
        }
    }

    @Override
    public void onError(UiError uiError) {
        WritableMap map = Arguments.createMap();
        map.putInt("err", uiError.errorCode);
        map.putString("errMsg", uiError.errorMessage);
        map.putString("type", _getType());

        getReactApplicationContext()
                .getJSModule(RCTNativeAppEventEmitter.class)
                .emit("QQ_Resp", map);
    }

    @Override
    public void onCancel() {
        WritableMap map = Arguments.createMap();
        map.putInt("err", -1);
        map.putString("errMsg", "Canceled.");
        map.putString("type", _getType());

        getReactApplicationContext()
                .getJSModule(RCTNativeAppEventEmitter.class)
                .emit("QQ_Resp", map);
    }
}
