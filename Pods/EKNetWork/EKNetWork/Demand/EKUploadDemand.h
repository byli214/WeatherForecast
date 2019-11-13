//
//  EKUploadDemand.h
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKNetDemand.h"
#import "EKResultProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EKUploadDemandDelegate;
// upload
@interface EKUploadDemand : EKNetDemand

@property (nonatomic, weak, readonly) id<EKUploadInfoProtocol> info;
@property (nonatomic, strong, readonly) NSData *fromData;
@property (nonatomic, strong, readonly) NSURL *fromURL;
@property (nonatomic, strong, readonly) id<EKUploadFormDataProtocol> packData;
@property (nonatomic, weak) id<EKUploadDemandDelegate>delegate;


- (instancetype)initWithProInfo:(id<EKUploadInfoProtocol>)info;

- (void)cancel;
- (void)startUploadWithArgument:(id)argument fromData:(NSData *)data;
- (void)startUploadWithArgument:(id)argument fromURL:(NSURL *)url;
- (void)startUploadWithArgument:(id)arguemnt packData:(id<EKUploadFormDataProtocol>)packData;
@end


@protocol EKUploadDemandDelegate <NSObject>
- (void)proUploadRequestStart:(EKUploadDemand *)demand;
- (void)proUploadRequestProgress:(EKUploadDemand *)demand progress:(NSProgress *)progress;
- (void)proUploadRequestCompleted:(EKUploadDemand *)demand;

@end

NS_ASSUME_NONNULL_END
