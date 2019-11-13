//
//  EKUrlStringSplice.h
//  EKPlugins
//
//  Created by Skye on 2017/12/18.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EKUrlStringSplice : NSObject

/**
 * 参数分三类,如有重复参数，优先级如下
 * 1. extraParameter中传递参数
 * 2. url中已经包含的参数
 * 3. 规定本地必传的基本参数baseParameter
 */

//获取有效的参数
+ (NSString *)getVailedParameterStrWithBaseUrlStr:(NSString *)baseUrlStr
                              baseParameter:(NSDictionary *)baseParameter
                             extraParameter:(NSDictionary *)extraParameter;

//获取有效的url
+ (NSString *)getVailedUrlStrWithBaseUrlStr:(NSString *)baseUrlStr
                                    baseParameter:(NSDictionary *)baseParameter
                                   extraParameter:(NSDictionary *)extraParameter;

@end
