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


@interface QQAPIInstance : NSObject<QQApiInterfaceDelegate, TencentSessionDelegate> {
    TencentOAuth* _qqapi;
}

@property (nonatomic, copy) RCTResponseSenderBlock resolveBlockShare;
@property (nonatomic, copy) RCTResponseSenderBlock rejectBlockShare;
@property (nonatomic, copy) RCTResponseSenderBlock resolveBlockLogin;
@property (nonatomic, copy) RCTResponseSenderBlock rejectBlockLogin;

@end

@implementation QQAPIInstance

+ (instancetype)sharedAPI
{
    static QQAPIInstance *_sharedAPI = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedAPI = [[[self class] alloc] init];
    });
    return _sharedAPI;
}

- (void)registerAPI
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *appId = nil;
        NSArray *list = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleURLTypes"];
        for (NSDictionary *item in list) {
            NSString *name = item[@"CFBundleURLName"];
            if ([name isEqualToString:@"qq"]) {
                NSArray *schemes = item[@"CFBundleURLSchemes"];
                if (schemes.count > 0)
                {
                    appId = [schemes[0] substringFromIndex:@"tencent".length];
                    break;
                }
            }
        }
        _qqapi = [[TencentOAuth alloc] initWithAppId:appId andDelegate:self];
    });
}

- (void)authorize:(NSArray *)scopes
{
    [_qqapi authorize:scopes];
}

- (void)unauthorize
{
    [_qqapi logout:nil];
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


@end


@implementation RCTQQAPI


+ (BOOL)handleUrl:(NSURL *)aUrl
{
    if ([TencentOAuth HandleOpenURL:aUrl])
    {
        return YES;
    }
    return NO;
}


+ (void)shareToQQWithData:(NSDictionary *)aData scene:(int)aScene
{
    QQAPIInstance *handle = [QQAPIInstance sharedAPI];
    
    NSString *type = aData[RCTQQShareType];
    
    NSString *title = aData[RCTQQShareTitle];
    if (title == nil) {
        if (handle.rejectBlockShare) {
            handle.rejectBlockShare(@[@{@"err":@(-1001),@"errMsg":@"title不能为空"}]);
        }
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
    }
    else if (sent == EQQAPIAPPSHAREASYNC) {
    }
    else {
        if (handle.rejectBlockShare) {
            handle.rejectBlockShare(@[@{@"err":@(sent),@"errMsg":@"qqShareEror"}]);
        }
    }
}

RCT_EXPORT_MODULE();

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[QQAPIInstance sharedAPI] registerAPI];
    }
    return self;
}

RCT_EXPORT_METHOD(login:(NSString *)scopes resolve:(RCTResponseSenderBlock)resolve reject:(RCTResponseSenderBlock)reject)
{
    QQAPIInstance *handle = [QQAPIInstance sharedAPI];
    handle.resolveBlockLogin = resolve;
    handle.rejectBlockLogin = reject;
  
  if (scopes && scopes.length) {
    NSArray *scopeArray = [scopes componentsSeparatedByString:@","];
    [handle authorize:scopeArray];
  }
  else {
    [handle authorize:@[@"get_user_info", @"get_simple_userinfo"]];
  }
}

RCT_EXPORT_METHOD(shareToQQ:(NSDictionary *)data resolve:(RCTResponseSenderBlock)resolve reject:(RCTResponseSenderBlock)reject)
{
    QQAPIInstance *handle = [QQAPIInstance sharedAPI];
    handle.resolveBlockShare = resolve;
    handle.rejectBlockShare = reject;
    
    [RCTQQAPI shareToQQWithData:data scene:0];
}

RCT_EXPORT_METHOD(shareToQzone:(NSDictionary *)data resolve:(RCTResponseSenderBlock)resolve reject:(RCTResponseSenderBlock)reject)
{
    QQAPIInstance *handle = [QQAPIInstance sharedAPI];
    handle.resolveBlockShare = resolve;
    handle.rejectBlockShare = reject;
    
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
    QQAPIInstance *handle = [QQAPIInstance sharedAPI];
    [handle unauthorize];
}

@end
