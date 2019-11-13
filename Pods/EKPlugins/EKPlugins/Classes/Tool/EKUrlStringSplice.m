//
//  EKUrlStringSplice.m
//  EKPlugins
//
//  Created by Skye on 2017/12/18.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import "EKUrlStringSplice.h"

@implementation EKUrlStringSplice

+ (NSString *)getVailedParameterStrWithBaseUrlStr:(NSString *)baseUrlStr
                              baseParameter:(NSDictionary *)baseParameter
                             extraParameter:(NSDictionary *)extraParameter {
    //总的参数
    NSMutableDictionary *allPragram = [[NSMutableDictionary alloc] initWithDictionary:baseParameter];
    
    if (extraParameter) {
        [allPragram addEntriesFromDictionary:extraParameter];
    }
    
    //移除url中已有的键值对（拼接参数去重）
    NSDictionary *urlParagramDic = [self priGainParagramDicFromUrlStr:baseUrlStr];
    if (urlParagramDic) {
        [allPragram removeObjectsForKeys:urlParagramDic.allKeys];
    }
    
    //最终有效的url
    NSMutableString *mutStr = [[NSMutableString alloc] init];
    
    for (NSString *key in allPragram){
        if (key && allPragram[key]){
            id value = allPragram[key];
            NSString *valueStr = nil;
            if ([value respondsToSelector:@selector(stringValue)]){
                valueStr = [value stringValue];
            }else if([value isKindOfClass:[NSString class]]){
                valueStr = (NSString *)value;
            }
            if (valueStr){
                [mutStr appendFormat:@"%@=%@&", key, valueStr];
            }
        }
    }
    //去除多余的&
    NSString *vailedParameterStr = nil;
    if (mutStr && mutStr.length > 1) {
        vailedParameterStr = [mutStr substringToIndex:mutStr.length - 1];
    }
    
    return vailedParameterStr;
}

+ (NSString *)getVailedUrlStrWithBaseUrlStr:(NSString *)baseUrlStr
                              baseParameter:(NSDictionary *)baseParameter
                             extraParameter:(NSDictionary *)extraParameter{
    
    NSString *parameterStr = [self getVailedParameterStrWithBaseUrlStr:baseUrlStr baseParameter:baseParameter extraParameter:extraParameter];
    NSString *url = nil;
    if ([baseUrlStr containsString:@"?"]){
        url = [baseUrlStr stringByAppendingFormat:@"&%@", parameterStr];
    } else {
        url = [baseUrlStr stringByAppendingFormat:@"?%@", parameterStr];
    }
    
    return url;
}

+ (NSDictionary *)priGainParagramDicFromUrlStr:(NSString *)urlStr{
    //无？或 ?后没有内容 = 无参数
    NSRange range = [urlStr rangeOfString:@"?"];
    if (range.length <= 0 || urlStr.length <= range.location + 1) {
        return nil;
    }
    //获取参数列表
    NSString *propertys = [urlStr substringFromIndex:(int)(range.location+1)];
    NSArray *subArray = [propertys componentsSeparatedByString:@"&"];
    NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
    
    for (int j = 0 ; j < subArray.count; j++){
        NSArray *dicArray = [subArray[j] componentsSeparatedByString:@"="];
        if (dicArray.count == 2) {
            NSString *key = dicArray[0];
            NSString *value = dicArray[1];
            if (key && value && key.length > 0 && value.length > 0) {
                [tempDic setValue:value forKey:key];
            }
        }
    }
    
    NSLog(@"打印参数列表生成的字典：\n%@", tempDic);
    
    return tempDic;
}

@end
