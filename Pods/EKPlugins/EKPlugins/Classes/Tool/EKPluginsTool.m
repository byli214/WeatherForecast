//
//  EKPluginsTool.m
//  EKPlugins
//
//  Created by mac on 2018/9/11.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "EKPluginsTool.h"
#import "EKConstants.h"
#import "EKJsonParser.h"

@implementation EKPluginsTool

+ (void)netFinishToNotice:(NSString *)url
                   method:(NSString *)method
                startTime:(NSTimeInterval)start
                 response:(NSURLResponse *)response
                     data:(id)data
                    error:(NSError *)error; {
    NSTimeInterval duration = [[NSDate date] timeIntervalSince1970] - start;
    
    NSMutableDictionary *noticeDic = [NSMutableDictionary dictionary];
    [noticeDic setValue:url forKey:@"url"];
    [noticeDic setValue:method forKey:@"method"];
    [noticeDic setValue:response forKey:@"response"];
    [noticeDic setValue:error forKey:@"error"];
    [noticeDic setValue:[NSString stringWithFormat:@"%f",duration] forKey:@"duration"];
    
    /*网络返回数据统计
     *apiStatus = "0"：成功； “1”：失败
     *intend = "错误码"
     *errorDes = "错误原因" data数据中包含的错误描述
     */
    NSString *apiStatus = @"0"; //兼容学生 h5返回数据 规则不是status,data的情况, 默认返回值是正确的
    //获取status状态
    if (nil != data){
        id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        id result = [EKJsonParser parse:obj];
        //status ==1 错误
        if ([result isKindOfClass:[Status1Message class]]) {
            apiStatus = @"1";
            Status1Message *resp = (Status1Message *)result;
            [noticeDic setValue:resp.reason forKey:@"errorDes"];
            NSString *intend = [NSString stringWithFormat:@"%d", resp.intent];
            [noticeDic setValue:intend forKey:@"intend"];
        }
    }
    [noticeDic setValue:apiStatus forKey:@"apiStatus"];

    [[NSNotificationCenter defaultCenter] postNotificationName:STATISTICS_NET_INFO object:noticeDic];
}

+ (void)netDownFinishToNotice:(NSString *)url
                     response:(NSURLResponse *)response
                        error:(NSError *)error {
    NSMutableDictionary *noticeDic = [NSMutableDictionary dictionary];
    [noticeDic setValue:url forKey:@"url"];
    [noticeDic setValue:response forKey:@"response"];
    [noticeDic setValue:error forKey:@"error"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:STATISTICS_NET_DOWN_INFO object:noticeDic];
}

@end
