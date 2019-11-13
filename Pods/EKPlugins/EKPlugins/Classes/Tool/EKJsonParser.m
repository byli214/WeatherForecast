//
//  EKJsonParser.m
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/14.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKJsonParser.h"
#import "EKJsonBuilder.h"

@implementation Status1Message

- (id)init:(int)intent reason:(NSString *)reason {
    self = [super init];
    if (self) {
        _intent = intent;
        _reason = reason;
    }
    
    return self;
}

@end

@implementation EKJsonParser

+ (id)parse:(id)response {
    if (!response)
        return nil;
    
    if ([response isKindOfClass:[NSString class]]) {
        return [EKJsonParser parseString:response];
    } else if ([response isKindOfClass:[NSDictionary class]]) {
        return [EKJsonParser parseDic:response];
    }
    
    return nil;
}

+ (id)parseString:(NSString *)json {
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:@"<(S*?)[^>]*>.*?|<.*? />" options:0 error:nil];
    json = [regularExpression stringByReplacingMatchesInString:json options:0 range:NSMakeRange(0, json.length) withTemplate:@""];
    NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    
    if (err) {
        return nil;
    }

    return [EKJsonParser parseDic:dic];
}

+(id)parseDic:(NSDictionary *)dic {
    if (!dic || !dic[@"data"]) {
        return nil;
    }
    
    id data = dic[@"data"];
    id status = [dic objectForKey:@"status"];
    if (!status) {
        return nil;
    }
    
    if ([status respondsToSelector:@selector(intValue)]) {
        int statusValue = [status intValue];
        if (statusValue == 1) {
            if ([data isKindOfClass:[NSDictionary class]]) {
                id intent = data[@"intent"];
                intent = !intent ? data[@"intend"] : intent;
                int intentValue = -1;
                if (intent && [intent respondsToSelector:@selector(intValue)]) {
                    intentValue = [intent intValue];
                }
            
                id reason = data[@"error_msg"];
                reason = !reason ? data[@"errlog"] : reason;
                NSString *reasonStr = @"";
                if (reason && [reason isKindOfClass:[NSString class]]) {
                    reasonStr = reason;
                }
            
                return [[Status1Message alloc] init:intentValue reason:reasonStr];
           } else {
                NSString *reasonStr = [EKJsonBuilder toJsonString:data];
 
                return [[Status1Message alloc] init:-1 reason:reasonStr];
            }
        } else if (statusValue == 0) {
            return data;
        }
    }
    
    return nil;
}

@end
