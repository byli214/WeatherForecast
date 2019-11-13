//
//  EKDataRequest.h
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//  基本数据请求类

#import <Foundation/Foundation.h>
#import "EKRequestProtocol.h"
#import "EKInfoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKDataRequest: NSObject<EKDataRequestProtocol, EKDataInfoProtocol, EKStateProtocol>

- (instancetype)new NS_UNAVAILABLE;

/**
 * 对象，请求返回使用block
 * @param url 请求地址
 */
- (instancetype)initWithUrl:(NSString *)url;

/**
 * 对象，请求返回使用delegate，如果使用block两个都会返回
 * @param url 请求地址
 * @param delegate 结果返回回调
 */
- (instancetype)initWithUrl:(NSString *)url delegate:(nullable id<EKDataRequestBackProtocol>)delegate;

/**
 * 此方法是请求开始后如果0.5s没有返回数据会触发block调用，如果再0.5s返回数据了则不执行block 增加便利方法，控制请求提示触发时机增加用户体验。
 * @param block 注意循环引用，使用weak，
 * @return EKDataRequest  返回当前实例
 */
- (EKDataRequest *)previousTip:(void(^)(void))block;

/**
 * 提供url不确定时，先创建对象后设置url便利方法
 * @param url 请求类对象设置url，
 * @return EKDataRequest 返回当前对象实例
 */
- (EKDataRequest *)setDataUrl:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
