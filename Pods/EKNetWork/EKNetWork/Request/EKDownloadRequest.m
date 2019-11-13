//
//  EKDownloadRequest.m
//  EKNetWork
//
//  Created by mac on 2019/1/3.
//  Copyright © 2019 ekwing. All rights reserved.
//

#import "EKDownloadRequest.h"
#import "EKDownloadDemand.h"
#import "EKNetDataResult.h"
#import <pthread/pthread.h>
#import "EKNetWorkConfg.h"


#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface EKDownloadRequest()<EKDownloadDemandDelegate>

@property (nonatomic, weak) id<EKDownloadRequestBackProtocol> delegate;
@property (nonatomic, weak) EKDownloadDemand *downDemand;
@property (nonatomic, copy, nullable) EKProgressBlock progressBlock;
@property (nonatomic, copy) void(^resultBlock)(id<EKDownloadResultProtocol>result);
@property (nonatomic, assign) BOOL canceSilenceFlag;
@end

@implementation EKDownloadRequest

// 请求
@synthesize url, method, timeoutInterval, serializer, useCache;
@synthesize appendSuggestIfNoExtension, userData;
// 查询
@synthesize argument, duration, error, request, resonseString;
@synthesize response, responseData, responseObject, task;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timeoutInterval = 30;
        self.method = EKNetGet;
        self.serializer = EKNetHttp;
        self.useCache = YES;
        self.appendSuggestIfNoExtension = YES;
    }
    return self;
}

- (instancetype)initWithUrl:(NSString *)url
{
    return [self initWithUrl:url delegate:nil];
}

- (instancetype)initWithUrl:(NSString *)url delegate:(nullable id<EKDownloadRequestBackProtocol>)delegate
{
    EKDownloadRequest *req = [[EKDownloadRequest alloc] init];
    req.url = url;
    req.delegate = delegate;
    return req;
}

- (void)dealloc
{
    [self silenceCancel];
}

- (void)cancel
{
    if (self.task != nil && self.task.state == NSURLSessionTaskStateRunning)
    {
        [self.downDemand cancel];
    }
}

- (void)silenceCancel
{
    self.canceSilenceFlag = YES;
    [self cancel];
}

- (EKDownloadRequest *)setDownUrl:(NSString *)url
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
        if ([self isDownloadExcuting])
        {
            [self silenceCancel];
        }
    }
    
    self.url = url;
    return self;
}

#pragma mark - EKDownRequestProtocol

- (void)startDownload
{
    if ([self isDownloadExcuting])
    {
        NSLog(@"EKDownloadRequest single request is running");
        return;
    }
 
    [self downloadInvokeRequest:self progress:nil complete:nil];
}

- (void)startDownload:(EKProgressBlock)progressBlock complete:(void(^)(id<EKDownloadResultProtocol>result))complete
{
    if ([self isDownloadExcuting])
    {
        NSLog(@"EKDownloadRequest single request is running");
        return;
    }
    [self downloadInvokeRequest:self progress:progressBlock complete:complete];
}

- (void)startMutDownload:(EKProgressBlock)progressBlock complete:(void(^)(NSArray<id<EKDownloadResultProtocol>> *result))complete
{
    NSLog(@"EKDownloadRequest single request is running");
}

- (void)downloadInvokeRequest:(id<EKDownloadDemandDelegate>)delegate progress:(EKProgressBlock)progressBlock complete:(void(^)(id<EKDownloadResultProtocol>result))complete
{
    self.progressBlock = progressBlock;
    self.resultBlock = complete;
    
    //
    EKDownloadDemand *downDemand = [[EKDownloadDemand alloc] initWithProInfo:self];
    downDemand.delegate = delegate;
    self.downDemand = downDemand;
    [self.downDemand startDownload];
}

#pragma mark - EKNetWorkDownloadDemandDelegate

- (void)proDownloadRequestStart:(EKDownloadDemand *)demand
{
    self.task = demand.task;
}

- (void)proDownloadRequestDownProgress:(EKDownloadDemand *)demand
{
    if ([self.delegate respondsToSelector:@selector(netWorkDownloadRequest:progress:)])
    {
        [self.delegate netWorkDownloadRequest:self progress:demand.receiveProgress];
    }
    
    //
    if (self.progressBlock != nil)
    {
        self.progressBlock(demand.receiveProgress);
    }
}

- (void)proDownloadRequestCompleted:(EKDownloadDemand *)demand
{
    // 沉默取消，不调用block/delegate
    BOOL isCancelled = (demand.error != nil && demand.error.code == NSURLErrorCancelled);
    if (!isCancelled || (isCancelled && !self.canceSilenceFlag) )
    {
        [self finishAndExcuteHander:demand];
    }
}

- (BOOL)isDownloadExcuting
{
    if (self.downDemand == nil) {
        return NO;
    }
    
    if (self.downDemand.task == nil) {
        return NO;
    }
    
    if (self.downDemand.task.state == NSURLSessionTaskStateRunning || self.downDemand.task.state == NSURLSessionTaskStateCanceling) {
        return YES;
    }
    
    return NO;
}

- (void)finishAndExcuteHander:(EKDownloadDemand *)demand
{
    EKNetDownloadResult *result = [[EKNetDownloadResult alloc] initWithDemand:demand];
    
    // 状态属性赋值
    [self fullStateDataWithResult:result];
    // 如果有回调代理，代理返回
    if ([self.delegate respondsToSelector:@selector(netWorkDownloadRequest:result:)])
    {
        [self.delegate netWorkDownloadRequest:self result:result];
    }
    
    // 如果有block，使用block
    if (self.resultBlock != nil)
    {
        self.resultBlock(result);
    }
    
    // 数据统计代理
    if ([EKNetWorkConfg shared].statisticDelegate && [[EKNetWorkConfg shared].statisticDelegate respondsToSelector:@selector(netWorkDownloadStatisticFinished:result:)] )
    {
        [[EKNetWorkConfg shared].statisticDelegate netWorkDownloadStatisticFinished:self result:result];
    }
    
    // release
    self.resultBlock = nil;
    self.progressBlock = nil;
}

- (void)fullStateDataWithResult:(id<EKDownloadResultProtocol>)result
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


////*************************************

@interface EKMutDownloadRequest()<EKDownloadDemandDelegate>
{
    pthread_mutex_t _lock;
}
@property (nonatomic, weak) id<EKDownloadRequestBackProtocol> delegate;
@property (nonatomic, strong) NSArray<EKDownloadRequest*> *requests;
@property (nonatomic, strong) NSMutableArray<EKDownloadResultProtocol> *finishResults;
@property (nonatomic, strong) NSProgress *downProgress;
@property (nonatomic, assign) float reqeustCopies;
@property (nonatomic, assign) BOOL canceSilenceFlag;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *progressDic;
@property (atomic, assign) BOOL requestRunning;

@property (nonatomic, copy) void(^completeBlock)(NSArray<void(^)(id<EKDownloadResultProtocol>result)> *);
@property (nonatomic, copy) void(^progressBlock)(NSProgress *);

@end

@implementation EKMutDownloadRequest
@synthesize appendSuggestIfNoExtension, url, useCache;

- (instancetype)init
{
    self = [super init];
    if (self) {

        pthread_mutex_init(&_lock, NULL);
        _downProgress = [NSProgress progressWithTotalUnitCount:1000];
    }
    return self;
}

- (instancetype)initWithUrls:(NSArray<NSString *> *)urls
{
    return [self initWithUrls:urls delegate:nil];
}

- (instancetype)initWithRequests:(NSArray<EKDownloadRequest*> *)requests
{
    return [self initWithRequests:requests delegate:nil];
}

- (instancetype)initWithUrls:(NSArray<NSString *> *)urls delegate:(nullable id<EKDownloadRequestBackProtocol>)delegate
{
    NSArray <EKDownloadRequest*> *requests = [self getDownloadInfosWithUrls:urls];
    return [self initWithRequests:requests delegate:delegate];
}

- (instancetype)initWithRequests:(NSArray<EKDownloadRequest*> *)requests delegate:(nullable id<EKDownloadRequestBackProtocol>)delegate
{
    EKMutDownloadRequest *request = [[EKMutDownloadRequest alloc] init];
    request.delegate = delegate;
    request.requests = [self fiterSameUrlToMerge:requests];
    return request;
}

- (EKMutDownloadRequest *)setDownUrls:(NSArray<NSString*> *)urls
{
    NSArray <EKDownloadRequest*> *requests = [self getDownloadInfosWithUrls:urls];
    NSArray *fiterArray = [self fiterSameUrlToMerge:requests];
    BOOL sameUrl = YES;
    
    if ([self.requests isKindOfClass:[NSArray class]] && self.requests.count > 0)
    {
        if (self.requests.count != urls.count)
        {
            sameUrl = NO;
        } else
        {
            for (EKDownloadRequest *oldRequest in self.requests)
            {
                if ([urls containsObject:oldRequest.url] == NO)
                {
                    sameUrl = NO;
                    break;
                }
            }
        }
        
        if (sameUrl == NO)
        {
            [self priCancelDownload:self.requests];
        }else
        {
            return self;
        }
    }
    
    self.requests = fiterArray;

    return self;
}

#pragma mark - EKDownloadRequestProtocol

- (void)cancel
{
    [self priCancelDownload:self.requests];
}

- (void)silenceCancel
{
    self.canceSilenceFlag = YES;
    [self cancel];
}

- (void)startDownload
{
    if (self.requests.count == 0) {
        return;
    }
    
    if (self.requestRunning) {
        return;
    }
    
    self.requestRunning = YES;
    [self priStartDownload:self.requests];
}

- (void)priStartDownload:(NSArray<EKDownloadRequest*> *)requestArray
{
    if ([requestArray isKindOfClass:[NSArray<EKDownloadRequest*> class]])
    {
        for (EKDownloadRequest *request in self.requests)
        {
            [request downloadInvokeRequest:self progress:request.progressBlock complete:request.resultBlock];
        }
    }
}

- (void)priCancelDownload:(NSArray<EKDownloadRequest*> *)requestArray
{
    if ([requestArray isKindOfClass:[NSArray<EKDownloadRequest*> class]])
    {
        for (EKDownloadRequest *request in requestArray)
        {
            [request silenceCancel];
        }
    }
    self.requests = nil;
}

- (void)startDownload:(EKProgressBlock)progressBlock complete:(void(^)(id<EKDownloadResultProtocol>result))complete
{
    NSLog(@"多资源下载不能调用该方法");
}

- (void)startMutDownload:(EKProgressBlock)progressBlock complete:(void(^)(NSArray<id<EKDownloadResultProtocol>> *result))complete
{
    if (self.requests.count == 0) {
        return;
    }
    
    // running request
    if (self.requestRunning) {
        return;
    }
    
    self.requestRunning = YES;
    self.progressBlock = progressBlock;
    self.completeBlock = complete;
    self.reqeustCopies = 1.0/(self.requests.count);
    self.finishResults = [NSMutableArray<EKDownloadResultProtocol> arrayWithCapacity:self.requests.count];
    self.progressDic = [NSMutableDictionary dictionary];

    //
    for (EKDownloadRequest *request in self.requests)
    {
        [request downloadInvokeRequest:self progress:request.progressBlock complete:request.resultBlock];
    }
}

#pragma mark - EKDownloadDemandDelegate

- (void)proDownloadRequestStart:(EKDownloadDemand *)demand
{
    for (EKDownloadRequest *request in self.requests) {
        if (request.downDemand == demand)
        {
            request.downDemand.task = demand.task;
        }
    }
}

- (void)proDownloadRequestDownProgress:(EKDownloadDemand *)demand
{
    // 单个下载
    if ([self.delegate respondsToSelector:@selector(netWorkDownloadRequest:progress:)])
    {
        [self.delegate netWorkDownloadRequest:self progress:demand.receiveProgress];
    }
    
    // 多个下载
    if ([self.delegate respondsToSelector:@selector(netWorkMutipleDownloadRequest:progress:)])
    {
        [self.delegate netWorkMutipleDownloadRequest:self progress:demand.receiveProgress];
    }
    
    // 如果有单个进度，执行单个进度
    if ([demand.info isKindOfClass:[EKDownloadRequest class]])
    {
        EKDownloadRequest *request = (EKDownloadRequest *)demand.info;
        if (request.progressBlock != nil)
        {
            request.progressBlock(demand.receiveProgress);
        }
    }
    
    // 多个 进度
    if (self.progressBlock != nil)
    {
        //
        double totalComplete = 0.0;
        NSString *rate = [NSString stringWithFormat:@"%f",demand.receiveProgress.fractionCompleted];
        Lock();
        if (demand.fileName.length > 0 && rate.length > 0) {
            [_progressDic setValue:rate forKey:demand.fileName];
        }
   
        for (NSString *key in self.progressDic.allKeys) {
            NSString *proKey = [self.progressDic valueForKey:key];
            totalComplete += proKey.floatValue;
        }
        Unlock();

        self.downProgress.completedUnitCount = totalComplete * self.reqeustCopies * 1000;
        self.progressBlock(self.downProgress);
    }
}

- (void)proDownloadRequestCompleted:(EKDownloadDemand *)demand
{
    [self mutFinishAndExcuteHander:demand];
}

#pragma mark - tools

- (void)mutFinishAndExcuteHander:(EKDownloadDemand *)demand
{
    EKNetDownloadResult *result = [[EKNetDownloadResult alloc] initWithDemand:demand];
    Lock();
    [self.finishResults addObject:result];
    Unlock();
    
    EKDownloadRequest *request = nil;
    // 如果有单个进入，执行单个完成block
    if ([demand.info isKindOfClass:[EKDownloadRequest class]])
    {
        request = (EKDownloadRequest *)demand.info;
    }
    
    
    // 沉默取消，不调用block/delegate
    BOOL isCancelled = (demand.error != nil && demand.error.code == NSURLErrorCancelled);
    if (!isCancelled || (isCancelled && !self.canceSilenceFlag) )
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 单个完成 回调
            if ([self.delegate respondsToSelector:@selector(netWorkDownloadRequest:result:)])
            {
                [self.delegate netWorkDownloadRequest:self result:result];
            }
            
            // 如果有单个进入，执行单个完成block
            if (request != nil)
            {
                if (request.resultBlock != nil)
                {
                    request.resultBlock(result);
                    request.resultBlock = nil;
                }
            }
        });
    }
    
    if (self.finishResults.count >= self.requests.count)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(netWorkMutipleDownloadRequest:results:)])
            {
                [self.delegate netWorkMutipleDownloadRequest:self results:self.finishResults];
            }
            
            if (self.completeBlock != nil)
            {
                self.completeBlock(self.finishResults);
                self.completeBlock = nil;
            }
            self.requestRunning = NO;
            
            self.finishResults = nil;
            self.progressDic = nil;
            self.requests = nil;
        });
    }
}

- (NSArray<EKDownloadRequest*> *)fiterSameUrlToMerge:(NSArray<EKDownloadRequest*> *)oriRequests
{
    NSMutableArray *urlArray = [NSMutableArray array];
    NSMutableArray<EKDownloadRequest*> *mutArr = [NSMutableArray array];
    for (EKDownloadRequest *request in oriRequests)
    {
        if (request.url.length > 0 && [urlArray containsObject:request.url] == NO)
        {
            [urlArray addObject:request.url];
            [mutArr addObject:request];
        }
    }
    return mutArr;
}

- (NSArray<EKDownloadRequest*> *)getDownloadInfosWithUrls:(NSArray <NSString *> *)urls
{
    NSTimeInterval timeoutInterval = 30;
    EKNetMethod method = EKNetGet;
    EKResponseSerializer serializer = EKNetJson;
    BOOL useCache = YES;
    BOOL appendSuggestIfNoExtension = YES;
    
    NSMutableArray<EKDownloadRequest*> *infos = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSString *url in urls)
    {
        EKDownloadRequest *info = [[EKDownloadRequest alloc] initWithUrl:url];
        info.method = method;
        info.timeoutInterval = timeoutInterval;
        info.useCache = useCache;
        info.serializer = serializer;
        info.appendSuggestIfNoExtension = appendSuggestIfNoExtension;
        [infos addObject:info];
    }
    return infos;
}

@end















