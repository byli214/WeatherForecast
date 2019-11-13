//
//  EKDataRequestManager.h
//  EKNetWork
//
//  Created by mac on 2019/5/29.
//  Copyright © 2019 ekwing. All rights reserved.
//
//  单例基本数据请求，旨在为外部提供便利对象，部分全局请求
//  不需要外部强持有情况下使用, 没有延时, 重试和重复请求过滤特性。
//  请求对象无法查询请求参数info信息，可以再结果信息里面查询
//  单个页面请求原则上要使用EKDataRequest, 一个请求一个对象

#import <Foundation/Foundation.h>
#import "EKRequestProtocol.h"
#import "EKInfoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKDataRequestManager : NSObject

- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

//
+ (EKDataRequestManager *)shared;

/// 取消全部，有回调
- (void)cancel;

/// 取消全部，无回调
- (void)silenceCancel;

/**
 * @param url 请求地址，其他设置默认
 * @param argument 参数
 * @param complete 结果返回block
 * 结果返回遵循EKDataResultProtocol协议对象
 */
- (void)startWithUrl:(nonnull NSString *)url
            argument:(nullable id)argument
            complete:(void(^)(id<EKDataResultProtocol>result))complete;


/**
 * @param info 请求信息数据
 * @param argument 参数
 * @param complete 结果返回block
 * 结果返回遵循EKDataResultProtocol协议对象
 */
- (void)startWithInfo:(nonnull id<EKInfoProtocol>)info
             argument:(nullable id)argument
             complete:(void(^)(id<EKDataResultProtocol>result))complete;

/**
 * @param request 外部自己定义NSURLRequest
 * @param complete 结果返回block
 * 结果返回遵循EKDataResultProtocol协议对象
 */
- (void)startWithRequest:(nonnull NSURLRequest *)request
                complete:(void(^)(id<EKDataResultProtocol>result))complete;

@end


/// EKDataInfoProtocol object
@interface EKDataInfo: NSObject<EKInfoProtocol>
- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithUrl:(nonnull NSString *)url;
@end


NS_ASSUME_NONNULL_END
