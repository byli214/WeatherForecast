//
//  EKNetRequestInfoProtocol.h
//  EKNet
//
//  Created by mac on 2018/11/28.
//  Copyright © 2018 EKing. All rights reserved.
//

#import <Foundation/Foundation.h>

// 具体protocol
typedef NS_ENUM(NSUInteger, EKNetMethod){
    EKNetPost, EKNetGet, EKNetPut, EKNetDelete, EKNetPatch, EKNetHead
};

typedef NS_ENUM(NSUInteger, EKResponseSerializer){
    EKNetHttp, EKNetJson, EKNetXml
};


NS_ASSUME_NONNULL_BEGIN

@protocol EKInfoProtocol <NSObject>
@required
/// 请求地址
@property (nonatomic, strong) NSString *url;
@optional
/// 请求方法， 默认POST, 在upload中只能设置post/get
@property (nonatomic, assign) EKNetMethod method;
/// 请求超时, 默认20s
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
/// 结果返回，格式类型，默认JSON
@property (nonatomic, assign) EKResponseSerializer serializer;
/// 用户请求自定义数据
@property (nonatomic, strong) id userData;
@end

#pragma mark - 请求数据protocol

@protocol EKDataInfoProtocol <EKInfoProtocol>
@optional
/// 延迟请求, 默认0s
@property (nonatomic, assign) NSTimeInterval delayInterval;
/// 失败后重试次数 默认0次，间隔时间1s，最多20次
@property (nonatomic, assign) int retryCount;
/// 暂时不用，下个版本加入此功能
@property (nonatomic, assign) BOOL useCache;
@end

@protocol EKUploadInfoProtocol <EKInfoProtocol>
@end

@protocol EKDownloadInfoProtocol <EKInfoProtocol>
/// 是否用本地下载缓存，默认YES
@property (nonatomic, assign) BOOL useCache;
/// 当下载url中没有扩展名，是否通过http信息中拼上建议扩展名 ，默认YES
@property (nonatomic, assign) BOOL appendSuggestIfNoExtension;
@end

/// 文件上传使用，数据封装Data数据类协议
/// HTTP header `Content-Disposition: file; filename=#{filename}; name=#{name}"` and `Content-Type: #{mimeType}
@protocol EKUploadFormDataProtocol <NSObject>
/// 上传的原始数据
@property (nonatomic, strong) NSData *data;
/// 上传的本地磁盘文件路径
@property (nonatomic, strong) NSURL *fileURL;
/// Http Header中 对应fileURL/data的名字
@property (nonatomic, strong) NSString *name;
/// Http Header中的filename
@property (nonatomic, strong) NSString *fileName;
/// Http Header中的Content-Type
@property (nonatomic, strong) NSString *mimeType;
@end

NS_ASSUME_NONNULL_END
