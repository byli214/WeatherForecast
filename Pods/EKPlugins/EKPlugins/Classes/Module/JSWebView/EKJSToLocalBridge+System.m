//
//  EKJSToLocalBridge+System.m
//  EKPlugins
//
//  Created by Skye on 2018/12/13.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "EKJSToLocalBridge+System.h"
#import "NSDictionary+Help.h"
#import "EKSysInfoData.h"
#import "NSString+Help.h"
#import "JSAmasBaseUtils.h"
#import "EKJSWebView.h"

@implementation EKJSToLocalBridge (System)

// MARK: - 手机设备

//获取系统消息
- (BOOL)jsWebView:(EKJSWebView *)jsWebView getSysInfoActionWithJsonDic:(NSDictionary *)jsonDic {
    NSString *callBack = [jsonDic js_stringValueForKey:@"callBack"];
    NSDictionary *parameterDic = [self getRequestParameters];
    NSString *uid = [parameterDic js_stringValueForKey:@"uid"];
    NSString *token =  [parameterDic js_stringValueForKey:@"token"];
    NSString *driverCode =  [parameterDic js_stringValueForKey:@"driverCode"];
    if (driverCode.length <= 0) {
        driverCode = [JSAmasBaseUtils getOSVersion];
    }
    NSString *req = [jsonDic js_stringValueForKey:@"request"];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    EKSysInfoData *sysInfo = [[EKSysInfoData alloc] initWithReq:req];
    if (token) {
        [sysInfo.data setObject:token forKey:@"token"];
    }
    
    if ([req containsString:@"uid"] && uid) {
        [sysInfo.data setObject:uid forKey:@"uid"];
    }
    
    if ([req containsString:@"screenWidth"]) {
        [sysInfo.data setObject:[NSNumber numberWithFloat:screenSize.width] forKey:@"screenWidth"];
    }
    
    if ([req containsString:@"screenHeight"]) {
        [sysInfo.data setObject:[NSNumber numberWithFloat:screenSize.height] forKey:@"screenHeight"];
    }
    
    if ([req containsString:@"isIPhoneX"]) {
        NSString *isX = (UIApplication.sharedApplication.statusBarFrame.size.height == 44) ? @"1" : @"0";
        [sysInfo.data setObject:isX forKey:@"isIPhoneX"];
    }
    
    [self toJSWithEvent:@"getSysInfo" data:jsonDic callBack:callBack callBackData:sysInfo.data];
    
    return true;
}

@end
