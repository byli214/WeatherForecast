//
//  EKX5DownloadUtils.m
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/30.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKX5DownloadUtils.h"
#import "JSRequest.h"
#import "EKJsonBuilder.h"

@interface EKX5DowloadProgressData : NSObject

@property (nonatomic, assign) int loadingProgress;
@property (nonatomic, copy) NSArray *localAudioSrcArr;
@property (nonatomic, assign) BOOL loadingFailed;

- (void)reset;

@end

@implementation EKX5DowloadProgressData

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reset];
    }
    
    return self;
}

- (void)reset {
    _loadingProgress = 0;
    _localAudioSrcArr = nil;
    _loadingFailed = NO;
}

@end

@interface EKX5DownloadUtils()

@property (nonatomic, copy) NSArray *urlArray;
@property (nonatomic, strong) NSMutableArray *localPathArray;
@property (nonatomic, strong) EKX5DowloadProgressData *progressData;
@property (nonatomic, assign) NSUInteger total;
@property (nonatomic, assign) NSUInteger current;

@property (nonatomic, copy) NSString *dir;
@property (nonatomic, copy) onProgress handler;


@end

@implementation EKX5DownloadUtils

- (instancetype)initWitUid:(NSString *)uid {
    self = [super init];
    if (self) {
        self.localPathArray = [[NSMutableArray alloc] init];
        self.progressData = [[EKX5DowloadProgressData alloc] init];
        self.dir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingFormat:@"/tmp/Data_%@/soloAudio/", uid];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:_dir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    return self;
}

#pragma mark - Public method
- (void)downloadBatch:(NSArray *)list progress:(onProgress)progress {
    if (!list || list.count == 0) {
        _progressData.loadingProgress = 100;
        _progressData.localAudioSrcArr = @[];
        _progressData.loadingFailed = NO;
        progress([EKJsonBuilder toJsonString:_progressData]);
        return;
    }
    
    _current = 0;
    _total = list.count;
    _urlArray = list;
    self.handler = progress;
    [_progressData reset];
    [_localPathArray removeAllObjects];
    [self downloadAudio:[_urlArray objectAtIndex:_current]];
}

+ (NSString *)getDownloadedFilePath:(NSString *)url uid:(NSString *)uid {
    NSString *dir = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingFormat:@"/tmp/Data_%@/soloAudio/", uid];
    return [dir stringByAppendingString:[EKX5DownloadUtils convertUrlToFileName:url]];
}


#pragma mark - Private method
- (void)downloadAudio:(id)url {
    if (url && [url isKindOfClass:[NSString class]]) {
        NSString *file = [_dir stringByAppendingString:[EKX5DownloadUtils convertUrlToFileName:url]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
            [self successOneFile:file];
        } else {
            [JSRequest DOWN:url localPath:file progress:^(float progress) {
                
                [self reportProgress:progress];
            } handler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                
                if (!error) {
                    [self successOneFile:file];
                } else {
                    /*
                     NSURLErrorTimedOut(-1001)
                     NSURLErrorNotConnectedToInternet(-1009)
                     NSURLErrorBadServerResponse(-1011)
                     NSURLErrorCannotFindHost(-1003)
                     NSURLErrorCannotParseResponse(-1017)
                     NSURLErrorNetworkConnectionLost(-1005)
                     NSURLErrorCannotConnectToHost(-1004)
                     NSURLErrorCallIsActive(-1019)
                     NSURLErrorCannotDecodeContentData(-1016)
                     NSURLErrorHTTPTooManyRedirects(-1007)
                     NSURLErrorCancelled(-999)
                     NSURLErrorDataNotAllowed(-1020)
                     NSURLErrorFileDoesNotExist(-1100)*/
                    NSInteger errorCode = [error code];
                    if (NSURLErrorNotConnectedToInternet == errorCode || NSURLErrorCannotConnectToHost == errorCode || NSURLErrorCannotFindHost == errorCode) {
                        [self reportFailed];
                    }
                    else {
                        [self reportAfterSuccessOneFile:@"null"];
                    }
                }
            }];
        }
    }
}

- (void)successOneFile:(NSString *)localPath {
    ++_current;
    [self reportAfterSuccessOneFile:localPath];
    if (_current < _total) {
        [self downloadAudio:[_urlArray objectAtIndex:_current]];
    }
}

- (void)reportAfterSuccessOneFile:(NSString *)localPath {
    if (localPath) {
        [_localPathArray addObject:localPath];
        if (self.handler) {
            _progressData.loadingProgress = (int)(100 * _current / _total);
            if (_progressData.loadingProgress > 100)
                _progressData.loadingProgress = 100;
            if (_current == _total) {
                _progressData.localAudioSrcArr = _localPathArray;
            }
            
            _handler([EKJsonBuilder toJsonString:_progressData]);
        }
    }
}

- (void)reportProgress:(float)progress {
    if (self.handler) {
        progress = progress > 1 ? 1 : progress;
        progress = progress < 0 ? 0 : progress;
        int finalProgress = (int)(progress * 100) / _total;
        _progressData.loadingProgress = (int)(100 * _current / _total) + finalProgress;
        if (_progressData.loadingProgress > 100)
            _progressData.loadingProgress = 100;
        
        _progressData.localAudioSrcArr = nil;
        _handler([EKJsonBuilder toJsonString:_progressData]);
    }
}

- (void)reportFailed {
    if (self.handler) {
        _progressData.loadingFailed = true;
        if (_progressData.loadingProgress > 100)
            _progressData.loadingProgress = 100;
        
        _progressData.localAudioSrcArr = nil;
        _handler([EKJsonBuilder toJsonString:_progressData]);
    }
}

+ (NSString *)convertUrlToFileName:(NSString *)url {
    if (!url || url.length == 0)
        return @"";
    
    NSArray *splits = [url componentsSeparatedByString:@"/"];
    NSUInteger length = splits.count;
    if (length <= 1)
        return url;
    
    if ([url containsString:@"chivox.com"])
        return [splits objectAtIndex:length - 1];
    
    return [NSString stringWithFormat:@"%@_%@", [splits objectAtIndex:length - 2], [splits objectAtIndex:length - 1]];
}

@end
