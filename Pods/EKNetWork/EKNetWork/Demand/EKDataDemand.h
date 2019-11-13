//
//  EKDataDemand.h
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKNetDemand.h"
#import "EKResultProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EKDataDemandDelegate;

// request
@interface EKDataDemand : EKNetDemand
@property (nonatomic, weak, readonly) id<EKInfoProtocol> info;
@property (nonatomic, weak) id<EKDataDemandDelegate> delegate;

- (instancetype)initWithProInfo:(id<EKInfoProtocol>)info;
- (void)startWithArgument:(id)argument;
- (void)startWithRequest:(NSURLRequest *)request;
- (void)cancel;

@end

//delegate
@protocol EKDataDemandDelegate <NSObject>
@required
- (void)proDataRequestStart:(EKDataDemand *)demand;
- (void)proDataRequestCompleted:(EKDataDemand *)demand;
@end


NS_ASSUME_NONNULL_END
