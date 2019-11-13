//
//  EKUploadRequest.m
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKUploadRequest.h"
#import "EKRequestProtocol.h"
#import "EKInfoProtocol.h"
#import "EKUploadDemand.h"
#import "EKNetDataResult.h"
#import "EKNetWorkConfg.h"


@interface EKUploadRequest()<EKUploadDemandDelegate>

@property (nonatomic, weak) EKUploadDemand *uploadDemand;
@property (nonatomic, weak) id<EKUploadRequestBackProtocol> delegate;
@property (nonatomic, copy) void(^resultBlock)(id<EKUploadResultProtocol>result);
@property (nonatomic, copy) EKProgressBlock progressBlock;
@property (nonatomic, assign) BOOL canceSilenceFlag;
@end

@implementation EKUploadRequest
// 请求
@synthesize url, method, timeoutInterval, serializer, userData;
// 查询
@synthesize argument, duration, error, request, task;
@synthesize resonseString, response, responseData, responseObject;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeoutInterval = 20;
        self.method = EKNetPost;
        self.serializer = EKNetHttp;
    }
    return self;
}

- (instancetype)initWithUrl:(NSString *)url
{
    return [self initWithUrl:url delegate:nil];
}

- (instancetype)initWithUrl:(NSString *)url delegate:(nullable id<EKUploadRequestBackProtocol>)delegate
{
    EKUploadRequest *req = [[EKUploadRequest alloc] init];
    req.url = url;
    req.delegate = delegate;
    return req;
}

- (void)dealloc
{
    [self cancel];
}

- (void)uploadInvokeRequest:(id)argument
                   fromData:(NSData *)fromData
                    fromURL:(NSURL *)fromURL
                   packData:(id<EKUploadFormDataProtocol>)packData
                   progress:(EKProgressBlock)progressBlk
                   complete:(void(^)(id<EKUploadResultProtocol>result))complete
{
    self.progressBlock = progressBlk;
    self.resultBlock = complete;
    //
    EKUploadDemand *uploadDemand = [[EKUploadDemand alloc] initWithProInfo:self];
    uploadDemand.delegate = self;
    self.uploadDemand = uploadDemand;
    
    //
    if (packData != nil)
    {
        [uploadDemand startUploadWithArgument:argument packData:packData];
    } else if([fromURL isKindOfClass:[NSURL class]]) {
        [uploadDemand startUploadWithArgument:argument fromURL:fromURL];
    } else {
        [uploadDemand startUploadWithArgument:argument fromData:fromData];
    }
}

- (EKUploadRequest *)setUploadUrl:(NSString *)url
{
    if (url.length == 0)
    {
        NSLog(@"EKDownloadRequest set downurl nil");
        return self;
    }
    
    if (self.url.length > 0 && [self.url isEqualToString:url])
    {
        return self;
    } else {
        if ([self isUploadExcuting])
        {
            [self cancel];
        }
    }
    
    self.url = url;
    return self;
}

#pragma mark - EKUploadRequestProtocol

- (void)startUploadWithArgument:(nullable id)argument
                       packData:(id<EKUploadFormDataProtocol>)packData
                       progress:(EKProgressBlock)progressBlock
                       complete:(void(^)(id<EKUploadResultProtocol>result))complete
{
    if ([self isUploadExcuting] == YES)
    {
        return;
    }
    
    [self uploadInvokeRequest:argument fromData:nil fromURL:nil packData:packData progress:progressBlock complete:complete];
}

- (void)startUploadWithArgument:(nullable id)argument packData:(id<EKUploadFormDataProtocol>)packData
{
    if ([self isUploadExcuting] == YES)
    {
        return;
    }
    
    [self uploadInvokeRequest:argument fromData:nil fromURL:nil packData:packData progress:nil complete:nil];
}

- (void)startUploadWithArgument:(nullable id)argument formData:(nonnull NSData *)fromData progress:(EKProgressBlock)progressBlock complete:(nonnull void (^)(id<EKUploadResultProtocol> _Nonnull))complete
{
    if ([self isUploadExcuting] == YES)
    {
        return;
    }
    
    [self uploadInvokeRequest:argument fromData:fromData fromURL:nil packData:nil progress:progressBlock complete:complete];
}


- (void)startUploadWithArgument:(nullable id)argument formURL:(nonnull NSURL *)fromURL progress:(EKProgressBlock)progressBlock complete:(nonnull void (^)(id<EKUploadResultProtocol> _Nonnull))complete {
    
    if ([self isUploadExcuting] == YES) {
        return;
    }

    [self uploadInvokeRequest:argument fromData:nil fromURL:fromURL packData:nil progress:progressBlock complete:complete];
}

- (void)startUploadWithArgument:(nullable id)argument fromData:(nonnull NSData *)fromData
{
    if ([self isUploadExcuting] == YES)
    {
        return;
    }
   
    [self uploadInvokeRequest:argument fromData:fromData fromURL:nil packData:nil progress:nil complete:nil];
}

- (void)startUploadWithArgument:(nullable id)argument fromURL:(nonnull NSURL *)fromURL
{
    if ([self isUploadExcuting] == YES)
    {
        return;
    }
    
    [self uploadInvokeRequest:argument fromData:nil fromURL:fromURL packData:nil progress:nil complete:nil];
}

#pragma mark - EKUploadDemandDelegate

- (void)proUploadRequestCompleted:(EKUploadDemand *)demand
{
    [self finishAndExcuteHander:demand];
}

- (void)proUploadRequestStart:(EKUploadDemand *)demand;
{
    self.task = demand.task;
}

- (void)proUploadRequestProgress:(EKUploadDemand *)demand progress:(nonnull NSProgress *)progress
{
    if ([self.delegate respondsToSelector:@selector(netWorkUploadRequest:progress:)])
    {
        [self.delegate netWorkUploadRequest:self progress:progress];
    }
    
    if (self.progressBlock != nil)
    {
        self.progressBlock(progress);
    }
}

- (void)cancel
{
    [self.uploadDemand cancel];
}

- (void)silenceCancel
{
    self.canceSilenceFlag = YES;
    [self cancel];
}

#pragma mark - Tool

- (BOOL)isUploadExcuting
{
    if (self.uploadDemand == nil) {
        return NO;
    }
    
    if (self.uploadDemand.task == nil) {
        return NO;
    }
    
    if (self.uploadDemand.task.state == NSURLSessionTaskStateRunning || self.uploadDemand.task.state == NSURLSessionTaskStateCanceling) {
        return YES;
    }
    
    return NO;
}


- (void)finishAndExcuteHander:(EKUploadDemand *)demand
{
    EKNetUploadResult *result = [[EKNetUploadResult alloc] initWithDemand:demand];
    
    // 状态属性赋值
    [self fullStateDataWithResult:result];
    
    // 沉默取消，不调用block/delegate
    BOOL isCancelled = (demand.error != nil && demand.error.code == NSURLErrorCancelled);
    if (!isCancelled || (isCancelled && !self.canceSilenceFlag) )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 如果有回调代理，代理返回
            if ([self.delegate respondsToSelector:@selector(netWorkUploadRequest:result:)])
            {
                [self.delegate netWorkUploadRequest:self result:result];
            }
            
            // 如果有block，使用block
            if (self.resultBlock != nil)
            {
                self.resultBlock(result);
            }
            
            self.resultBlock = nil;
            self.progressBlock = nil;
        });
    }
    
    // 数据统计代理
    if ([EKNetWorkConfg shared].statisticDelegate && [[EKNetWorkConfg shared].statisticDelegate respondsToSelector:@selector(netWorkUploadStatisticFinished:result:)] )
    {
        [[EKNetWorkConfg shared].statisticDelegate netWorkUploadStatisticFinished:self result:result];
    }
}

- (void)fullStateDataWithResult:(id<EKUploadResultProtocol>)result
{
    self.argument = result.argument;
    self.duration = result.duration;
    self.error = result.error;
    self.request = result.request;
    self.resonseString = result.resonseString;
    self.response = result.response;
    self.responseData = result.responseData;
    self.responseObject = result.responseObject;
    self.userData = result.userData;
}


@end
