//
//  EKUploadRequest.h
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKRequestProtocol.h"
#import "EKInfoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKUploadRequest : NSObject<EKUploadRequestProtocol, EKUploadInfoProtocol, EKStateProtocol>

- (instancetype)new NS_UNAVAILABLE;

/**
 * 对象，请求返回使用block
 * @param url 请求地址
 */
- (instancetype)initWithUrl:(NSString *)url;

/**
 * 对象，上传返回使用delegate，如果使用block两个都会返回
 * @param url 请求地址
 * @param delegate 结果返回回调
 */
- (instancetype)initWithUrl:(NSString *)url delegate:(nullable id<EKUploadRequestBackProtocol>)delegate;

/**
 * 提供url不确定时，先创建对象后设置url便利方法
 * @param url 请求类对象设置url，
 * @return EKUploadRequest 返回当前对象实例
 */
- (EKUploadRequest *)setUploadUrl:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
