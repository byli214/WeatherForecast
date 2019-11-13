//
//  EKMediaPlayerPool.m
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/20.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKMediaPlayerPool.h"
#import "NSDictionary+Help.h"
#import "EKJSWebViewHeader.h"
#import "EKX5DownloadUtils.h"
#import "NSString+Help.h"
#import "EKFileSizeGetter.h"
#import "EKJSToLocalBridge.h"

const static NSString *STATUS_PLAYING = @"playing";
const static NSString *STATUS_PAUSED = @"paused";
const static NSString *STATUS_ENDED = @"ended";
const static NSString *STATUS_ERROR = @"error";

@interface EKMediaPlayer()

@property (nonatomic, weak) AVPlayerItem *item;
@property (nonatomic, weak) EKMediaPlayerPool *pool;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) NSMutableDictionary *callbackData;
@property (nonatomic, assign) long durationMs;

@end

@implementation EKMediaPlayer

- (instancetype)init:(NSString *)url event:(NSString *)event offset:(int)offset needDetails:(BOOL)details isLoop:(BOOL)loop pool:(EKMediaPlayerPool *)pool; {
    self = [super init];
    if (self) {
        _url = url;
        _player = [[AVPlayer alloc] initWithURL:[url getUrl]];
        _jsCallBack = event;
        self.state = _IDLE;
        _needDetails = details;
        _loop = loop;
        _pool = pool;
        
        _item = NULL;
        _timeObserver = NULL;
        self.callbackData = [[NSMutableDictionary alloc] init];
        self.state = _PREPARING;
        [_callbackData setValue:url forKey:@"currentSrc"];
        _durationMs = -1;
        
        _offsetMs = offset == USE_CURRENT_PROGRESS ? 0 : offset;
        [self addItemObserver:_player.currentItem];
    }
    
    return self;
}

#pragma mark - Private method
- (void)addItemObserver:(AVPlayerItem *)item {
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [item addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:nil];
    _item = item;
    
    EKFileSizeGetter *getter = [[EKFileSizeGetter alloc] init];
    __weak EKMediaPlayer *player = self;
    [getter getUrlFileLength:_url withResultBlock:^(long long size, NSError *err) {
        if (!err && size == 0 && player.state <= _PREPARING) {
            [player removeItemObserver];
            [player doError];
        }
    }];
    
    //监控播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)removeItemObserver {
    [_item removeObserver:self forKeyPath:@"status"];
    _item = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)addProgressObserver {
    //监控时间进度
    if (_needDetails && !_timeObserver) {
        __weak typeof (self) weakSelf = self;
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 5) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            
            if (weakSelf.state <= _SEEK_END) {
                if (weakSelf.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                    weakSelf.state = _PLAYING;
                    [weakSelf updateProgress:weakSelf.jsCallBack];
                }
            }
            
            if (weakSelf.state >= _PLAYING) {
                [weakSelf updateProgress:weakSelf.jsCallBack];
            }
        }];
    }
}

- (void)removeProgressObserver {
    if (_timeObserver) {
        [self.player removeTimeObserver:_timeObserver];
        _timeObserver = nil;
    }
}

- (void)updateProgress:(NSString *)jsCallBack {
    if (_player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (_durationMs < 0) {
            NSArray *loadedRanges = _player.currentItem.seekableTimeRanges;

            if (loadedRanges.count > 0) {
                CMTimeRange range = [[loadedRanges objectAtIndex:0] CMTimeRangeValue];
                //获取音频总时长
                Float64 duration = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
                _durationMs = (long)(duration * 1000);
                NSNumber *obj = [NSNumber numberWithLong:_durationMs];
                [_callbackData setValue:obj forKey:@"duration"];
           } else {
                NSNumber *obj = [NSNumber numberWithInt:-1];
                [_callbackData setValue:obj forKey:@"duration"];
            }
        }
        
        Float64 position = CMTimeGetSeconds(_player.currentTime);
        long posInMs = (long)(position * 1000);
        if (posInMs < 0) {
            posInMs = 0;
        }
        
        if (_durationMs > 0 && posInMs > _durationMs) {
            posInMs = _durationMs;
        }
        
        NSNumber *obj = [NSNumber numberWithLong:posInMs];
        [_callbackData setValue:obj forKey:@"progress"];
    }
    
    if ([_callbackData js_hasValueForKey:@"duration"]) {
        [_pool callbackToJs:_jsCallBack data:[_callbackData JSONToString]];
    }
}

#pragma mark - Inner implement
- (void)doStart {
    [_player play];
    self.state = _PLAYING;
    [self addProgressObserver];
    [self updateProgress:_jsCallBack];
}

- (void)doPause:(NSString *)jsCallBack {
    if (_state == _PLAYING) {
        [_player pause];
    }
    
    self.state = _PAUSED;
    
    if (jsCallBack) {
        Float64 position = CMTimeGetSeconds(_player.currentTime);
        long posInMs = (long)(position * 1000);
        if (posInMs < 0) {
            posInMs = 0;
        }
    
        if (_durationMs > 0 && posInMs > _durationMs) {
            posInMs = _durationMs;
        }
    
        NSNumber *obj = [NSNumber numberWithLong:posInMs];
        [_callbackData setValue:obj forKey:@"progress"];
        [_pool callbackToJs:jsCallBack data:[_callbackData JSONToString]];
    }
    
    [self removeProgressObserver];
}

- (void)doEnd {
    if (_state == _PLAYING) {
        [_player pause];
        [_player seekToTime:CMTimeMake(0, 1)];
    }
    
    self.state = _PLAY_END;
    
    // remove observer befre js callback because ios 8.x is syncrous invoking
    [self removeProgressObserver];
    [self removeItemObserver];
    [self updateProgress:_jsCallBack];
}

- (void)doError {
    self.state = _SOURCE_ERR;
    [_pool callbackToJs:_jsCallBack data:[_callbackData JSONToString]];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (object != _player.currentItem) {
        NSLog(@"current item is not equal to player's item");
        return;
    }
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                if (_state <= _PREPARING) {
                    self.state = _PREPARED;
                }
                
                if (_state == _PREPARED) {
                    [self seekAndPlay];
                }
            }
                break;
            case AVPlayerItemStatusFailed:
            case AVPlayerItemStatusUnknown: {
                [self removeItemObserver];
                [self doError];
            }
                break;
            default:
                break;
        }
    } else {
        [self willChangeValueForKey:keyPath];
        [self didChangeValueForKey:keyPath];
    }
}

- (void)playbackFinished:(NSNotification *)notify {
    if (_loop) {
        __weak typeof (self) weakSelf = self;
        [_player seekToTime:CMTimeMake(0, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            if (finished) {
                if (weakSelf.state != _PAUSED) {
                    weakSelf.state = _SEEK_END;
                    [weakSelf doStart];
                }
            }
        }];
    } else {
        [self doEnd];
    }
}

- (void)audioRouteChangeListenerCallback:(NSNotification*)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            if (_state == _PLAYING) {
                [_player performSelector:@selector(play) withObject:nil afterDelay:0.1f]; //异步调用
            }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
        default:
            break;
    }
}

#pragma mark - Setter
- (void)setState:(PlayState)state {
    if (state == _PLAYING) {
        [_callbackData setValue:STATUS_PLAYING forKey:@"status"];
    } else if (state == _PAUSED) {
        [_callbackData setValue:STATUS_PAUSED forKey:@"status"];
    } else if (state == _PLAY_END) {
        [_callbackData setValue:STATUS_ENDED forKey:@"status"];
    } else if (state == _SOURCE_ERR) {
        [_callbackData setValue:STATUS_ERROR forKey:@"status"];
    }
    
    _state = state;
}

- (void)setUrl:(NSString *)newUrl {
    if (newUrl) {
        if ([_url isEqualToString:newUrl]) {
            if (self.state == _PLAY_END) {
                [self addItemObserver:_player.currentItem];
            }
            
            self.state = _PREPARED;
            [self seekAndPlay];
        } else {
            [self removeItemObserver];
            self.state = _PREPARING;
            _durationMs = -1;
            _url = newUrl;
            AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:[newUrl getUrl]];
            [self addItemObserver:item];
            [_player replaceCurrentItemWithPlayerItem:item];
            [_callbackData setValue:newUrl forKey:@"currentSrc"];
            [_callbackData removeObjectForKey:@"duration"];
        }
    }
}

- (void)seekAndPlay {
    if (self.state == _PAUSED)
        return;
    
    if (_durationMs < 0 || _offsetMs > _durationMs)
        _offsetMs = 0;
    
    if (_offsetMs > 0) {
        if (self.state != _PAUSED)
            self.state = _SEEKING;
        __weak typeof (self) weakSelf = self;
        [_player seekToTime:CMTimeMake(_offsetMs, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            if (finished) {
                if (weakSelf.state != _PAUSED) {
                    weakSelf.state = _SEEK_END;
                    [weakSelf doStart];
                }
           } else {
                weakSelf.state = _SOURCE_ERR;
                [weakSelf doError];
            }
        }];
    } else {
        if (self.state != _PAUSED)
            [self doStart];
    }
}

@end

@interface EKMediaPlayerPool()

@property (nonatomic, strong) NSMutableArray *players;
@property (nonatomic, weak) EKJSToLocalBridge *jsToLocalBridge;
@property (nonatomic, copy) void(^progressCallBackBlock)(NSString *event, NSString *callBack, NSString *callBackData);

@end

@implementation EKMediaPlayerPool

- (instancetype)init:(EKJSToLocalBridge *)jsToLocalBridge progressBlock:(void(^)(NSString *event, NSString *callBack, NSString *callBackData))progressBlock{
    self = [super init];
    if (self) {
        self.players = [[NSMutableArray alloc] init];
        self.jsToLocalBridge = jsToLocalBridge;
        self.progressCallBackBlock = progressBlock;
    }
    
    return self;
}

- (void)play:(NSString *)url offsetMs:(int)offset newPlayer:(BOOL)newPlayer callback:(NSString *)jsCallBack pauseOthers:(BOOL)pauseOthers needDetails:(BOOL)details isLoop:(BOOL)loop preferLocalFile:(BOOL)localFile {
    if (!url || url.length <= 0)
        return;
    
    if (pauseOthers)
        [self handlePauseOthers];
    
    NSString *filePath = [self checkAudioUrl:url];
    if (localFile) {
        NSString *uid = [[self.jsToLocalBridge getRequestParameters] js_stringValueForKey:@"uid"];
        NSString *local = [EKX5DownloadUtils getDownloadedFilePath:url uid:uid];
        if ([[NSFileManager defaultManager] fileExistsAtPath:local]) {
            filePath = local;
        }
    }
    
    if (newPlayer) {
        [self playWithNewPlayer:filePath event:jsCallBack offset:offset needDetails:details isLoop:loop];
    } else {
        [self playWithOldPlayer:filePath event:jsCallBack offset:offset needDetails:details isLoop:loop];
    }
}

- (BOOL)pause:(NSString *)url callback:(NSString *)jsCallBack {
    url = [self checkAudioUrl:url];
    BOOL ret = NO;
    NSString *uid = [[self.jsToLocalBridge getRequestParameters] js_stringValueForKey:@"uid"];
    NSString *local = [EKX5DownloadUtils getDownloadedFilePath:url uid:uid];
    @synchronized (self) {
        for (EKMediaPlayer *p in _players) {
            if ([url isEqualToString:p.url]) {
                [p doPause:jsCallBack];
                ret = YES;
            }
            if ([local isEqualToString:p.url]) {
                [p doPause:jsCallBack];
                ret = YES;
            }
        }
    }
    
    return ret;
}

- (long)getDuration:(NSString *)url {
    url = [self checkAudioUrl:url];
    @synchronized (self) {
        for (EKMediaPlayer *p in _players) {
            if ([url isEqualToString:p.url]) {
                return p.durationMs;
            }
        }
    }

    float duration = [EKMediaPlayerPool getFileDurationSeconds:url];
    if (duration > 0) {
        return duration*1000;
    }

    return 0;
}

- (BOOL)isPlaying:(NSString *)url {
    url = [self checkAudioUrl:url];
    @synchronized (self) {
        for (EKMediaPlayer *p in _players) {
            if ([url isEqualToString:p.url]) {
                return p.state == _PLAYING;
            }
        }
    }
    
    return NO;
}

- (void)stopAll {
    @synchronized (self) {
        for (EKMediaPlayer *player in _players) {
            if (player.state == _PLAYING && player.player) {
                [player.player pause];
            }
            
            if (player.player) {
                [player.player replaceCurrentItemWithPlayerItem:NULL];
            }
            
            [player removeProgressObserver];
            [player removeItemObserver];
        }
        
        [_players removeAllObjects];
    }
}

- (void)playWithNewPlayer:(NSString *)url event:(NSString *)jsCallBack offset:(int)offset needDetails:(BOOL)details isLoop:(BOOL)loop {
    EKMediaPlayer *player = [[EKMediaPlayer alloc] init:url event:jsCallBack offset:offset needDetails:details isLoop:loop pool:self];
    @synchronized (self) {
        [_players addObject:player];
    }
}

- (void)playWithOldPlayer:(NSString *)url event:(NSString *)jsCallBack offset:(int)offset needDetails:(BOOL)details isLoop:(BOOL)loop {
    EKMediaPlayer *player = NULL;
    @synchronized (self) {
        for (EKMediaPlayer *p in _players) {
            if ([url isEqualToString:[p url]] && [jsCallBack isEqualToString:[p jsCallBack]]) {
                player = p;
                break;
            }
        }
        
        if (!player) {
            if ([_players count] > 0) {
                player = [_players lastObject];
            }
        } else {
            [_players removeObject:player];
            [_players addObject:player]; // make it to the last
        }
    }
    
    if (!player) {
        [self playWithNewPlayer:url event:jsCallBack offset:offset needDetails:details isLoop:loop];
    } else {
        [player setJsCallBack:jsCallBack];
        [player setOffsetMs:offset];
        [player setNeedDetails:details];
        [player setLoop:loop];
        [player setUrl:url];
     }
}

- (void)handlePauseOthers {
    @synchronized (self) {
        for (EKMediaPlayer *p in _players) {
            if (p.state != _IDLE && p.state != _SOURCE_ERR && p.state != _PLAY_END) {
                [p doPause:NULL];
            }
        }
    }
}

- (void)handlePlayEnd {
    NSUInteger index = 0;
    @synchronized (self) {
        while ([_players count] > MAX_PLAYER_CT) {
            EKMediaPlayer *p = [_players objectAtIndex:index];
            if ([p state] == _PLAY_END) {
                [p.player replaceCurrentItemWithPlayerItem:NULL];
                [_players removeObject:p];
                p.url = NULL;
           } else {
                index++;
                if (index == [_players count])
                    break;
            }
        }
    }
}

- (NSString *)checkAudioUrl:(NSString *)url {
    // h5会将所有url加上mp3后缀带过来，这个在云知声上无法工作，必须去掉
    if ([url containsString:@"hivoice.cn"] && [url containsString:@".mp3"]) {
        url = [url stringByReplacingOccurrencesOfString:@".mp3" withString:@""];
    }
    // 放在我们云上的音频文件会自带wav后缀
    return [url stringByReplacingOccurrencesOfString:@".wav.mp3" withString:@".wav"];
}

#pragma mark - 清理
- (void)dealloc {
    [self stopAll];
    self.players = NULL;
}

- (void)callbackToJs:(NSString *)callBack data:(NSString *)data {
    if (self.progressCallBackBlock) {
        self.progressCallBackBlock(@"playAudio", callBack, data);
    }
}

#pragma mark - tool


+ (float)getFileDurationSeconds:(NSString *)sourcesURL
{
    
    if ([[NSURL URLWithString:sourcesURL] scheme] != nil && ([[[NSURL URLWithString:sourcesURL] scheme] caseInsensitiveCompare:@"http"] == NSOrderedSame || [[[NSURL URLWithString:sourcesURL] scheme] caseInsensitiveCompare:@"https"] == NSOrderedSame)) {
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:sourcesURL] options:nil];
        return CMTimeGetSeconds(asset.duration);
        
    }else if ([[NSURL fileURLWithPath:sourcesURL] scheme] != nil && [[[NSURL fileURLWithPath:sourcesURL] scheme] isEqualToString:@"file"]){
        
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:sourcesURL] options:nil];
        return CMTimeGetSeconds(asset.duration);
        
    }
    
    return 0;
}

@end
