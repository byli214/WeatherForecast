//
//  EKNetWorkConfg.h
//  EKNetWork
//
//  Created by mac on 2018/11/27.
//  Copyright © 2018 EKing. All rights reserved.
//  请求全局配置文件

#import <Foundation/Foundation.h>
#import "EKRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface EKNetWorkConfg : NSObject

/// NSURLSession配置
@property (nonatomic, strong, readonly) NSURLSessionConfiguration* configuration;
/// 基础参数
@property (nonatomic, strong, readonly) NSDictionary<NSString*, NSString*> *baseArgument;
/// 基础请求，缓存文件夹路径 暂时disable
@property (nonatomic, strong, readonly) NSString *dataCacheFolder;
/// 资源下载缓存文件夹路径
@property (nonatomic, strong, readonly) NSString *downloadCacheFolder;
/// json中的基本数据类型转成string，是否自动转换，默认是NO
@property (nonatomic, assign, readonly) BOOL intToString;
/// 数据统计delegate
@property (nonatomic, weak, readonly) id<EKNetWorkStatisticProtocol> statisticDelegate;
/// 设置HTTP acceptableContentTypes类型
@property (nonatomic, strong, readonly) NSArray<NSString *> *acceptTypes;


+ (EKNetWorkConfg *)shared;

/**
 * 设置基础参数数据
 * @param argument 基础参数
 */
- (void)setBaseArgument:(NSDictionary<NSString*, NSString*> *)argument;

/**
 * NSURLSession配置信息
 * @param configuraton 配置信息
 */
- (void)setSessionConfiguration:(NSURLSessionConfiguration *)configuraton;

/**
 * 设置基础请求缓存路径文件夹
 * @param cacheFolder 基础参数 暂不可用
 */
- (void)setDataRequestCacheFolder:(NSString *)cacheFolder;

/**
 * 设置资源下载文件夹路径
 * @param cacheFolder 基础参数
 */
- (void)setDownloadCacheFolder:(NSString *)cacheFolder;


/**
 * 数据请求中，是否将Int，Float，Double转成String
 * @param toString 是否转换
 */
- (void)setResultJsonFromIntToString:(BOOL)toString;

/**
 * 添加数据统计代理
 * @param delegate delegate
 */
- (void)setNetStatisticDelegate:(id<EKNetWorkStatisticProtocol>)delegate;

/*
 * 设置解析类型
 * @param acceptTypes 数据解析类型
 * 默认 @[@"application/json", @"text/json", @"text/javascript", @"text/html", @"application/xml"];
 */
- (void)setAcceptableContentTypes:(NSArray<NSString *>*)acceptTypes;

@end

NS_ASSUME_NONNULL_END
