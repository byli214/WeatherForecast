//
//  EKDownloadDemand.m
//  EKNetWork
//
//  Created by mac on 2019/1/4.
//  Copyright © 2019 ekwing. All rights reserved.
//

#import "EKDownloadDemand.h"
#import "EKNetWorkCentral.h"
#import "EKNetWorkConfg.h"
#import "EKNetWorkTool.h"

@interface EKDownloadDemand()
@property (nonatomic, strong) NSString *fileName;
@property (nonatomic, weak) id<EKDownloadInfoProtocol> info;

@end

@implementation EKDownloadDemand

- (void)dealloc
{
    
}


- (instancetype)initWithProInfo:(id<EKDownloadInfoProtocol>)info
{
    self = [super init];
    if (self) {
        
        self.info = info;
        self.cacheLenght = 0;
        self.receiveProgress = [[NSProgress alloc] init];

        NSFileManager *fileHander = [NSFileManager defaultManager];
        
        NSString *mediaFolder = [EKNetWorkConfg shared].downloadCacheFolder;
        if ([fileHander fileExistsAtPath:mediaFolder] == NO)
        {
            NSError *createFolderError;
            [fileHander createDirectoryAtPath:mediaFolder withIntermediateDirectories:YES attributes:nil error:&createFolderError];
            if (createFolderError != nil) {
   
            }
        }
        
        self.cacheFolder = mediaFolder;
        self.fileName = [EKNetWorkTool getMediaFileNameWithUrl:info.url];
        self.cachePath = [mediaFolder stringByAppendingPathComponent:self.fileName];
        
        //
        if ([fileHander fileExistsAtPath:self.cachePath])
        {
            self.cacheLenght = [EKNetWorkTool getContentFileLength:self.cachePath];
        } else {
            NSString *tmpPath = [EKNetWorkTool appendTempKeyWithMediaPath:self.cachePath];
            if ([fileHander fileExistsAtPath:tmpPath])
            {
                self.cacheLenght = [EKNetWorkTool getContentFileLength:tmpPath];
            }
        }
    }
    return self;
}

- (void)cancel
{
    [[EKNetWorkCentral shared] removeDownloadRequest:self];
}
- (void)startDownload
{
    [[EKNetWorkCentral shared] startDownloadRequest:self];
}


@end
