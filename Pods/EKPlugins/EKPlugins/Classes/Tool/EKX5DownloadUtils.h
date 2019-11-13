//
//  EKX5DownloadUtils.h
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/30.
//  Copyright © 2017年 ekwing. All rights reserved.
//

typedef void(^onProgress)(NSString *json);


@interface EKX5DownloadUtils : NSObject

- (instancetype)initWitUid:(NSString *)uid;
- (void)downloadBatch:(NSArray *)list progress:(onProgress)progress;
+ (NSString *)getDownloadedFilePath:(NSString *)url uid:(NSString *)uid;

@end
