//
//  EKDataRequest.m
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKDataRequest.h"
#import "EKNetWorkTimer.h"
#import "EKDataDemand.h"
#import "EKNetDataResult.h"
#import "EKNetWorkConfg.h"


@interface EKDataRequest()<EKDataDemandDelegate>

@property (nonatomic, weak) EKDataDemand *netDemand;
@property (nonatomic, weak) id<EKDataRequestBackProtocol> delegate;
@property (nonatomic, copy) void(^resultBlock)(id<EKDataResultProtocol>result);
@property (nonatomic, strong) EKNetWorkTimer *delayTimer;
@property (nonatomic, strong) EKNetWorkTimer *preTipTimer;
@property (nonatomic, assign) int failRequestRetryCount;
@property (nonatomic, assign) BOOL canceSilenceFlag;
@property (nonatomic, copy) void(^preTipBlock)(void);

@end

@implementation EKDataRequest
// 请求
@synthesize url, method, timeoutInterval, serializer;
@synthesize delayInterval, retryCount, useCache, userData;

// 查询
@synthesize argument, duration, error, request, resonseString;
@synthesize response, responseData, responseObject, task;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.timeoutInterval = 20;
        self.method = EKNetPost;
        self.delayInterval = 0;
        self.retryCount = 0;
        self.serializer = EKNetJson;
        self.failRequestRetryCount = 0;

    }
    return self;
}

- (instancetype)initWithUrl:(NSString *)url
{
    return [self initWithUrl:url delegate:nil];
}

- (instancetype)initWithUrl:(NSString *)url delegate:(nullable id<EKDataRequestBackProtocol>)delegate
{
    EKDataRequest *req = [[EKDataRequest alloc] init];
    req.url = url;
    req.delegate = delegate;
    return req;
}

- (void)dealloc
{
//    NSLog(@"EKDataRequest Dealloc == %@, url == %@",self, self.url);
    [self silenceCancel];
}

#pragma mark - Function

- (EKDataRequest *)setDataUrl:(NSString *)url
{
    if (url.length == 0)
    {
        NSLog(@"EKDataRequest set downurl nil");
        return self;
    }
    
    self.url = url;
    return self;
}

- (EKDataRequest *)previousTip:(void(^)(void))block;
{
    self.preTipBlock = block;
    return self;
}

//
- (void)delayInvokeRequest:(id)argument customRequest:(NSURLRequest *)request complete:(void(^)(id<EKDataResultProtocol>result))complete
{
    self.failRequestRetryCount = MIN(self.retryCount, 20);
    
    if (self.delayInterval <= 0)
    {
        [self priRealDataRequest:argument customRequest:request complete:complete];
        return;
    }
    
    [self finishDelayTiemr];
    __weak typeof(self)weakSelf = self;
    self.delayTimer = [EKNetWorkTimer scheduledWithInterval:MAX(self.delayInterval, 0) repeats:NO block:^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf priRealDataRequest:argument customRequest:request complete:complete];
    }];
}

- (void)priRealDataRequest:(id)argument customRequest:(NSURLRequest *)request complete:(void(^)(id<EKDataResultProtocol>result))complete
{
    self.resultBlock = complete;
    //
    EKDataDemand *netDemand = [[EKDataDemand alloc] initWithProInfo:self];
    netDemand.delegate = self;
    self.netDemand = netDemand;
    
    //
    if (request != nil)
    {
        [netDemand startWithRequest:request];
    } else
    {
        id appendArgument = [self appendBaseArgument:argument];
        [netDemand startWithArgument:appendArgument];
    }
    
    if (self.preTipBlock != nil)
    {
        __weak typeof(self) weakSelf = self;
        self.preTipTimer = [EKNetWorkTimer scheduledWithInterval:0.5 repeats:NO block:^{
            if (weakSelf.netDemand.task != nil && weakSelf.netDemand.task.state == NSURLSessionTaskStateRunning)
            {
                weakSelf.preTipBlock();
                weakSelf.preTipBlock = nil;
            }
        }];
    }
}

- (void)priRetryRequestWhenFail:(EKDataDemand *)demand
{
    NSURLRequest *oriRequest = [demand.oriRequest copy];
    void(^completeBlock)(id<EKDataResultProtocol>) = [self.resultBlock copy];
    
    self.failRequestRetryCount--;
    __weak typeof(self)weakSelf = self;
    self.delayTimer = [EKNetWorkTimer scheduledWithInterval:1.0 repeats:NO block:^{
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf priRealDataRequest:nil customRequest:oriRequest complete:completeBlock];
    }];
}


#pragma mark - EKDataInfoRequestProtocol

- (void)cancel
{
    [self finishDelayTiemr];
    
    if (self.netDemand != nil)
    {
        [self.netDemand cancel];
    }
}

- (void)silenceCancel
{
    self.canceSilenceFlag = YES;
    [self cancel];
}

- (void)startWithArgument:(nullable id)argument
{
    if ([self isExcutingOrDelayInvoke]) {
        return;
    }
    
    [self delayInvokeRequest:argument customRequest:nil complete:nil];
}

- (void)startWithRequest:(nonnull NSURLRequest *)request
{
    if ([self isExcutingOrDelayInvoke])
    {
        return;
    }
    
    [self delayInvokeRequest:nil customRequest:request complete:nil];
}

- (void)startWithArgument:(nullable id)argument complete:(void(^)(id<EKDataResultProtocol>result))complete
{
    if ([self isExcutingOrDelayInvoke])
    {
        return;
    }
    [self delayInvokeRequest:argument customRequest:nil complete:complete];
}

- (void)startWithRequest:(nonnull NSURLRequest *)request complete:(void(^)(id<EKDataResultProtocol>result))complete
{
    if ([self isExcutingOrDelayInvoke])
    {
        return;
    }
    [self delayInvokeRequest:nil customRequest:request complete:complete];
}

#pragma mark - EKDataDemandDelegate

- (void)proDataRequestStart:(EKDataDemand *)demand
{
    self.task = demand.task;
}

- (void)proDataRequestCompleted:(EKDataDemand *)demand
{
    //
    [self finishAndExcuteHander:demand finished:YES];
    
    //
    BOOL isCancelled = (demand.error != nil && demand.error.code == NSURLErrorCancelled);
    self.failRequestRetryCount = MAX(0, self.failRequestRetryCount);
    if (demand.error == nil || self.failRequestRetryCount == 0 || isCancelled)
    {
        self.canceSilenceFlag = NO;
        return;
    }
    
    [self priRetryRequestWhenFail:demand];
}

#pragma mark - Tool

- (void)finishAndExcuteHander:(EKDataDemand *)demand finished:(BOOL)finished
{
    EKNetDataResult *dataResult = [[EKNetDataResult alloc] initWithNetDataDemand:demand];
    
    // 设置此类 协议属性
    [self fullStateDataWithResult:dataResult];
    
    // 沉默取消，不调用block/delegate
    BOOL isCancelled = (demand.error != nil && demand.error.code == NSURLErrorCancelled);
    if (!isCancelled || (isCancelled && !self.canceSilenceFlag) )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 如果有回调代理，代理返回
            if (self.delegate && [self.delegate respondsToSelector:@selector(netWorkDataRequest:result:)])
            {
                [self.delegate netWorkDataRequest:self result:dataResult];
            }
            
            // 如果有block，使用block
            if (self.resultBlock != nil)
            {
                self.resultBlock(dataResult);
            }
            
            if (finished)
            {
                self.resultBlock = nil;
                self.preTipBlock = nil;
                [self finishDelayTiemr];
            }
        });
    }
    
    // 数据统计代理
    if ([EKNetWorkConfg shared].statisticDelegate && [[EKNetWorkConfg shared].statisticDelegate respondsToSelector:@selector(netWorkDataStatisticFinished:result:)] )
    {
        [[EKNetWorkConfg shared].statisticDelegate netWorkDataStatisticFinished:self result:dataResult];
    }
}

- (void)fullStateDataWithResult:(id<EKDataResultProtocol>)result
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

- (BOOL)isExcutingOrDelayInvoke
{
    if (self.delayTimer != nil) {
        return YES;
    }
    
    if (self.netDemand == nil) {
        return NO;
    }
    
    if (self.netDemand.task == nil) {
        return NO;
    }
    
    if (self.netDemand.task.state == NSURLSessionTaskStateRunning || self.netDemand.task.state == NSURLSessionTaskStateCanceling) {
        return YES;
    }
    
    return NO;
}

- (id)appendBaseArgument:(id)argument
{
    if ([EKNetWorkConfg shared].baseArgument == nil)
    {
        return argument;
    }
    
    if (argument == nil)
    {
        return [EKNetWorkConfg shared].baseArgument;
    }
    
    NSMutableDictionary *mutDic = [NSMutableDictionary dictionaryWithDictionary:[EKNetWorkConfg shared].baseArgument];
    
    if ([argument isKindOfClass:[NSDictionary<NSString *, id> class]])
    {
        NSDictionary *argumentDic = (NSDictionary *)argument;
        
        for (NSString *key in argumentDic)
        {
            [mutDic setValue:argumentDic[key] forKey:key];
        }
    }
    
    return mutDic;
}

- (void)finishDelayTiemr
{
    if (self.delayTimer != nil){
        [self.delayTimer invalidate];
        self.delayTimer = nil;
    }
    
    if (self.preTipTimer != nil) {
        [self.preTipTimer invalidate];
        self.preTipTimer = nil;
    }
}

@end
