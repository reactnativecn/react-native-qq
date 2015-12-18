//
//  QQAPI.m
//  RNThirdShareMangager
//
//  Created by LvBingru on 10/10/15.
//  Copyright © 2015 erica. All rights reserved.
//

#import "RCTQQAPI.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/TencentOAuthObject.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/QQApiInterfaceObject.h>
#import "RCTImageLoader.h"
#import "RCTBridge.h"
#import "RCTLog.h"

static TencentOAuth* _qqapi;

@interface RCTQQAPI()<QQApiInterfaceDelegate, TencentSessionDelegate>

@property (nonatomic, copy) RCTResponseSenderBlock resolveBlockShare;
@property (nonatomic, copy) RCTResponseSenderBlock rejectBlockShare;
@property (nonatomic, copy) RCTResponseSenderBlock resolveBlockLogin;
@property (nonatomic, copy) RCTResponseSenderBlock rejectBlockLogin;

@end

@implementation RCTQQAPI

+ (instancetype)sharedAPI
{
    static RCTQQAPI *_sharedAPI = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedAPI = [[[self class] alloc] init];
    });
    
    return _sharedAPI;
}

+ (void)registerAPI:(NSString *)aString
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RCTQQAPI *api = [RCTQQAPI sharedAPI];
        if (_qqapi == nil) {
            _qqapi = [[TencentOAuth alloc] initWithAppId:aString andDelegate:api];
        }
    });
}

+ (BOOL)handleUrl:(NSURL *)aUrl
{
    if ([TencentOAuth HandleOpenURL:aUrl])
    {
        return YES;
    }
    return NO;
}

#pragma mark - qq delegate
- (void)onReq:(QQBaseReq *)req
{
    
}

- (void)onResp:(QQBaseResp *)resp
{
    RCTLogInfo(@"%@",resp.result);
    
    self.resolveBlockShare = nil;
    self.rejectBlockShare = nil;
}

- (void)isOnlineResponse:(NSDictionary *)response
{
    
}

#pragma mark - oauth delegate
- (void)tencentDidLogin
{
    self.resolveBlockLogin(@[@{
                             @"openid":_qqapi.openId,
                             @"access_token":_qqapi.accessToken,
                             @"expires_in":@([_qqapi.expirationDate timeIntervalSince1970]),
                             @"oauth_consumer_key":_qqapi.appId
                             }]);
    self.resolveBlockLogin = nil;
    self.rejectBlockLogin = nil;
}

- (void)tencentDidNotLogin:(BOOL)cancelled
{
    self.rejectBlockLogin(@[@{@"err":@(-1001),@"errMsg":@"Canceled."}]);
    self.resolveBlockLogin = nil;
    self.rejectBlockLogin = nil;
}

- (void)tencentDidNotNetWork
{
}

- (void)getUserInfoResponse:(APIResponse*)response
{
}

+ (void)shareToQQWithData:(NSDictionary *)aData scene:(int)aScene
{
    NSString *type = aData[RCTQQShareType];
    
    NSString *title = aData[RCTQQShareTitle];
    if (title == nil) {
        [RCTQQAPI sharedAPI].rejectBlockShare(@[@{@"err":@(-1001),@"errMsg":@"title不能为空"}]);
        return;
    }
    
    NSString *description= aData[RCTQQShareDescription];
    NSString *imgPath = aData[RCTQQShareImageUrl];
    NSString *webpageUrl = aData[RCTQQShareWebpageUrl]? :@"";
    NSString *flashUrl = aData[@"flashUrl"];

    QQApiObject *message = nil;
    
    if (type.length <=0 || [type isEqualToString: RCTQQShareTypeNews]) {
        message = [QQApiNewsObject
                                    objectWithURL:[NSURL URLWithString:webpageUrl]
                                    title:title
                                    description:description
                                    previewImageURL:[NSURL URLWithString:imgPath]];
    }
    else if ([type isEqualToString: RCTQQShareTypeText]) {
        message = [QQApiTextObject objectWithText:description];
    }
    else if ([type isEqualToString: RCTQQShareTypeImage]) {
        NSData *imgData = [NSData dataWithContentsOfFile:imgPath];
        message = [QQApiImageObject objectWithData:imgData
                                  previewImageData:imgData
                                             title:title
                                       description:description];
    }
    else if ([type isEqualToString: RCTQQShareTypeAudio]) {
        QQApiAudioObject *audioObj = [QQApiAudioObject objectWithURL:[NSURL URLWithString:webpageUrl]
                                  title:title
                            description:description
                        previewImageURL:[NSURL URLWithString:imgPath]];
        if (flashUrl) {
            [audioObj setFlashURL:[NSURL URLWithString:flashUrl]];
        }
        message = audioObj;
    }
    else if ([type isEqualToString: RCTQQShareTypeVideo]) {
        QQApiVideoObject *videoObj = [QQApiVideoObject objectWithURL:[NSURL URLWithString:webpageUrl]
                                                               title:title
                                                         description:description
                                                    previewImageURL:[NSURL URLWithString:imgPath]];
        if (flashUrl) {
            [videoObj setFlashURL:[NSURL URLWithString:flashUrl]];
        }
        message = videoObj;
    }
    
    QQApiSendResultCode sent = EQQAPISENDFAILD;

    if (message != nil) {
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:message];
        if (aScene == 0) {
            sent = [QQApiInterface sendReq:req];
        }
        else {
            sent = [QQApiInterface SendReqToQZone:req];
        }
        sent = [QQApiInterface sendReq:req];
    }
    
    if (sent == EQQAPISENDSUCESS) {
//        [RCTQQAPI sharedAPI].resolveBlock(@[]);
    }
    else if (sent == EQQAPIAPPSHAREASYNC) {
        
    }
    else {
        [RCTQQAPI sharedAPI].rejectBlockShare(@[@{@"err":@(sent),@"errMsg":@"qqShareEror"}]);
    }
}

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(login:(NSString *)scopes resolve:(RCTResponseSenderBlock)resolve reject:(RCTResponseSenderBlock)reject)
{
    [RCTQQAPI sharedAPI].resolveBlockLogin = resolve;
    [RCTQQAPI sharedAPI].rejectBlockLogin = reject;
  
  if (scopes && scopes.length) {
    NSArray *scopeArray = [scopes componentsSeparatedByString:@","];
    [_qqapi authorize:scopeArray inSafari:NO];
  }
  else {
    [_qqapi authorize:@[@"get_user_info", @"get_simple_userinfo"] inSafari:NO];
  }
}

RCT_EXPORT_METHOD(shareToQQ:(NSDictionary *)data resolve:(RCTResponseSenderBlock)resolve reject:(RCTResponseSenderBlock)reject)
{
    RCTQQAPI *api = [RCTQQAPI sharedAPI];
    api.resolveBlockShare = resolve;
    api.rejectBlockShare = reject;
    
    [RCTQQAPI shareToQQWithData:data scene:0];
}

RCT_EXPORT_METHOD(shareToQzone:(NSDictionary *)data resolve:(RCTResponseSenderBlock)resolve reject:(RCTResponseSenderBlock)reject)
{
    RCTQQAPI *api = [RCTQQAPI sharedAPI];
    api.resolveBlockShare = resolve;
    api.rejectBlockShare = reject;
    
    [RCTQQAPI shareToQQWithData:data scene:1];
}


RCT_EXPORT_METHOD(getQQState:(RCTResponseSenderBlock)resolve reject:(RCTResponseSenderBlock)reject) {
  if(![TencentOAuth iphoneQQInstalled]){
    reject(@[@{@"err":@(-1) ,@"errMsg":@"not installed"}]);
  }else if (![TencentOAuth iphoneQQSupportSSOLogin]) {
    reject(@[@{@"err":@(-2) ,@"errMsg":@"not support"}]);
  }else {
    resolve(@[@{}]);
  }
}


RCT_EXPORT_METHOD(logout)
{
    [_qqapi logout:nil];
}

@end
