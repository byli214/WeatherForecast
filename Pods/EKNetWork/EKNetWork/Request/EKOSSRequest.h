//
//  EKOSSRequest.h
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//  oss上传，由于上传参数格式不统一, 无法做统一内部处理，此类分成两个步骤进行
//  1、oss基本上传info信息请求，请求完成后block返回
//  2、外部获取到ossJson后如果需要处理，进行处理后传入上传方法，如果不需要处理则拿ossJson原始数据作为参数传入资源上传方法。


#import <Foundation/Foundation.h>
#import "EKResultProtocol.h"


NS_ASSUME_NONNULL_BEGIN

@class EKUploadRequest;
@class EKDataRequest;
@interface EKOSSRequest : NSObject

/**
 * oss信息请求
 * @param url 获取oss信息的地址
 * @param argument 请求参数，里面默认已经把AES随机码生成字段是SHK,外部需要可以传入但key必须是SHK
 * @param hookBlock 返回请求对象的block，外部可以设置EKDataRequest的属性, 控制请求参数
 * @param complete 结果返回block， ossReq当前对象，ossJson解密后的请求信息数据，result请求结果对象
 */
- (void)startRequestOSSInfo:(NSString *)url
                   argument:(NSDictionary<NSString*, NSString*> *)argument
                  hookBlock:(nullable void(^)(EKDataRequest*dataRequest))hookBlock
                   complete:(void(^)(EKOSSRequest* ossReq, NSString *ossJson, id<EKDataResultProtocol>result))complete;


/**
 * 阿里云上传资源
 * @param filePath 需要上传文件的磁盘路径
 * @param ossJson  把获取到的ossInfo信息外部处理成可json的字符串在传入
 * @param hookBlock 返回实际oss上传的url和请求对象的block，外部需要的话可以使用ossUrl并设置EKUploadRequest的属性
 * @param progressBlock 上传进度
 * @param complete 结果返回block，response请求返回信息， result请求返回结果，error错误信息
 */
- (void)startUploadWithPath:(NSString *)filePath
                    ossJson:(NSString *)ossJson
                  hookBlock:(nullable void(^)(NSString*lineUrl, EKUploadRequest*upRequest))hookBlock
                   progress:(nullable void(^)(NSProgress*progress))progressBlock
                   complete:(void(^)(id<EKUploadResultProtocol>result))complete;

/// 取消资源上传
- (void)cancelOSSUpload;

/// 取消oss信息请求
- (void)cancelOSSRequest;


@end

NS_ASSUME_NONNULL_END
