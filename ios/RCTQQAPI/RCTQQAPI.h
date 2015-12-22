//
//  RCTQQAPI.h
//  RNThirdShareMangager
//
//  Created by LvBingru on 10/10/15.
//  Copyright © 2015 erica. All rights reserved.
//

#import "RCTBridgeModule.h"


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
