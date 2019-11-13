//
//  EKDataRequestManager.m
//  EKNetWork
//
//  Created by mac on 2019/5/29.
//  Copyright © 2019 ekwing. All rights reserved.
//

#import "EKDataRequestManager.h"
#import "EKDataRequest.h"
#import "EKNetDataResult.h"
#import "EKNetWorkConfg.h"

@interface EKDataRequestManager()

@property (nonatomic, strong) NSMutableDictionary *cacheDic;
@property (nonatomic, strong) NSLock *lock;

@end

@implementation EKDataRequestManager

+ (EKDataRequestManager *)shared;
{
    static dispatch_once_t onceToken;
    static EKDataRequestManager *onceOjbect;
    dispatch_once(&onceToken, ^{
        onceOjbect = [[self alloc] init];
    });
    return onceOjbect;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _cacheDic = [NSMutableDictionary dictionary];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

///
- (void)startWithUrl:(nonnull NSString *)url
            argument:(nullable id)argument
            complete:(void(^)(id<EKDataResultProtocol>result))complete
{
    EKDataInfo *info = [[EKDataInfo alloc] initWithUrl:url];    
    [self startWithInfo:info argument:argument complete:complete];
}

///
- (void)startWithInfo:(nonnull id<EKInfoProtocol>)info
             argument:(nullable id)argument
             complete:(void(^)(id<EKDataResultProtocol>result))complete
{
    EKDataRequest *dataRequest = [[EKDataRequest alloc] initWithUrl:info.url];
    dataRequest.method = info.method;
    dataRequest.timeoutInterval = info.timeoutInterval;
    dataRequest.serializer = info.serializer;
    dataRequest.userData = info.userData;
    dataRequest.useCache = NO;
    dataRequest.retryCount = 0;
    dataRequest.delayInterval = 0;
    
    [dataRequest startWithArgument:argument complete:^(id<EKDataResultProtocol>  _Nonnull result) {
        
        complete(result);
        [self startDataStatic:dataRequest result:result];
        [self removeDataRequestFromPool:dataRequest];
    }];
    
    [self addDataRequestToPool:dataRequest];
}

///
- (void)startWithRequest:(nonnull NSURLRequest *)request
                complete:(void(^)(id<EKDataResultProtocol>result))complete
{
    EKDataRequest *dataRequest = [[EKDataRequest alloc] init];
    [dataRequest startWithRequest:request complete:^(id<EKDataResultProtocol>  _Nonnull result) {
        
        complete(result);
        [self startDataStatic:dataRequest result:result];
        [self removeDataRequestFromPool:dataRequest];
    }];
    [self addDataRequestToPool:dataRequest];
}


- (void)cancel
{
    [self priRealCancel:NO];
}

- (void)silenceCancel
{
    [self priRealCancel:YES];
}

- (void)priRealCancel:(BOOL)silence
{
    [self.lock tryLock];
    NSArray *keys = [[self.cacheDic allKeys] copy];
    [self.lock unlock];
    
    if (keys.count > 0)
    {
        for (int i=0; i<keys.count; i++)
        {
            NSString *key = [keys objectAtIndex:i];
            [self.lock tryLock];
            EKDataRequest *request = [self.cacheDic objectForKey:key];
            [self.lock unlock];
            
            if ([request isKindOfClass:[EKDataRequest class]])
            {
                if (silence)
                {
                    [request silenceCancel];
                }else {
                    [request cancel];
                }
            }
        }
    }
}

- (void)startDataStatic:(EKDataRequest *)request result:(id<EKDataResultProtocol>)result
{
    // 数据统计代理
    if ([EKNetWorkConfg shared].statisticDelegate && [[EKNetWorkConfg shared].statisticDelegate respondsToSelector:@selector(netWorkDataStatisticFinished:result:)] )
    {
        [[EKNetWorkConfg shared].statisticDelegate netWorkDataStatisticFinished:request result:result];
    }
}

#pragma mark - Tool

- (void)addDataRequestToPool:(EKDataRequest *)request
{
    if (request && request.task != nil)
    {
        [self.lock tryLock];
        [self.cacheDic setObject:request forKey:[NSString stringWithFormat:@"%lu",(unsigned long)request.task.taskIdentifier]];
        [self.lock unlock];
        
        
//        NSLog(@".........%@", self.cacheDic);
    }
}

- (void)removeDataRequestFromPool:(EKDataRequest *)request
{
    if (request && request.task != nil)
    {
        NSString *requestKey = [NSString stringWithFormat:@"%lu", (unsigned long)request.task.taskIdentifier];
        [self.lock tryLock];
        [self.cacheDic removeObjectForKey:requestKey];
        [self.lock unlock];
    }
    
//    NSLog(@"@@@@ cacheDic = %@",self.cacheDic);
}

@end

///
@implementation EKDataInfo
@synthesize url, method, timeoutInterval, serializer, userData;

- (instancetype)initWithUrl:(nonnull NSString *)url
{
    self = [super init];
    if (self) {
        self.url = url;
        self.method = EKNetPost;
        self.timeoutInterval = 20;
        self.serializer = EKNetJson;
        self.userData = @"";
    }
    return self;
}

@end
