//
//  EKRequestProtocol.h
//  EK
//
//  Created by mac on 2018/11/28.
//  Copyright © 2018 EKing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKResultProtocol.h"
#import "EKInfoProtocol.h"

NS_ASSUME_NONNULL_BEGIN

//back block type
typedef void(^EKProgressBlock)(NSProgress *progress);

#pragma mark - 基础请求protocol
// 具体protocol
@protocol EKRequestProtocol <NSObject>

/**
 * 取消请求，内部直接调用NSURLSessionTask的cancel方法，
 * 如果是延迟还没调用，不会触发回调方法
 * 取消后，会调用相关的complete块和delegate
 */
- (void)cancel;
/**
 * 类似cancel功能，调用后不会触发complete和delegate回调
 */
- (void)silenceCancel;
@end



#pragma mark - 网络请求protocol
//
@protocol EKDataRequestProtocol <EKRequestProtocol>

/**
 * 请求方法
 * @param argument 请求参数，应该为@{String: String}类型
 * 结果返回需要EKDataRequestBackProtocol类型delegate
 */
- (void)startWithArgument:(nullable id)argument;

/**
 * 请求方法
 * @param request 外部自己定义NSURLRequest
 * 回调代理需要EKDataRequestBackProtocol类型delegate
 */
- (void)startWithRequest:(nonnull NSURLRequest *)request;

/**
 * 请求方法 内部持有 complete注意循环引用，使用weak
 * @param argument 请求参数, 应该为应该为@{String: String}类型
 * @param complete 结果返回block，如果对象指定delegate，则两个回调都会触发
 * 结果返回遵循EKDataResultProtocol协议对象
 */
- (void)startWithArgument:(nullable id)argument
                 complete:(void(^)(id<EKDataResultProtocol>result))complete;

/**
 * 请求方法 内部持有 complete注意循环引用，使用weak
 * @param request 外部自己定义NSURLRequest
 * @param complete 结果返回block，如果对象指定delegate，则两个回调都会触发
 * 结果返回遵循EKDataResultProtocol协议对象
 */
- (void)startWithRequest:(nonnull NSURLRequest *)request
                complete:(void(^)(id<EKDataResultProtocol>result))complete;

@end


#pragma mark - 资源上传请求protocol
// 资源上传请求ptotocol
@protocol EKUploadRequestProtocol <EKRequestProtocol>

/**
 * 请求方法
 * @param argument 请求参数
 * @param packData 上传的资源包装的对象
 * 包装对象需要遵循EKUploadFormDataProtocol协议，默认可用EKPackData
 * 进度和结果通过delegate回调获取
 */
- (void)startUploadWithArgument:(nullable id)argument
                       packData:(id<EKUploadFormDataProtocol>)packData;

/**
 * 请求方法
 * @param argument 请求参数
 * @param fromData NSData数据上传
 * 进度和结果通过delegate回调获取
 */
- (void)startUploadWithArgument:(nullable id)argument
                       fromData:(NSData *)fromData;

/**
 * 请求方法
 * @param argument 请求参数
 * @param fromURL 路径文件上传
 * 进度和结果通过delegate回调获取
 */
- (void)startUploadWithArgument:(nullable id)argument
                        fromURL:(NSURL *)fromURL;

/**
 * 请求方法 内部持有 complete注意循环引用，使用weak
 * @param argument 请求参数
 * @param packData 上传的资源包装的对象，遵循EKUploadFormDataProtocol协议，默认可用EKPackData
 * @param progressBlock 进度回调block
 * @param complete 结果返回block， 结果遵循EKUploadResultProtocol协议对象
 * 如果有delegate回调，也会触发
 */
- (void)startUploadWithArgument:(nullable id)argument
                       packData:(id<EKUploadFormDataProtocol>)packData
                       progress:(EKProgressBlock)progressBlock
                       complete:(void(^)(id<EKUploadResultProtocol>result))complete;

/**
 * 请求方法 内部持有 complete注意循环引用，使用weak
 * @param argument 请求参数
 * @param fromData NSData数据上传
 * @param progressBlock 进度回调block
 * @param complete 结果返回block， 结果遵循EKUploadResultProtocol协议对象
 * 如果有delegate回调，也会触发
 */
- (void)startUploadWithArgument:(nullable id)argument
                       formData:(NSData *)fromData
                       progress:(EKProgressBlock)progressBlock
                       complete:(void(^)(id<EKUploadResultProtocol>result))complete;

/**
 * 请求方法 内部持有 complete注意循环引用，使用weak
 * @param argument 请求参数
 * @param fromURL 路径文件上传
 * @param progressBlock 进度回调block
 * @param complete 结果返回block， 结果遵循EKUploadResultProtocol协议对象
 * 如果有delegate回调，也会触发
 */
- (void)startUploadWithArgument:(nullable id)argument
                        formURL:(NSURL *)fromURL
                       progress:(EKProgressBlock)progressBlock
                       complete:(void(^)(id<EKUploadResultProtocol>result))complete;

@end







#pragma mark - 资源下载请求protocol
// 资源上传请求ptotocol
@protocol EKDownloadRequestProtocol <EKRequestProtocol>

/// 开始下载方法，回调使用delegate
- (void)startDownload;

/**
 * 单文件下载 内部持有 block注意循环引用，使用weak
 * @param progressBlock 下载进度block
 * @param complete 下载完成block
 * 如果有delegate回调，也会触发
 */
- (void)startDownload:(EKProgressBlock)progressBlock
             complete:(void(^)(id<EKDownloadResultProtocol>result))complete;

/**
 * 多文件下载 内部持有 block注意循环引用，使用weak，当多资源下载的时候
 * @param progressBlock 下载进度block
 * @param complete 下载完成block
 * 如果有delegate回调，也会触发
 */
- (void)startMutDownload:(EKProgressBlock)progressBlock
                complete:(void(^)(NSArray<id<EKDownloadResultProtocol>>*result))complete;

@end





#pragma mark - 网络请求回调delegate
// 普通请求protocol
@protocol EKDataRequestBackProtocol <NSObject>

/**
 * 请求结果返回，
 * @param starter 开始请求对象, 遵循EKDataRequestProtocol
 * @param result 请求结果数据包装, 遵循EKDataResultProtocol
 */
- (void)netWorkDataRequest:(id<EKDataRequestProtocol>)starter
                    result:(id<EKDataResultProtocol>)result;
@end






#pragma mark - 文件上传请求回调delegate
// 文件上传protocol
@protocol EKUploadRequestBackProtocol <NSObject>

/**
 * 文件上传进度回调
 * @param starter 开始请求对象, 遵循EKUploadRequestProtocol
 * @param progress 上传进度返回NSProgress
 */
- (void)netWorkUploadRequest:(id<EKUploadRequestProtocol>)starter
                    progress:(NSProgress *)progress;

/**
 * 文件上传结果返回
 * @param starter 开始请求对象, 遵循EKUploadRequestProtocol
 * @param result 上传结束返回结果, 遵循EKUploadResultProtocol
 */
- (void)netWorkUploadRequest:(id<EKUploadRequestProtocol>)starter
                      result:(id<EKUploadResultProtocol>)result;
@end






#pragma mark - 文件下载请求回调delegate
// 文件上传protocol
@protocol EKDownloadRequestBackProtocol <NSObject>

/**
 * 单文件下载进度
 * @param starter 开始请求对象, 遵循EKDownloadRequestProtocol
 * @param progress 下载进度返回NSProgress
 */
- (void)netWorkDownloadRequest:(id<EKDownloadRequestProtocol>)starter
                      progress:(NSProgress *)progress;

/**
 * 多文件下载进度
 * @param starter 开始请求对象, 遵循EKDownloadRequestProtocol
 * @param progress 总资源下载进度返回NSProgress
 */
- (void)netWorkMutipleDownloadRequest:(id<EKDownloadRequestProtocol>)starter
                             progress:(NSProgress *)progress;


/**
 * 单文件下载结果回调
 * @param starter 开始请求对象, 遵循EKDownloadRequestProtocol
 * @param result 上传结束返回结果, 遵循EKDownResultProtocol
 */
- (void)netWorkDownloadRequest:(id<EKDownloadRequestProtocol>)starter
                        result:(id<EKDownloadResultProtocol>)result;


/**
 * 多文件下载结果回调
 * @param starter 开始请求对象, 遵循EKDownloadRequestProtocol
 * @param results 上传结束返回结果, 遵循EKDownResultProtocol
 */
- (void)netWorkMutipleDownloadRequest:(id<EKDownloadRequestProtocol>)starter
                              results:(NSArray<void(^)(id<EKDataResultProtocol>result)>*)results;

@end






#pragma mark - 数据统计请求回调delegate

@protocol EKNetWorkStatisticProtocol <NSObject>

/**
 * 请求返回后调用，此方法会在所有对象请求结束后都调用
 * @param info 请求参数, 遵循EKDataInfoProtocol
 * @param result 请求结果数据包装, 遵循EKDataResultProtocol
 */
- (void)netWorkDataStatisticFinished:(id<EKDataInfoProtocol>)info
                              result:(id<EKDataResultProtocol>)result;


/**
 * 下载结束后调用，此方法会在所有对象下载结束后都调用
 * @param info 请求请求参数, 遵循EKDownloadInfoProtocol
 * @param result 请求结果数据包装, 遵循EKDataResultProtocol
 */
- (void)netWorkDownloadStatisticFinished:(id<EKDownloadInfoProtocol>)info
                                  result:(id<EKDownloadResultProtocol>)result;

/**
 * 上传结束后调用，此方法会在所有对象上传结束后都调用
 * @param info 请求请求参数, 遵循EKUploadInfoProtocol
 * @param result 请求结果数据包装, 遵循EKDataResultProtocol
 */
- (void)netWorkUploadStatisticFinished:(id<EKUploadInfoProtocol>)info
                                result:(id<EKUploadResultProtocol>)result;

@end

NS_ASSUME_NONNULL_END
