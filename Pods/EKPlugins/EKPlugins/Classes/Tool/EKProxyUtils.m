//
//  EKProxyUtils.m
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/17.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKProxyUtils.h"
#import "JSRequest.h"
#import "EKJsonParser.h"
#import "NSDictionary+Help.h"
#import "NSString+Help.h"

@interface EKProxyUtils()

@end

@implementation EKProxyUtils

- (void)handleRequest:(NSDictionary *)input baseParam:(NSDictionary *)baseParam success:(onSuccess)success failed:(onFailed)failed {
    if (!input || ![input js_stringValueForKey:@"url"] || [input js_stringValueForKey:@"url"].length < 5) {
        [self reportFailed:@"Request proxy data is illegal" httpCode:-1 errorCode:-1 callback:failed];
        return;
    }
    
    NSString *url = [input js_stringValueForKey:@"url"];
    NSString *method = [input js_stringValueForKey:@"type"];
    NSDictionary *datas = [input objectForKey:@"data"];
    NSDictionary *param = [EKProxyUtils percentEncodingPostParams:datas];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:baseParam];
    [parameters addEntriesFromDictionary:param];
    if ([method isEqualToString:@"GET"]) {
        [JSRequest GET:url parameters:parameters success:^(NSURLResponse *response, id data) {
            
            id result = [EKJsonParser parse:data];
            if (!result) {
                NSString *retJson = @"";
                if ([data isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *resp = (NSDictionary *)data;
                    retJson = [resp JSONToString];
                } else if ([data isKindOfClass:[NSString class]]) {
                    retJson = (NSString *)data;
                }
                
                [self reportFailed:retJson httpCode:200 errorCode:-1 callback:failed];
                return;
            }
            
            if ([result isKindOfClass:[Status1Message class]]) {
                Status1Message *resp = (Status1Message *)result;
                [self reportFailed:resp.reason httpCode:200 errorCode:resp.intent callback:failed];
           } else {
                if ([data isKindOfClass:[NSDictionary class]]) {
                    success(data);
                } else {
                    success([[NSDictionary alloc] init]);
                }
            }
            
        } failure:^(NSURLResponse *response, NSError *error) {
            // 如果用户没有连接网络，默认httpCode默认-1
            int httpCode = -1;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                httpCode = (int)[(NSHTTPURLResponse *)response statusCode];
            }
            [self reportFailed:[error description] httpCode:httpCode errorCode:(int)[error code] callback:failed];
        }];
    } else {
        [JSRequest POST:url parameters:parameters success:^(NSURLResponse *response, id data) {
            
            id result = [EKJsonParser parse:data];
            if (!result) {
                NSString *retJson = @"";
                if ([data isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *resp = (NSDictionary *)data;
                    retJson = [resp JSONToString];
                } else if ([data isKindOfClass:[NSString class]]) {
                    retJson = (NSString *)data;
                }
                
                [self reportFailed:retJson httpCode:200 errorCode:-1 callback:failed];
                return;
            }
            
            if ([result isKindOfClass:[Status1Message class]]) {
                Status1Message *resp = (Status1Message *)result;
                [self reportFailed:resp.reason httpCode:200 errorCode:resp.intent callback:failed];
           } else {
                if ([data isKindOfClass:[NSDictionary class]]) {
                    success(data);
                } else {
                    success([[NSDictionary alloc] init]);
                }
            }
        } failure:^(NSURLResponse *response, NSError *error) {
            // 如果用户没有连接网络，默认httpCode默认-1
            int httpCode = -1;
            if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                httpCode = (int)[(NSHTTPURLResponse *)response statusCode];
            }
            [self reportFailed:[error description] httpCode:httpCode errorCode:(int)[error code] callback:failed];
        }];
    }
}

#pragma mark - Private method
- (void)reportFailed:(NSString *)str httpCode:(int)httpCode  errorCode:(int)code callback:(onFailed)failed {
    if (failed) {
        failed(str, httpCode, code);
    }
}

+ (NSDictionary *)percentEncodingPostParams:(NSDictionary *)dict {
    NSMutableDictionary *ret = [[NSMutableDictionary alloc] initWithCapacity:[dict count]];
    for (NSString *key in dict) {
        id v = dict[key];
        if ([v isKindOfClass:[NSString class]]) {
            [ret setObject:[v percentEncoding] forKey:key];
        } else {
            [ret setObject:v forKey:key];
        }
    }
    
    return ret;
}

@end
