//
//  EKNetWorkTool.h
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//  工具库

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EKNetWorkTool : NSObject

/// 获得string的MD5加密串
+ (NSString *)getMD5WithString:(NSString *)string;
/// 根据url生成本地资源存储路径
+ (NSString *)getMediaFileNameWithUrl:(NSString *)url;
/// 获取filePath文件大小
+ (int64_t)getContentFileLength:(NSString *)filePath;
/// 删除filePath后面的__&&__拼接
+ (NSString *)deleteTempKeyWithMediaPath:(NSString *)filePath;
/// 在filePath后面，增加__&&__拼接生成临时路径
+ (NSString *)appendTempKeyWithMediaPath:(NSString *)filePath;
/// 是否支持字节断点下载
+ (BOOL)resonseEnableByRangeDownload:(NSURLResponse *)resonse;
/// 随机生成串，规则：过期时间+'s'+6位随机字符+1位数字+6位随机字符+1位字母(a-Z)+12位随机字符
+ (NSString *)generatingSHK:(int)expired;
/// 将oriJson内字典和数组中的int、float、double转成string
+ (NSString *)changeJsonIntToString:(NSString *)oriJson;
/// AES128解码
+ (NSString *)AES128Decrypt:(NSData *)encryptData key:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
