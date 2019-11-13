//
//  EKNetPackData.h
//  EKNetWork
//
//  Created by mac on 2018/11/29.
//  Copyright © 2018 EKing. All rights reserved.
//  资源上传，数据包装对象

#import <Foundation/Foundation.h>
#import "EKRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKNetPackData : NSObject<EKUploadFormDataProtocol>

///
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

/**
 * @param fileURL   本地资源路径
 * @param name      HTTP header ----> name=#{name}"
 */
- (instancetype)initWithFileURL:(NSURL *)fileURL name:(NSString *)name;

/**
 * @param fileURL    本地资源路径
 * @param name       HTTP header ----> name=#{name}"
 * @param fileName   HTTP header ----> filename=#{filename}
 * @param mimeType   HTTP header ----> `Content-Type: #{mimeType}
 */
- (instancetype)initWithFileURL:(NSURL *)fileURL name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;

/**
 * @param data      原始上传NSData数据
 * @param name      HTTP header ----> name=#{name}"
 */
- (instancetype)initWithData:(NSData *)data name:(NSString *)name;


/**
 * @param data       原始上传NSData数据
 * @param name       HTTP header ----> name=#{name}"
 * @param fileName   HTTP header ----> filename=#{filename}
 * @param mimeType   HTTP header ----> `Content-Type: #{mimeType}
 */
- (instancetype)initWithData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType;


@end

NS_ASSUME_NONNULL_END
