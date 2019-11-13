//
//  EKResultProtocol.h
//  EKNetWork
//
//  Created by mac on 2018/11/28.
//  Copyright © 2018 EKing. All rights reserved.
// 

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 具体protocol
@protocol EKResultProtocol <NSObject>

/// 请求url
@property (nonatomic, strong) NSString *url;
/// 请求时长
@property (nonatomic, assign) NSTimeInterval duration;
/// 请求错误，系统u原始error，成功时为nil
@property (nonatomic, strong, nullable) NSError *error;
/// 请求参数，调试可使用, 没有参数为nil
@property (nonatomic, strong, nullable) id argument;
/// 请求参数，原始request
@property (nonatomic, strong) NSURLRequest *request;
/// 请求结果，返回response
@property (nonatomic, strong, nullable) NSURLResponse *response;
/// 请求结果，原始数据String
@property (nonatomic, strong, nullable) NSString *resonseString;
/// 请求结果，原始二进制数据
@property (nonatomic, strong, nullable) NSData *responseData;
/// 请求结果
@property (nonatomic, strong, nullable) id responseObject;
/// 用户自定义数据， 
@property (nonatomic, strong, nullable) id userData;
@end

/// 基础请求返回结果protocol
@protocol EKDataResultProtocol <EKResultProtocol>

/* 各应用大部分接口返回数据格式结构如下：
 *  { "status": 0, "data": {}/[] }
 *  { "status": 1, "data": {"intent/intend": errrorId, "errorlog/error_msg": "errorMsg" } }
 *  为了方便使用，根据以上接口格式，默认内部已经获取相关字段，如果在使用中，接口非此格式，
 *  则以下数据失效直接使用resonseString/responseObject ,自行解析
 */

/// 原始数据内部包含的数据，方便使用
/// 请求结果，包含的data数据，可能为dictionary 或array, 默认nil
@property (nonatomic, strong, nullable) id data;
/// data的json形式，可能nil
@property (nonatomic, strong, nullable) NSString *dataJson;
/// 请求结果，包含status值0/1，如果接口中没有status，默认-1
@property (nonatomic, assign) int status;
/// 请求失败，服务器返回的错误intent/intend，默认-1
@property (nonatomic, assign) int errorId;
/// 请求失败，服务器返回的错误提示信息error_msg/errorlog, 默认nil
@property (nonatomic, strong, nullable) NSString *errorMsg;

@end

/// 资源下载结果protocol
@protocol EKDownloadResultProtocol <EKResultProtocol>
// 磁盘缓存路径
@property (nonatomic, strong) NSString *cachePath;
@end

@protocol EKUploadResultProtocol <EKResultProtocol>
@end

#pragma mark - 状态和结果查询protocol
/*****************************************/
@protocol EKStateProtocol <EKResultProtocol>
/// 请求过程中原始的 NSURLSessionTask
@property (nonatomic, strong) NSURLSessionTask *task;

@end


NS_ASSUME_NONNULL_END
