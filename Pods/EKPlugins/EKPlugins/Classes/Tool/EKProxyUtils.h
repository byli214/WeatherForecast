//
//  EKProxyUtils.h
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/17.
//  Copyright © 2017年 ekwing. All rights reserved.
//

typedef void(^onSuccess)(NSDictionary *respon);
typedef void(^onFailed)(NSString *json, int errorCode, int httpCode);

@interface EKProxyUtils : NSObject

/*
 input：请求的额外参数
 baseParam：请求的基础参数
 success：成功block
 failed：失败block
 */
- (void)handleRequest:(NSDictionary *)input
            baseParam:(NSDictionary *)baseParam
              success:(onSuccess)success
               failed:(onFailed)failed;

+ (NSDictionary *)percentEncodingPostParams:(NSDictionary *)dict;
@end
