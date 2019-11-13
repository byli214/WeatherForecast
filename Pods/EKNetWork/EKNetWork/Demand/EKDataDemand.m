//
//  EKDataDemand.m
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKDataDemand.h"
#import "EKNetWorkCentral.h"

@interface EKDataDemand()
@property (nonatomic, weak) id<EKInfoProtocol> info;
@end

/*******************************************/
@implementation EKDataDemand

- (instancetype)initWithProInfo:(id<EKInfoProtocol>)info
{
    self = [super init];
    if (self) {
        self.info = info;
    }
    return self;
}
- (void)startWithArgument:(id)argument
{
    self.argument = argument;
    [[EKNetWorkCentral shared] startDataRequest:self];
}

- (void)startWithRequest:(NSURLRequest *)request
{
    self.oriRequest = request;
    [[EKNetWorkCentral shared] startDataRequest:self];
}

- (void)cancel
{
    [[EKNetWorkCentral shared] removeDataRequest:self];
}

@end

