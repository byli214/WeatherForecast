//
//  EKDownloadDemand.h
//  EKNetWork
//
//  Created by mac on 2019/1/4.
//  Copyright © 2019 ekwing. All rights reserved.
//

#import "EKNetDemand.h"
#import "EKInfoProtocol.h"

@protocol EKDownloadDemandDelegate;

@interface EKDownloadDemand : EKNetDemand

@property (nonatomic, weak, readonly) id<EKDownloadInfoProtocol> info;
@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, copy) NSString *cachePath;
@property (nonatomic, copy) NSString *cacheFolder;

///
@property (nonatomic, assign) int64_t cacheLenght;
@property (nonatomic, strong) NSOutputStream *fileSream;
@property (nonatomic, strong) NSProgress *receiveProgress;
@property (nonatomic, weak) id<EKDownloadDemandDelegate>delegate;


- (instancetype)initWithProInfo:(id<EKDownloadInfoProtocol>)info;
- (void)startDownload;
- (void)cancel;

@end

@protocol EKDownloadDemandDelegate <NSObject>
- (void)proDownloadRequestStart:(EKDownloadDemand *)demand;
- (void)proDownloadRequestDownProgress:(EKDownloadDemand *)demand;
- (void)proDownloadRequestCompleted:(EKDownloadDemand *)demand;

@end
