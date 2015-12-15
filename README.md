# react-native-qq

React Native的QQ登录插件

## 如何安装

### 首先安装npm包

```bash
npm install react-native-qq --save
```

### 安装Android工程

在`android/settings.gradle`里添加如下代码：

```
include ':react-native-qq'
project(':react-native-qq').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-qq/android')
```

在`android/app/build.gradle`里的`dependencies`结构中添加如下代码：

```
dependencies{
    ... // 原本的代码
    compile project(':react-native-qq')
}
```

在`android/app/src/main/AndroidManifest.xml`里，`<manifest>`标签中添加如下代码：

```
	<uses-permission android:name="android.permission.INTERNET" />
	<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

`<application>`标签中添加如下代码：

```
		<!-- QQ的APPID -->
        <meta-data android:name="QQ_APPID" android:value="${QQ_APPID}"/>
        <!-- QQ接入的回调Activity和辅助Activity -->
        <activity
            android:name="com.tencent.tauth.AuthActivity"
            android:noHistory="true"
            android:launchMode="singleTask" >
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="${QQ_APPID}" />
            </intent-filter>
        </activity>
        <activity android:name="com.tencent.connect.common.AssistActivity"
            android:theme="@android:style/Theme.Translucent.NoTitleBar"
            android:configChanges="orientation|keyboardHidden|screenSize"
            />
```

`android/app/build.gradle`里，defaultConfig栏目下添加如下代码：

```
		manifestPlaceholders = [
            QQ_APPID: "<平台申请的APPID>"
        ]
```

以后如果需要修改APPID，只需要修改此一处。


`android/app/src/main/java/<你的包名>/MainActivity.java`中，`public class MainActivity`之前增加：

```java
import cn.reactnative.modules.qq.QQPackage;
```

`.addPackage(new MainReactPackage())`之后增加：

```java
                .addPackage(new QQPackage())
```

另外，确保你的MainActivity.java中有`onActivityResult`的实现：

```java
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data){
        super.onActivityResult(requestCode, resultCode, data);
        mReactInstanceManager.onActivityResult(requestCode, resultCode, data);
    }
```

## 如何使用

### 引入包

```
import * as QQAPI from 'react-native-qq';
```

### API

#### QQAPI.login([scopes])

调用QQ登录，可能会跳转到QQ应用或者打开一个网页浏览器以供用户登录。在本次login返回前，所有接下来的login调用都会直接失败。

返回一个`Promise`对象。成功时的回调为一个类似这样的对象：

```javascript
{
	"accessToken": "CAF0085A2AB8FDE7903C97F4792ECBC3",
	"openId": "0E00BA738F6BB55731A5BBC59746E88D"
}
```

#### QQAPI.shareToQQ(data)

分享到QQ好友，参数同QQAPI.shareToQzone，返回一个`Promise`对象

#### QQAPI.shareToQzone(data)

分享到QZone，参数为一个object，可以有如下的形式：

```javascript
// 分享图文消息
{	
	type: 'news',
	title: 分享标题,
	description: 描述,
	webpageUrl: 网页地址,
	imageUrl: 远程图片地址,
}

// 其余格式尚未实现。
```

## 常见问题

#### Android: 调用QQAPI.login()没有反应

通常出现这个原因是因为Manifest没有配置好，检查Manifest中有关Activity的配置。

#### Android: 已经成功激活QQ登录，但回调没有被执行

通常出现这个原因是因为MainActivity.java中缺少onActivityResult的调用。
