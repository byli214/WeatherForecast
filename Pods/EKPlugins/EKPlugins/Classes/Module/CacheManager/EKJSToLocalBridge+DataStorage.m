//
//  EKJSToLocalBridge+DataStorage.m
//  EKPlugins
//
//  Created by Skye on 2018/12/13.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "EKJSToLocalBridge+DataStorage.h"
#import "EKH5CacheManager.h"
#import "NSDictionary+Help.h"
#import "EKJSWebView.h"


@implementation EKJSToLocalBridge (DataStorage)

// MARK: - 缓存数据
//添加缓存数据
- (BOOL)jsWebView:(EKJSWebView *)jsWebView setLocalCacheActionWithJsonDic:(NSDictionary *)jsonDic {
    [[EKH5CacheManager sharedInstance] setData:[jsonDic objectForKey:@"key"] value:[jsonDic objectForKey:@"value"] replace:[jsonDic js_boolValueForKey:@"cover" defaultValue:YES] saveToFile:[jsonDic js_boolValueForKey:@"persistent" defaultValue:NO]];
    
    return true;
}

//获取缓存数据
- (BOOL)jsWebView:(EKJSWebView *)jsWebView getLocalCacheActionWithJsonDic:(NSDictionary *)jsonDic {
    NSString *callBack = [jsonDic js_stringValueForKey:@"callBack"];
    [self toJSWithEvent:@"getLocalCache" data:jsonDic callBack:callBack callBackData:[[EKH5CacheManager sharedInstance] getData:[jsonDic js_stringValueForKey:@"key"]]];
    
    return true;
}

//清理缓存数据
- (BOOL)jsWebView:(EKJSWebView *)jsWebView clearLocalCacheActionWithJsonDic:(NSDictionary *)jsonDic {
    [[EKH5CacheManager sharedInstance] removeData:[jsonDic objectForKey:@"key"]];
    
    return true;
}

@end
