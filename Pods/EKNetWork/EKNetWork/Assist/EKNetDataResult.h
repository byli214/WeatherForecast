//
//  EKNewDataInfo.h
//  EKNetWork
//
//  Created by mac on 2018/11/27.
//  Copyright © 2018 EKing. All rights reserved.
//  请求结果数据默认包装类, 外部不需要关心

#import <Foundation/Foundation.h>
#import "EKResultProtocol.h"

@class EKNetDemand;
@class EKDataDemand;
@class EKDownloadDemand;
@class EKUploadDemand;
NS_ASSUME_NONNULL_BEGIN

/// 基础数据
@interface EKNetResult : NSObject<EKResultProtocol>
- (instancetype)initWithDemand:(EKNetDemand *)demand;
@end

/// EKDataRequst 对象请求返回包装数据
@interface EKNetDataResult : EKNetResult<EKDataResultProtocol>
- (instancetype)initWithNetDataDemand:(EKDataDemand *)demand;
@end

/// EKUploadRequst 对象请求返回包装数据
@interface EKNetUploadResult : EKNetResult<EKUploadResultProtocol>
- (instancetype)initWithNetUploadDemand:(EKUploadDemand *)demand;
@end

/// EKDownLoadRequst 对象请求返回包装数据
@interface EKNetDownloadResult : EKNetResult<EKDownloadResultProtocol>
- (instancetype)initWithDemand:(EKDownloadDemand *)demand;
@end

NS_ASSUME_NONNULL_END
