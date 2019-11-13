//
//  EKJSWebViewHeader.h
//  EKPlugins
//
//  Created by chen on 2017/8/21.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#ifndef EKJSWebViewHeader_h
#define EKJSWebViewHeader_h


typedef void (^EKLocalEventHandler)(NSString *type, id data);

static NSString *JS_EVENT_STR_FORMAT = @"javascript:bridgeClass.toJsEvent('%@','%@');";
static NSString *JS_EVENT_JSON_FORMAT = @"javascript:bridgeClass.toJsEvent('%@',%@);";


const static int MAX_PLAYER_CT = 4;
const static int USE_CURRENT_PROGRESS = -1;

#endif /* EKJSWebViewHeader_h */
