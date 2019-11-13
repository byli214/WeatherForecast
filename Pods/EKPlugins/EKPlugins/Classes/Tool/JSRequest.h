//
//  SYRequest.h
//  EKStudent
//
//  Created by chen on 2017/8/3.
//  Copyright © 2017年 ekwing. All rights reserved.
//  JS交互中网络请求类

#import <Foundation/Foundation.h>

@interface JSRequest : NSObject

+ (NSURLSessionDataTask *)POST:(NSString *)url
                    parameters:(id)parameters
                       success:(void (^)(NSURLResponse *response, id data))success
                       failure:(void (^)(NSURLResponse *response, NSError* error))failure;

+ (NSURLSessionDataTask *)GET:(NSString *)url
                   parameters:(id)parameters
                      success:(void (^)(NSURLResponse *response, id data))success
                      failure:(void (^)(NSURLResponse *response, NSError* error))failure;

//下载方法
+ (NSURLSessionDownloadTask *)DOWN:(NSString *)url
                         localPath:(NSString *)path
                          progress:(void (^)(float progress)) progress
                           handler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))cHandler;

//返回的是JSON原始数据
+ (NSURLSessionDataTask *)request:(NSString *)url
                           method:(NSString *)method
                       parameters:(id)parameters
                          success:(void (^)(NSURLResponse *response, id data))success
                          failure:(void (^)(NSURLResponse *response, NSError* error))failure;

@end
