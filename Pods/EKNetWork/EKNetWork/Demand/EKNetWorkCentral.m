//
//  EKNetAgent.m
//  EKNetWork
//
//  Created by mac on 2018/11/23.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKNetWorkCentral.h"
#import <pthread/pthread.h>

#import "EKUploadDemand.h"
#import "EKDataDemand.h"
#import "EKDownloadDemand.h"
#import "EKNetWorkTool.h"
#import "EKNetWorkConfg.h"

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@interface EKNetWorkCentral()
{
    AFHTTPSessionManager *_httpSession;
    AFURLSessionManager *_uploadSession;
    AFURLSessionManager *_downloadSession;
    
    NSFileManager *_fileManager;
    
    pthread_mutex_t _lock;
    AFJSONResponseSerializer *_jsonResponseSerializer;
    AFXMLParserResponseSerializer *_xmlResponseSerialzier;
    
    NSMutableDictionary<NSString *, NSMutableArray<EKDownloadDemand *> *> *_downDemandDic;
    NSMutableDictionary<NSString *, EKDownloadDemand*> *_realDownDic;
}
@end

@implementation EKNetWorkCentral

NS_INLINE NSString *netHttpMethod(EKNetMethod method)
{
    switch (method) {
        case EKNetPost:
            return @"POST";
            break;
        case EKNetGet:
            return @"GET";
            break;
        case EKNetPut:
            return @"PUT";
            break;
        case EKNetDelete:
            return @"DELETE";
            break;
        case EKNetPatch:
            return @"PATCH";
            break;
        case EKNetHead:
            return @"HEAD";
            break;
        default:
            return @"POST";
            break;
    }
}

NS_INLINE NSString *taskIdentifyKey(NSURLSessionTask *task)
{
   return [NSString stringWithFormat:@"%lu",(unsigned long)task.taskIdentifier];
}

#pragma mark - lifeCycle
+ (EKNetWorkCentral *)shared
{
    static dispatch_once_t onceToken;
    static EKNetWorkCentral *onceOjbect;
    dispatch_once(&onceToken, ^{
        onceOjbect = [[self alloc] init];
    });
    return onceOjbect;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        _downDemandDic = [NSMutableDictionary dictionary];
        _fileManager = [NSFileManager defaultManager];
        _realDownDic = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - dataRequest

- (void)startDataRequest:(EKDataDemand *)demand
{
    NSError *serializerError = nil;
    NSURLSessionDataTask *dataTask = [self dataTaskWithDemand:demand error:serializerError];
    
    if (serializerError != nil) {
        
        if ([demand.delegate respondsToSelector:@selector(proDataRequestCompleted:)])
        {
            demand.error = serializerError;
            [demand.delegate proDataRequestCompleted:demand];
        }
        return;
    }
    
    [dataTask resume];
    demand.task = dataTask;
    
    //
    if ([demand.delegate respondsToSelector:@selector(proDataRequestStart:)])
    {
        [demand.delegate proDataRequestStart:demand];
    }
}

- (void)removeDataRequest:(EKDataDemand *)demand
{
    [demand.task cancel];
}

#pragma mark - uploadRequest

- (void)startUploadRequest:(EKUploadDemand *)demand
{
    NSError *serializerError = nil;
    NSURLSessionUploadTask *uploadTask = [self uploadTaskWithDemand:demand error:serializerError];
    
    if (serializerError != nil) {
        
        if ([demand.delegate respondsToSelector:@selector(proUploadRequestCompleted:)])
        {
            demand.error = serializerError;
            [demand.delegate proUploadRequestCompleted:demand];
        }
        return;
    }
    
    [uploadTask resume];
    demand.task = uploadTask;
    
    //
    if ([demand.delegate respondsToSelector:@selector(proUploadRequestStart:)])
    {
        [demand.delegate proUploadRequestStart:demand];
    }
}

- (void)removeUploadRequest:(EKUploadDemand *)demand
{
    [demand.task cancel];
}

#pragma mark - downloadRequest
- (void)startDownloadRequest:(EKDownloadDemand *)demand
{
    // 如果存在，直接完成
    if ([self checkLocalExistFullPath:demand extension:demand.info.url.pathExtension]) {
        return;
    }
    
    // 如果之前有已经在执行的demand，就不继续执行
    if ([self checkExistRuningAndsetToPool:demand]) {
        return;
    }
    
    // 生成task并执行
    NSError *serializerError = nil;
    NSURLSessionTask *dataTask;
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0)
    {
        dataTask = [self downloadForDataTaskWithDemand:demand error:serializerError];
    } else {
        dataTask = [self downloadTaskWithDemand:demand error:serializerError];
    }
    
    //
    if ([demand.delegate respondsToSelector:@selector(proDownloadRequestStart:)])
    {
        [demand.delegate proDownloadRequestStart:demand];
    }
    
    //
    if (serializerError != nil) {
        
        if ([demand.delegate respondsToSelector:@selector(proDownloadRequestCompleted:)])
        {
            demand.error = serializerError;
            [demand.delegate proDownloadRequestCompleted:demand];
        }
        return;
    }
    
    [dataTask resume];
    demand.task = dataTask;
    // 把真实请求的demand，放入到_realDownDic中
    Lock();
    [_realDownDic setValue:demand forKey:taskIdentifyKey(dataTask)];
    Unlock();
}

- (void)removeDownloadRequest:(EKDownloadDemand *)demand
{
    if (demand.task != nil && demand.task.state == NSURLSessionTaskStateRunning)
    {
        // 如果是真正的请求者，调用cancel方法，否则只需要从dic中移除
        [demand.task cancel];
    } else
    {
        [self removeDownDemandFromPool:demand];
    }
}

#pragma mark - getTask

- (NSURLSessionDataTask *)dataTaskWithDemand:(EKDataDemand *)demand error:(NSError * __autoreleasing _Nullable)error
{
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSURLRequest *request = demand.oriRequest;
    AFHTTPSessionManager *httpSesson = [self httpSession];
    
    if (nil != request)
    {
        return [httpSesson dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error){
            [self handlerFinishedRequest:demand startTime:startTime response:response result:responseObject error:error];
        }];
    } else
    {
        AFHTTPRequestSerializer *serializer = [self requestSerializer:demand];
        NSString *method = netHttpMethod(demand.info.method);
        demand.oriRequest = [serializer requestWithMethod:method URLString:demand.info.url parameters:demand.argument error:&error];
        
        return [httpSesson dataTaskWithRequest:demand.oriRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error){
            [self handlerFinishedRequest:demand startTime:startTime response:response result:responseObject error:error];
        }];
    }
}

- (NSURLSessionUploadTask *)uploadTaskWithDemand:(EKUploadDemand *)demand error:(NSError * __autoreleasing _Nullable)error
{
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    AFHTTPRequestSerializer *serializer = [self requestSerializer:demand];
    AFURLSessionManager *uploadSession = [self uploadSession];
    
    EKNetMethod netMedthod = (demand.info.method == EKNetGet || demand.info.method == EKNetHead) ? EKNetPost : demand.info.method;
    NSString *method = netHttpMethod(netMedthod);
    
    if (demand.fromData != nil)
    {
        demand.oriRequest = [serializer requestWithMethod:method URLString:demand.info.url parameters:demand.argument error:&error];
        return [uploadSession uploadTaskWithRequest:demand.oriRequest fromData:demand.fromData progress:^(NSProgress * _Nonnull uploadProgress) {

            [self handlerUploadProgressRequest:demand progress: uploadProgress];
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [self handlerFinishedRequest:demand startTime:startTime response:response result:responseObject error:error];
        }];
    } else if(demand.fromURL != nil)
    {
        demand.oriRequest = [serializer requestWithMethod:method URLString:demand.info.url parameters:demand.argument error:&error];
        return [uploadSession uploadTaskWithRequest:demand.oriRequest fromFile:demand.fromURL progress:^(NSProgress * _Nonnull uploadProgress) {
            
            [self handlerUploadProgressRequest:demand progress: uploadProgress];
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [self handlerFinishedRequest:demand startTime:startTime response:response result:responseObject error:error];
        }];
    } else
    {
        demand.oriRequest = [serializer multipartFormRequestWithMethod:method URLString:demand.info.url parameters:demand.argument constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            [self appendUploadPackData:formData uploadDemand:demand];
        } error:&error];
        
        return [uploadSession uploadTaskWithStreamedRequest:demand.oriRequest progress:^(NSProgress * _Nonnull uploadProgress) {
            
            [self handlerUploadProgressRequest:demand progress: uploadProgress];
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            [self handlerFinishedRequest:demand startTime:startTime response:response result:responseObject error:error];
        }];
    }
}

- (NSURLSessionDataTask *)downloadForDataTaskWithDemand:(EKDownloadDemand *)demand error:(NSError * __autoreleasing _Nullable)error
{
    AFURLSessionManager *downSession = [self downloadSession];
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    AFHTTPRequestSerializer *serializer = [self requestSerializer:demand];
    NSString *method = netHttpMethod(demand.info.method);
    NSMutableURLRequest *mutRequest = [serializer requestWithMethod:method URLString:demand.info.url parameters:demand.argument error:&error];
    int64_t cacheLenght = [EKNetWorkTool getContentFileLength:demand.cachePath];
    demand.oriRequest = mutRequest;

    if (cacheLenght > 0)
    {
        demand.cacheLenght = cacheLenght;
        NSString *rang = [NSString stringWithFormat:@"bytes=%lld-",demand.cacheLenght];
        [mutRequest setValue:rang forHTTPHeaderField:@"Range"];
    }
    
    NSURLSessionDataTask *dataTask = [downSession dataTaskWithRequest:demand.oriRequest uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        [self handlerFinishedRequest:demand startTime:startTime response:response result:responseObject error:error];
    }];
    
    [downSession setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSURLResponse * _Nonnull response) {
        return [self handlerReceiveDataResponse:response dataTask:dataTask];
    }];
    
    [downSession setDataTaskDidReceiveDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDataTask * _Nonnull dataTask, NSData * _Nonnull data) {
        [self handlerReceiveWithData:data task:dataTask];
    }];
    
    return dataTask;
}

- (NSURLSessionDownloadTask *)downloadTaskWithDemand:(EKDownloadDemand *)demand error:(NSError * __autoreleasing _Nullable)error
{
    AFURLSessionManager *downSession = [self downloadSession];
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    AFHTTPRequestSerializer *serializer = [self requestSerializer:demand];
    NSString *method = netHttpMethod(demand.info.method);
    demand.oriRequest = [serializer requestWithMethod:method URLString:demand.info.url parameters:nil error:&error];
    
    //替换临时路径
    [self appendTmpKeyWithPath:demand];
    //
    return [downSession downloadTaskWithRequest:demand.oriRequest progress:^(NSProgress * _Nonnull downloadProgress) {
        
        demand.receiveProgress.totalUnitCount = downloadProgress.totalUnitCount;
        demand.receiveProgress.completedUnitCount = downloadProgress.completedUnitCount;
        [self syncPoolDemandProgressWithCurrentDemand:demand];
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if ([self checkLocalExistFullPath:demand extension:response.suggestedFilename.pathExtension]) {
            return [NSURL fileURLWithPath:@""];
        }
        
        return [NSURL fileURLWithPath:demand.cachePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [self handlerFinishedRequest:demand startTime:startTime response:response result:nil error:error];
    }];
}

#pragma mark - sync pool demand invoke
// 同步完成逻辑
- (void)syncPoolDemandCompleteCurrentDemand:(EKDownloadDemand *)demand
{
    if (demand.error == nil)
    {
        NSString *oldExtension = demand.info.url.pathExtension;
        
        if (oldExtension.length == 0)
        {
            oldExtension = demand.response.suggestedFilename.pathExtension;
            if (nil != demand.info && demand.info.appendSuggestIfNoExtension == NO)
            {
                oldExtension = @"";
            }
        }
        
        NSString *extensionKey = oldExtension.length > 0 ? [NSString stringWithFormat:@".%@",oldExtension] : @"";
        NSString *newPath = [NSString stringWithFormat:@"%@/%@%@",demand.cacheFolder,demand.fileName,extensionKey];
        if ([self replaceFileFromPath:demand.cachePath to:newPath])
        {
            demand.cachePath = newPath;
        }
        
        NSArray *newArray = [self getNewArrayWithDemand:demand removeOriginal:YES];
        //
        [self removeDownDemandFromPool:demand];
        
        //
        if ([newArray isKindOfClass:[NSArray class]] && newArray.count > 0)
        {
            for (EKDownloadDemand *downDemand in newArray)
            {
                downDemand.error = demand.error;
                downDemand.response = demand.response;
                downDemand.cachePath = demand.cachePath;
                downDemand.duration = demand.duration;
                downDemand.responseObject = demand.responseObject;
                downDemand.responseString = demand.responseString;
                downDemand.oriRequest = demand.oriRequest;
                
                if ([downDemand.delegate respondsToSelector:@selector(proDownloadRequestCompleted:)])
                {
                    [downDemand.delegate proDownloadRequestCompleted:downDemand];
                }
            }
        } else {
            
            if ([demand.delegate respondsToSelector:@selector(proDownloadRequestCompleted:)])
            {
                [demand.delegate proDownloadRequestCompleted:demand];
            }
        }
    } else
    {
        // 从pool中移除
        [self removeDownDemandFromPool:demand];
        // 当前demand非正常结束，只标记当前demand的完成方法，数组中的其他demand，继续尝试请求
        if ([demand.delegate respondsToSelector:@selector(proDownloadRequestCompleted:)])
        {
            [demand.delegate proDownloadRequestCompleted:demand];
        }
        
        // 把本地临时缓存名字，替换成非临时名字
        [self removeAppendTmpKeyWithPath:demand];

        //如果真正执行的demand结束了请求，则从arr中继续获取剩余进行请求
        NSArray *array = [self getNewArrayWithDemand:demand removeOriginal:NO];
        if (array.count > 0)
        {
            [self startDownloadRequest:array.firstObject];
        }
    }
}

// 同步下载进度
- (void)syncPoolDemandProgressWithCurrentDemand:(EKDownloadDemand *)demand
{
    NSArray *newArray = [self getNewArrayWithDemand:demand removeOriginal:NO];
    if ([newArray isKindOfClass:[NSArray class]] && newArray.count > 1)
    {
        for (EKDownloadDemand *downDemand in newArray)
        {
            downDemand.cacheLenght = demand.cacheLenght;
            downDemand.receiveProgress.totalUnitCount = demand.receiveProgress.totalUnitCount;
            downDemand.receiveProgress.completedUnitCount = demand.receiveProgress.completedUnitCount;
            
            if ([downDemand.delegate respondsToSelector:@selector(proDownloadRequestDownProgress:)])
            {
                [downDemand.delegate proDownloadRequestDownProgress:downDemand];
            }
        }
    } else
    {
        if ([demand.delegate respondsToSelector:@selector(proDownloadRequestDownProgress:)])
        {
            [demand.delegate proDownloadRequestDownProgress:demand];
        }
    }
}

#pragma mark - handler
- (void)handlerUploadProgressRequest:(EKUploadDemand *)uploadDemand progress:(NSProgress *)progress;
{
    if ([uploadDemand.delegate respondsToSelector:@selector(proUploadRequestProgress:progress:)])
    {
        [uploadDemand.delegate proUploadRequestProgress:uploadDemand progress:progress];
    }
}

- (void)handlerReceiveWithData:(NSData *)data task:(NSURLSessionDataTask *)dataTask
{
    Lock();
    EKDownloadDemand *demand = _realDownDic[taskIdentifyKey(dataTask)];
    Unlock();
    
    if ([demand isKindOfClass:[EKDownloadDemand class]])
    {
        [demand.fileSream write:data.bytes maxLength:data.length];
        demand.cacheLenght = demand.cacheLenght + data.length;
        demand.receiveProgress.completedUnitCount = demand.cacheLenght;
        
        [self syncPoolDemandProgressWithCurrentDemand:demand];
    }
}

- (NSURLSessionResponseDisposition)handlerReceiveDataResponse:(NSURLResponse *)response dataTask:(NSURLSessionDataTask *)dataTask
{
    Lock();
    EKDownloadDemand *demand = _realDownDic[taskIdentifyKey(dataTask)];
    Unlock();
    
    if ([demand isKindOfClass:[EKDownloadDemand class]])
    {
        //如果存在直接cancel
        if ([self checkLocalExistFullPath:demand extension:response.suggestedFilename.pathExtension])
        {
            return NSURLSessionResponseCancel;
        }
        //替换临时路径
        [self appendTmpKeyWithPath:demand];
        //
        BOOL isEnableRangDownload = [EKNetWorkTool resonseEnableByRangeDownload:response];
        if (isEnableRangDownload == NO)
        {
            // 如果不支持断点下载，删除本地缓存，从新下载
            Lock();
            [_fileManager removeItemAtPath:demand.cachePath error:nil];
            Unlock();
            demand.receiveProgress.totalUnitCount = 0 + response.expectedContentLength;
        } else
        {
            demand.receiveProgress.totalUnitCount = demand.cacheLenght + response.expectedContentLength;
        }
        
        NSURL *cacheURL = [NSURL fileURLWithPath:demand.cachePath];
        demand.fileSream = [NSOutputStream outputStreamWithURL:cacheURL append:YES];
        [demand.fileSream open];
        
        return NSURLSessionResponseAllow;
    }
    
    return NSURLSessionResponseCancel;
}

- (void)handlerFinishedRequest:(EKNetDemand *)demand
                     startTime:(NSTimeInterval)start
                      response:(NSURLResponse *)response
                        result:(id)result
                         error:(NSError *)error
{
    demand.error = error;
    demand.response = response;
    demand.responseData = result;
    demand.duration = [[NSDate date] timeIntervalSince1970]-start;
    if ([result isKindOfClass:[NSData class]])
    {
        demand.responseString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    }
    
    if([demand isKindOfClass:[EKDownloadDemand class]])
    {
        demand.responseObject = demand.responseString;
        [self syncPoolDemandCompleteCurrentDemand:(EKDownloadDemand *)demand];
    } else
    {
        if ([demand isKindOfClass:[EKDataDemand class]])
        {
            EKDataDemand * dataDemand = (EKDataDemand *)demand;
            if ([dataDemand.delegate respondsToSelector:@selector(proDataRequestCompleted:)])
            {
                [self serializerParserResponse:dataDemand];
                
                [dataDemand.delegate proDataRequestCompleted:dataDemand];
            }
        } else
        {
            demand.responseObject = demand.responseString;
            EKUploadDemand * uploadDemand = (EKUploadDemand *)demand;
            if ([uploadDemand.delegate respondsToSelector:@selector(proUploadRequestCompleted:)])
            {
                [uploadDemand.delegate proUploadRequestCompleted:uploadDemand];
            }
        }
    }
}

#pragma mark - Tool
- (BOOL)replaceFileFromPath:(NSString *)fromPath to:(NSString *)toPath
{
    BOOL flg = NO;
    if ([_fileManager fileExistsAtPath:fromPath])
    {
        Lock();
        flg = [_fileManager moveItemAtPath:fromPath toPath:toPath error:nil];
        Unlock();
    } else
    {
        if ([_fileManager fileExistsAtPath:toPath])
        {
            flg = YES;
        }
    }
    return flg;
}

// 此方法检测的是完整路径，必须包含扩展名字，否则当成本地未下载完的缓存
- (BOOL)checkLocalExistFullPath:(EKDownloadDemand *)demand extension:(NSString *)extension
{
    if (extension.length ==0 || demand.cachePath.length == 0)
    {
        return NO;
    }
    
    NSString *fullPath = [demand.cachePath stringByAppendingPathExtension:extension];
    BOOL flg = [_fileManager fileExistsAtPath:fullPath];
    if (flg)
    {
        demand.receiveProgress.totalUnitCount = 1;
        demand.receiveProgress.completedUnitCount = 1;
        [self syncPoolDemandProgressWithCurrentDemand:demand];
        [self syncPoolDemandCompleteCurrentDemand:demand];
    }
    return flg;
}

// 把demand放入全局dic中, 并且检测arr中是否存在正在执行的task，如果有返回nil，否则返回当前demand执行
- (BOOL)checkExistRuningAndsetToPool:(EKDownloadDemand *)downDemand
{
    BOOL haveRunning = NO;
    Lock();
    if ([_downDemandDic.allKeys containsObject:downDemand.fileName])
    {
        NSMutableArray *sets = [_downDemandDic valueForKey:downDemand.fileName];
        for (EKDownloadDemand *demand in sets)
        {
            if (demand.task != nil && (demand.task.state == NSURLSessionTaskStateRunning || demand.task.state == NSURLSessionTaskStateCanceling))
            {
                haveRunning = YES;
                break;
            }
        }
        
        if ([sets containsObject:downDemand] == NO)
        {
            [sets addObject:downDemand];
        }
        [_downDemandDic setValue:sets forKey:downDemand.fileName];
    } else
    {
        NSMutableArray<EKDownloadDemand *> *sets = [NSMutableArray arrayWithObject:downDemand];
        [_downDemandDic setValue:sets forKey:downDemand.fileName];
    }
    Unlock();
    return haveRunning;
}

- (NSArray *)getNewArrayWithDemand:(EKDownloadDemand *)demand removeOriginal:(BOOL)isRemove
{
    NSArray *newSets = nil;
    Lock();
    NSMutableArray *sets = [_downDemandDic valueForKey:demand.fileName];
    if ([sets isKindOfClass:[NSArray class]] && sets.count > 0)
    {
        newSets = [NSArray arrayWithArray:sets];
    }
    if (isRemove)
    {
        [_downDemandDic removeObjectForKey:demand.fileName];
    }
    Unlock();
    return newSets;
}

// 取消或者完成后，把demand从pool中移除
- (void)removeDownDemandFromPool:(EKDownloadDemand *)downDemand
{
    Lock();
    if (downDemand.task != nil && downDemand.task.state == NSURLSessionTaskStateRunning)
    {
        [_realDownDic removeObjectForKey:taskIdentifyKey(downDemand.task)];
    }
    
    if ([_downDemandDic.allKeys containsObject:downDemand.fileName])
    {
        NSMutableArray *sets = [_downDemandDic valueForKey:downDemand.fileName];
        if ([sets containsObject:downDemand])
        {
            [sets removeObject:downDemand];
        }
        
        if (sets.count > 0)
        {
            [_downDemandDic setValue:sets forKey:downDemand.fileName];
        } else {
            [_downDemandDic removeObjectForKey:downDemand.fileName];
        }
    }
    // 没有正在执行的下载，销毁session
    if (_downDemandDic.allKeys == 0)
    {
        [[self downloadSession] invalidateSessionCancelingTasks:YES];
        _downloadSession = nil;
    }
    Unlock();
}

//
- (void)appendTmpKeyWithPath:(EKDownloadDemand *)demand
{
    NSString *tmpPath = [EKNetWorkTool appendTempKeyWithMediaPath:demand.cachePath];
    if ([_fileManager fileExistsAtPath:demand.cachePath])
    {
        [self replaceFileFromPath:demand.cachePath to:tmpPath];
    }
    demand.cachePath = tmpPath;
}

- (void)removeAppendTmpKeyWithPath:(EKDownloadDemand *)demand
{
    [demand.fileSream close];
    // 把本地临时缓存名字，替换成非临时名字
    NSString *cachePath = [EKNetWorkTool deleteTempKeyWithMediaPath:demand.cachePath];
    if ([_fileManager fileExistsAtPath:demand.cachePath])
    {
        [self replaceFileFromPath:demand.cachePath to:cachePath];
    }
    demand.cachePath = cachePath;
}

- (void)appendUploadPackData:(id<AFMultipartFormData>)formData uploadDemand:(EKUploadDemand *)demand
{
    if (demand.packData != nil)
    {
        id<EKUploadFormDataProtocol> fData = demand.packData;
        
        if (fData.fileURL != nil ){
            if (fData.mimeType.length > 0) {
                [formData appendPartWithFileURL:fData.fileURL name:fData.name fileName:fData.fileName mimeType:fData.mimeType error:nil];
            } else {
                [formData appendPartWithFileURL:fData.fileURL name:fData.name error:nil];
            }
        } else if(fData.data != nil) {
            if (fData.mimeType.length > 0 ) {
                [formData appendPartWithFileData:fData.data name:fData.name fileName:fData.fileName mimeType:fData.mimeType];
            } else {
                [formData appendPartWithFormData:fData.data name:fData.name];
            }
        }
    }
}

- (AFHTTPRequestSerializer *)requestSerializer:(EKNetDemand *)demand
{
    NSTimeInterval timeInterval = 15.0;
    if ([demand isKindOfClass:[EKDownloadDemand class]]) {
        
        timeInterval = [(EKDownloadDemand *)demand info].timeoutInterval;
    } else if([demand isKindOfClass:[EKDataDemand class]]) {
        
        timeInterval = [(EKDataDemand *)demand info].timeoutInterval;
    } else if([demand isKindOfClass:[EKUploadDemand class]]) {
        
        timeInterval = [(EKUploadDemand *)demand info].timeoutInterval;
    }
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    serializer.timeoutInterval = timeInterval;
    return serializer;
}

- (void)serializerParserResponse:(EKDataDemand *)demand
{
    if ([demand.responseData isKindOfClass:[NSData class]])
    {
        NSString *oriJson = demand.responseString;
        NSData *oriData = demand.responseData;
        if ([EKNetWorkConfg shared].intToString == YES)
        {
            NSString *newJson = [EKNetWorkTool changeJsonIntToString:oriJson];
            NSData *newData = [newJson dataUsingEncoding:NSUTF8StringEncoding];
            
            demand.responseString = newJson;
            demand.responseObject = [self serializerObjectWithData:newData response:demand.response serializer:demand.info.serializer];
        }
        
        if (demand.responseObject == nil)
        {
            id serializerObject = [self serializerObjectWithData:oriData response:demand.response serializer:demand.info.serializer];
            demand.responseString = oriJson;
            demand.responseObject = serializerObject == nil ? oriJson : serializerObject;
        }
    }
}

- (id)serializerObjectWithData:(NSData *)data response:(id)response serializer:(EKResponseSerializer)serializer
{
    id responseObject = nil;
    NSError *serializerError;
    if (serializer == EKNetJson)
    {
        responseObject =[self.jsonResponseSerializer responseObjectForResponse:response
                                                                     data:data
                                                                    error:&serializerError];
        // 部分server返回的response的MIMEType和实际数据不匹配验证不通过，导致serializer失败, 尝试直接serializer
        if (serializerError != nil && serializerError.domain == AFURLResponseSerializationErrorDomain)
        {
            responseObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        }
    } else if(serializer == EKNetXml)
    {
        responseObject = [self.xmlResponseSerialzier responseObjectForResponse:response
                                                                     data:data
                                                                    error:&serializerError];
        
        // 部分server返回的response的MIMEType和实际数据不匹配验证不通过，导致serializer失败, 尝试直接serializer
        if (serializerError != nil && serializerError.domain == AFURLResponseSerializationErrorDomain)
        {
            responseObject = [[NSXMLParser alloc] initWithData:data];
        }
    }
    
    return responseObject;
}

#pragma mark - lazy

- (id <AFURLResponseSerialization>)requestSesonseSerializer
{
    AFHTTPResponseSerializer *responSerializer = [AFHTTPResponseSerializer serializer];
    responSerializer.acceptableContentTypes = [NSSet setWithArray:[EKNetWorkConfg shared].acceptTypes];
    return responSerializer;
}

- (AFHTTPSessionManager *)httpSession
{
    if (!_httpSession) {
        
        _httpSession = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[EKNetWorkConfg shared].configuration];
        _httpSession.completionQueue = dispatch_queue_create("ekwing.EKNetWork.downloadRequet", DISPATCH_QUEUE_CONCURRENT);
        _httpSession.responseSerializer = [self requestSesonseSerializer];
    }
    return _httpSession;
}

- (AFURLSessionManager *)uploadSession
{
    if (!_uploadSession) {
        _uploadSession = [[AFURLSessionManager alloc] initWithSessionConfiguration:[EKNetWorkConfg shared].configuration];
        _uploadSession.completionQueue = dispatch_queue_create("ekwing.EKNetWork.uploadRequest", DISPATCH_QUEUE_CONCURRENT);
        _uploadSession.responseSerializer = [self requestSesonseSerializer];
    }
    return _uploadSession;
}

- (AFURLSessionManager *)downloadSession
{
    if (!_downloadSession) {
        _downloadSession = [[AFURLSessionManager alloc] initWithSessionConfiguration:[EKNetWorkConfg shared].configuration];
        _downloadSession.completionQueue = dispatch_queue_create("ekwing.EKNetWork.downloadRequet", DISPATCH_QUEUE_CONCURRENT);
        _downloadSession.responseSerializer =  [AFHTTPResponseSerializer serializer];
    }
    return _downloadSession;
}

- (AFJSONResponseSerializer *)jsonResponseSerializer {
    if (!_jsonResponseSerializer) {
        _jsonResponseSerializer = [AFJSONResponseSerializer serializer];
    }
    return _jsonResponseSerializer;
}

- (AFXMLParserResponseSerializer *)xmlResponseSerialzier {
    if (!_xmlResponseSerialzier) {
        _xmlResponseSerialzier = [AFXMLParserResponseSerializer serializer];
    }
    return _xmlResponseSerialzier;
}

@end
