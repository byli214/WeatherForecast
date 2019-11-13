//
//  EKPluginsTool.h
//  EKPlugins
//
//  Created by mac on 2018/9/11.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EKPluginsTool : NSObject

+ (void)netFinishToNotice:(NSString *)url
                   method:(NSString *)method
                startTime:(NSTimeInterval)start
                 response:(NSURLResponse *)response
                     data:(id)data
                    error:(NSError *)error;

/// 资源下载后通知
+ (void)netDownFinishToNotice:(NSString *)url
                     response:(NSURLResponse *)response
                        error:(NSError *)error;

@end
