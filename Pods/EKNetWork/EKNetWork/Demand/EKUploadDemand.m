//
//  EKUploadDemand.m
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKUploadDemand.h"
#import "EKNetWorkCentral.h"


@interface EKUploadDemand()

@property (nonatomic, strong) NSData *fromData;
@property (nonatomic, strong) NSURL *fromURL;
@property (nonatomic, strong) id<EKUploadFormDataProtocol>packData;
@property (nonatomic, weak) id<EKUploadInfoProtocol>info;

@end

/*******************************************/
@implementation EKUploadDemand

- (instancetype)initWithProInfo:(id<EKUploadInfoProtocol>)info
{
    self = [super init];
    if (self) {
        
        self.info = info;
    }
    return self;
}

- (void)startUploadWithArgument:(id)argument fromData:(NSData *)data
{
    self.argument = argument;
    self.fromData = data;
    [[EKNetWorkCentral shared] startUploadRequest:self];
}

- (void)startUploadWithArgument:(id)argument fromURL:(NSURL *)url
{
    self.argument = argument;
    self.fromURL = url;
    [[EKNetWorkCentral shared] startUploadRequest:self];
}

- (void)startUploadWithArgument:(id)arguemnt packData:(id<EKUploadFormDataProtocol>)packData
{
    self.argument = arguemnt;
    self.packData = packData;
    [[EKNetWorkCentral shared] startUploadRequest:self];
}

- (void)cancel
{
    [[EKNetWorkCentral shared] removeUploadRequest:self];
}

@end
