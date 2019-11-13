//
//  EKMediaPlayerPool.h
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/20.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "IEKJSWebViewProtocol.h"
@class EKJSToLocalBridge;

typedef enum {
    _IDLE = 0,
    _SOURCE_SET,
    _PREPARING,
    _PREPARED,
    _SEEKING,
    _SEEK_END,
    _PLAYING,
    _PAUSED,
    _PLAY_END,
    _SOURCE_ERR
} PlayState;

@interface EKMediaPlayerPool : NSObject

- (instancetype)init:(EKJSToLocalBridge *)jsToLocalBridge progressBlock:(void(^)(NSString *event, NSString *callBack, NSString *callBackData))progressBlock;

- (void)play:(NSString *)url offsetMs:(int)offset newPlayer:(BOOL)newPlayer callback:(NSString *)jsCallBack pauseOthers:(BOOL)pauseOthers needDetails:(BOOL)details isLoop:(BOOL)loop preferLocalFile:(BOOL)localFile;
- (BOOL)pause:(NSString *)url callback:(NSString *)jsCallBack;
- (long)getDuration:(NSString *)url;
- (BOOL)isPlaying:(NSString *)url;
- (void)stopAll;
- (void)callbackToJs:(NSString *)event data:(NSString *)data;

@end

@interface EKMediaPlayer : NSObject

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *jsCallBack;
@property (nonatomic, assign) BOOL needDetails;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) PlayState state;
@property (nonatomic, assign) int offsetMs;

- (instancetype)init:(NSString *)url event:(NSString *)event offset:(int)offset needDetails:(BOOL)details isLoop:(BOOL)loop pool:(EKMediaPlayerPool *)pool;

@end
