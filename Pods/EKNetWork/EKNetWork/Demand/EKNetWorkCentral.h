//
//  EKNetAgent.h
//  EKNetWork
//
//  Created by mac on 2018/11/23.
//  Copyright © 2018 EKing. All rights reserved.
//  请求中枢对象

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class EKDataDemand;
@class EKUploadDemand;
@class EKDownloadDemand;

@interface EKNetWorkCentral : NSObject

///
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

///
+ (EKNetWorkCentral *)shared;

/// 基本数据操作
- (void)startDataRequest:(EKDataDemand *)demand;
- (void)removeDataRequest:(EKDataDemand *)demand;

/// 资源上传操作
- (void)startUploadRequest:(EKUploadDemand *)demand;
- (void)removeUploadRequest:(EKUploadDemand *)demand;

/// 资源下载操作
- (void)startDownloadRequest:(EKDownloadDemand *)demand;
- (void)removeDownloadRequest:(EKDownloadDemand *)demand;

@end

NS_ASSUME_NONNULL_END
