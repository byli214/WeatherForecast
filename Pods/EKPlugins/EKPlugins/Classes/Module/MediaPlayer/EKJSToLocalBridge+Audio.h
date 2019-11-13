//
//  EKJSToLocalBridge+Audio.h
//  EKPlugins
//
//  Created by Skye on 2018/12/12.
//  Copyright © 2018年 ekwing. All rights reserved.
//
//与音频相关的交互

#import "EKJSToLocalBridge.h"
@class EKMediaPlayerPool;

@interface EKJSToLocalBridge (Audio)

/// 音频播放
@property (nonatomic, strong, readonly) EKMediaPlayerPool *pool;
    
/**
 * 停止音频播放
 */
- (void)stopMediaPlayerPool;
    
@end
