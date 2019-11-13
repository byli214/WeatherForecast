//
//  EKDownloadRequest.h
//  EKNetWork
//
//  Created by mac on 2019/1/3.
//  Copyright © 2019 ekwing. All rights reserved.
//  资源下载类

#import <Foundation/Foundation.h>
#import "EKRequestProtocol.h"
#import "EKInfoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 单资源下载类
@interface EKDownloadRequest : NSObject<EKDownloadRequestProtocol, EKDownloadInfoProtocol, EKStateProtocol>

- (instancetype)new NS_UNAVAILABLE;

/**
 * 对象，请求返回使用block
 * @param url 请求地址
 */
- (instancetype)initWithUrl:(NSString *)url;

/**
 * 对象，单下载返回使用delegate，如果使用block两个都会返回
 * @param url 请求地址
 * @param delegate 结果返回回调
 */
- (instancetype)initWithUrl:(NSString *)url delegate:(nullable id<EKDownloadRequestBackProtocol>)delegate;

/**
 * 提供url不确定时，先创建对象后设置url便利方法，单个下载使用
 * @param url 下载类对象设置url，
 * @return EKDownloadRequest  返回当前对象实例
 */
- (EKDownloadRequest *)setDownUrl:(NSString *)url;

@end



/// 多资源下载类
@interface EKMutDownloadRequest: NSObject<EKDownloadRequestProtocol, EKDownloadInfoProtocol>

- (instancetype)new NS_UNAVAILABLE;

/**
 * 对象，请求返回使用block
 * @param urls 多资源请求url集合
 */
- (instancetype)initWithUrls:(NSArray<NSString*> *)urls;

/**
 * 对象，多资源下载返回使用delegate，如果使用block两个都会返回
 * @param urls 多资源请求url集合
 * @param delegate 结果返回回调
 */
- (instancetype)initWithUrls:(NSArray<NSString*> *)urls delegate:(nullable id<EKDownloadRequestBackProtocol>)delegate;

/**
 * 对象，请求返回使用block
 * @param requests 多资源请求，对象集合
 */
- (instancetype)initWithRequests:(NSArray<EKDownloadRequest*> *)requests;

/**
 * 对象，多资源下载返回使用delegate，如果使用block两个都会返回
 * @param requests 多资源请求，对象集合
 * @param delegate 结果返回回调
 */
- (instancetype)initWithRequests:(NSArray<EKDownloadRequest*> *)requests delegate:(nullable id<EKDownloadRequestBackProtocol>)delegate;

/**
 * @param urls 下载类对象设置urls，提供urls不确定时，先创建对象后设置urls便利方法，多个资源下载使用
 * @return id<EKDownloadRequestProtocol>  返回当前对象实例
 */
- (EKMutDownloadRequest *)setDownUrls:(NSArray<NSString*> *)urls;

@end

NS_ASSUME_NONNULL_END
