//
//  RCTQQAPI.h
//  RNThirdShareMangager
//
//  Created by LvBingru on 10/10/15.
//  Copyright © 2015 erica. All rights reserved.
//

#if __has_include(<React/RCTBridge.h>)
#import <React/RCTBridgeModule.h>
#else
#import "RCTBridgeModule.h"
#endif

#define RCTQQShareTypeNews @"news"
#define RCTQQShareTypeImage @"image"
#define RCTQQShareTypeText @"text"
#define RCTQQShareTypeVideo @"video"
#define RCTQQShareTypeAudio @"audio"

#define RCTQQShareType @"type"
#define RCTQQShareTitle @"title"
#define RCTQQShareDescription @"description"
#define RCTQQShareWebpageUrl @"webpageUrl"
#define RCTQQShareImageUrl @"imageUrl"

@interface RCTQQAPI : NSObject<RCTBridgeModule>

@end
