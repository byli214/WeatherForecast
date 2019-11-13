//
//  EKConstants.h
//  EKPlugins
//
//  Created by mac on 2018/9/11.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#ifndef EKConstants_h
#define EKConstants_h

/*网络返回数据统计
 *apiStatus = "0"：成功； “1”：失败
 *intend = "错误码"
 *errorDes = "错误原因" data数据中包含的错误描述
 */

//  {url:NSString, method:NSString, error:NSError, duration:NSString, response:NSURLResponse, apiStatus:@"0", intend:@"10000", errorDes:@"错误原因"}
/// 网络请求通知关键字
static NSString *const STATISTICS_NET_INFO = @"STATISTICS_NET_INFO";

//  {url:NSString, error:NSError, response:NSURLResponse}
/// 资源下载后，通知关键字
static NSString *const STATISTICS_NET_DOWN_INFO = @"STATISTICS_NET_DOWN_INFO";



#endif /* EKConstants_h */
