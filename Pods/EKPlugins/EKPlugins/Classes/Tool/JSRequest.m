//
//  JSRequest.m
//  EKStudent
//
//  Created by chen on 2017/8/3.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import "JSRequest.h"
#import "EKPluginsTool.h"

@interface RequestMission : NSObject<NSURLSessionDownloadDelegate, NSURLSessionTaskDelegate,NSURLSessionDelegate>
typedef void (^BlockHandler)(NSURLResponse *response, NSURL *filePath, NSError *error);
typedef void (^BlockProgress)(float progress);

@property (nonatomic, copy) BlockHandler handlerB;
@property (nonatomic, copy) BlockProgress progressB;
@property (nonatomic, copy) NSURL *localURL;

- (NSURLSessionDownloadTask *)down:(NSString *)url localPath:(NSString *)localPath progress:(BlockProgress)pro handle:(BlockHandler)handler;

@end

@interface JSRequest()<NSURLSessionDelegate>

@end
@implementation JSRequest

static float _postTimeout = 15.0;
static float _downTimeout = 30.0;
+ (NSURLSessionDataTask *)POST:(NSString *) url
                    parameters:(id)parameters
                       success:(void (^)(NSURLResponse *response, id data))success
                       failure:(void (^)(NSURLResponse *response, NSError* error))failure {
    
    return [[self alloc] POST:url parameters:parameters success:success failure:failure];
    
}
- (NSURLSessionDataTask *)POST:(NSString *) url
                    parameters:(id)parameters
                       success:(void (^)(NSURLResponse *response, id data))success
                       failure:(void (^)(NSURLResponse *response, NSError* error))failure {
    if (parameters == nil || url.length == 0) {
        parameters = [NSMutableDictionary dictionaryWithCapacity:2];
    }
#ifdef DEBUG
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
#else
    NSURLSession *session = [NSURLSession sharedSession];
#endif
    
    NSString *parUrl = [[NSString alloc] init];
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        NSMutableString *mutString = [[NSMutableString alloc] init];
        [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            NSString *parKey = key;
            NSString *parValue = obj;
            [mutString appendFormat:@"%@=%@&",parKey,parValue];
        }];
        parUrl = [mutString substringToIndex:mutString.length-1];
    }
    
    
    NSData *bodyData = [parUrl dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSURL *requestUrl = [NSURL URLWithString:url];
    
    NSMutableURLRequest *mutRequest = [NSMutableURLRequest requestWithURL:requestUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_postTimeout];
    mutRequest.HTTPBody = bodyData;
    mutRequest.HTTPMethod = @"POST";
    
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSURLSessionDataTask *sessionTask = [session dataTaskWithRequest:mutRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        /// 请求完成后发送通知
        [EKPluginsTool netFinishToNotice:url method:mutRequest.HTTPMethod startTime:startTime response:response data:data error:error];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!error) {
                id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                if (success) {
                    if (obj != nil) {
                        //JSON数据
                        success(response, obj);
                    } else {
                        NSString *strRespone = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        //非JSON数据
                        success(response, strRespone);
                    }
                }
            } else {
                if (failure) {
                    failure(response, error);
                }
            }
        });
    }];
    [sessionTask resume];
    
    return sessionTask;
    
}

+ (NSURLSessionDataTask *)GET:(NSString *) url
                   parameters:(id)parameters
                      success:(void (^)(NSURLResponse *response, id data))success
                      failure:(void (^)(NSURLResponse *response, NSError* error))failure {
    if (parameters == nil || url.length == 0) {
        parameters = [NSMutableDictionary dictionaryWithCapacity:2];
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSString *parUrl = [[NSString alloc] init];
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        NSMutableString *mutString = [[NSMutableString alloc] init];
        [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            NSString *parKey = key;
            NSString *parValue = obj;
            [mutString appendFormat:@"%@=%@&",parKey,parValue];
        }];
        parUrl = [mutString substringToIndex:mutString.length-1];
    }
    
    NSString *requestUrl = [url containsString:@"?"] ? [NSString stringWithFormat:@"%@&%@", url, parUrl] : [NSString stringWithFormat:@"%@?%@", url, parUrl];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_postTimeout];
    
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSURLSessionDataTask *sessionTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        ///请求完成后发送通知
        [EKPluginsTool netFinishToNotice:url method:urlRequest.HTTPMethod startTime:startTime response:response data:data error:error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!error) {
                id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                if (success) {
                    if (obj != nil) {
                        //JSON数据
                        success(response, obj);
                    } else {
                        NSString *strRespone = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        //非JSON数据
                        success(response, strRespone);
                    }
                }
            } else {
                if (failure) {
                    failure(response, error);
                }
            }
        });
    }];
    
    [sessionTask resume];
    return sessionTask;
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        NSURLCredential *cre = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        // 调用block
        completionHandler(NSURLSessionAuthChallengeUseCredential,cre);
    }
    return;
}

+ (NSURLSessionDataTask *)request:(NSString *) url
                           method:(NSString *) method
                       parameters:(id)parameters
                          success:(void (^)(NSURLResponse *response, id data))success
                          failure:(void (^)(NSURLResponse *response, NSError* error))failure {
    if (parameters == nil || url.length == 0) {
        parameters = [NSMutableDictionary dictionaryWithCapacity:2];
    }
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSString *parUrl = [[NSString alloc] init];
    if ([parameters isKindOfClass:[NSDictionary class]]) {
        NSMutableString *mutString = [[NSMutableString alloc] init];
        [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            NSString *parKey = key;
            NSString *parValue = obj;
            [mutString appendFormat:@"%@=%@&",parKey,parValue];
        }];
        parUrl = [mutString substringToIndex:mutString.length-1];
    }
    
    
    NSData *bodyData = [parUrl dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSURL *requestUrl = [NSURL URLWithString:url];
    
    NSMutableURLRequest *mutRequest = [NSMutableURLRequest requestWithURL:requestUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:_postTimeout];
    mutRequest.HTTPBody = bodyData;
    mutRequest.HTTPMethod = @"POST";
    
    if ([method isKindOfClass:[NSString class]] && [[method lowercaseString] isEqualToString:@"get"]) {
        mutRequest.HTTPMethod = @"GET";
    }
    
    
    NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    NSURLSessionDataTask *sessionTask = [session dataTaskWithRequest:mutRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        ///请求完成后发送通知
        [EKPluginsTool netFinishToNotice:url method:mutRequest.HTTPMethod startTime:startTime response:response data:data error:error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (!error) {
                NSString *strRespone = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (success) {
                    success(response, strRespone);
                }
            } else {
                if (failure) {
                    failure(response, error);
                }
            }
        });
    }];
    
    [sessionTask resume];
    
    return sessionTask;
}

+ (NSURLSessionDownloadTask *)DOWN:(NSString *) url
                         localPath:(NSString *) path
                          progress:(void (^)(float progress)) progress
                           handler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))cHandler {
    
    RequestMission *downMission = [[RequestMission alloc] init];
    
    NSURLSessionDownloadTask *downTask = [downMission down:url localPath:path progress:^(float pro) {
        
        if (progress) {
            progress(pro);
        }
        
    } handle:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        // 下载结束通知
        [EKPluginsTool netDownFinishToNotice:url response:response error:error];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (cHandler) {
                cHandler(response, filePath, error);
            }
        });
    }];
    
    [downTask resume];
    return downTask;
}

@end


@implementation RequestMission

- (void)dealloc {
}

- (NSURLSessionDownloadTask *)down:(NSString *)url localPath:(NSString *)localPath progress:(BlockProgress)pro handle:(BlockHandler)handler {
    self.handlerB = [handler copy];
    self.progressB = [pro copy];
    self.localURL = [NSURL fileURLWithPath:localPath];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = _downTimeout;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    return [session downloadTaskWithURL:[NSURL URLWithString:url]];
}

#pragma mark -- NSURLSessionTaskDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if (self.handlerB) {
        NSURL *tmpURL = [self.localURL copy];
        self.handlerB(task.response, tmpURL, error);
    }
}

//上传进度
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    
}

#pragma mark -- NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    if (self.localURL != nil) {
        NSError *error;
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:self.localURL error:&error];
        
        if (error) {
        }
    } else {
        NSString *localStr = [[location absoluteString] stringByReplacingOccurrencesOfString:@".tmp" withString:@""];
        self.localURL = [[NSURL fileURLWithPath:localStr] URLByAppendingPathExtension:downloadTask.response.suggestedFilename.pathExtension];
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:self.localURL error:nil];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    if (self.progressB) {
        float progress = isnan(totalBytesExpectedToWrite) ? 0.0 :  (float)totalBytesWritten/totalBytesExpectedToWrite;
        self.progressB(progress);
    }
}

@end

#ifdef DEBUG

//添加跳过证书验证
@implementation NSURLRequest(DataController)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}

@end

#endif


