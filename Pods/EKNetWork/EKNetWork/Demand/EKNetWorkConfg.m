//
//  EKNetWorkConfg.m
//  EKNetWork
//
//  Created by mac on 2018/11/27.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKNetWorkConfg.h"

@interface EKNetWorkConfg()
@property (nonatomic, strong) NSURLSessionConfiguration* configuration;
@property (nonatomic, strong) NSDictionary<NSString*, NSString*> *baseArgument;
@property (nonatomic, strong) NSString *dataCacheFolder;
@property (nonatomic, strong) NSString *downloadCacheFolder;
@property (nonatomic, assign) BOOL intToString;
@property (nonatomic, strong) NSArray<NSString *> *acceptTypes;
@property (nonatomic, weak) id<EKNetWorkStatisticProtocol> statisticsDelegate;

@end

@implementation EKNetWorkConfg

+ (EKNetWorkConfg *)shared
{
    static EKNetWorkConfg *onceObjc;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        onceObjc = [[self alloc] init];
    });
    
    return onceObjc;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _downloadCacheFolder = [self getDefaultMediaCacheFolder];
        _dataCacheFolder = [self getDefaultDataCacheFolder];
        _acceptTypes = @[@"application/json", @"text/json", @"text/javascript", @"text/html", @"application/xml"];
        _intToString = NO;
    }
    return self;
}

- (void)setSessionConfiguration:(NSURLSessionConfiguration *)configuraton
{
    _configuration = configuraton;
}

- (void)setBaseArgument:(NSDictionary<NSString *, NSString *> *)argument
{
    _baseArgument = argument;
}

- (void)setDataRequestCacheFolder:(NSString *)cacheFolder
{
    if (cacheFolder.length > 0 && cacheFolder.isAbsolutePath)
    {
        _dataCacheFolder = cacheFolder;
    }
}

- (void)setDownloadCacheFolder:(NSString *)cacheFolder
{
    if (cacheFolder.length > 0 && cacheFolder.isAbsolutePath)
    {
        _downloadCacheFolder = cacheFolder;
    }
}

- (void)setResultJsonFromIntToString:(BOOL)toString
{
    _intToString = toString;
}

- (void)setNetStatisticDelegate:(id<EKNetWorkStatisticProtocol>)delegate
{
    _statisticDelegate = delegate;
}

- (void)setAcceptableContentTypes:(NSArray<NSString *>*)acceptTypes
{
    _acceptTypes = acceptTypes;
}

#pragma mark -- tool


- (NSString *)getDefaultMediaCacheFolder
{
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    cachePath = [NSString stringWithFormat:@"%@/%@",cachePath,@"ekw/media"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return cachePath;
}

- (NSString *)getDefaultDataCacheFolder
{
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    cachePath = [NSString stringWithFormat:@"%@/%@",cachePath,@"ekw/content"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return cachePath;
}

@end
