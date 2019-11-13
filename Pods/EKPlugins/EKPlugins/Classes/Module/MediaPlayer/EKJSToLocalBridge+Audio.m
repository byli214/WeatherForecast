//
//  EKJSToLocalBridge+Audio.m
//  EKPlugins
//
//  Created by Skye on 2018/12/12.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "EKJSToLocalBridge+Audio.h"
#import "EKMediaPlayerPool.h"
#import "EKX5DownloadUtils.h"
#import "NSDictionary+Help.h"
#import "JSAmasBaseUtils.h"
#import "IEKJSWebViewProtocol.h"
#import "EKJSWebView.h"
#import <objc/runtime.h>

static char EKJSToLocalBridge_Pool;

@implementation EKJSToLocalBridge (Audio)

@dynamic pool;

// MARK: - 音频相关
    
- (void)setPool:(EKMediaPlayerPool *)pool {
    objc_setAssociatedObject(self, &EKJSToLocalBridge_Pool, pool, OBJC_ASSOCIATION_RETAIN);
}

-(EKMediaPlayerPool *)pool {
    return objc_getAssociatedObject(self, &EKJSToLocalBridge_Pool);
}
    
- (void)stopMediaPlayerPool {
    if (nil != self.pool) {
        [self.pool stopAll];
    }
}

//音频播放
- (BOOL)jsWebView:(EKJSWebView *)jsWebView playAudioActionWithJsonDic:(NSDictionary *)jsonDic {
    NSString *callBack = [jsonDic js_stringValueForKey:@"callBack"];
    NSString *run = [jsonDic js_stringValueForKey:@"run"];
    NSString *src = [jsonDic js_stringValueForKey:@"src"];
    int seekTime = [jsonDic js_intValueForKey:@"seekTime" defaultValue:-1];
    BOOL details = [jsonDic js_boolValueForKey:@"needDetails"];
    BOOL newPlayer = [jsonDic js_boolValueForKey:@"newPlayer" defaultValue:YES];
    BOOL pauseOthers = [jsonDic js_boolValueForKey:@"pauseOthers" defaultValue:YES];
    BOOL loop = [jsonDic js_boolValueForKey:@"loop" defaultValue:NO];
    BOOL useLocal = [jsonDic js_boolValueForKey:@"playLocalFile" defaultValue:NO];
    
    if (!self.pool) {
        self.pool = [[EKMediaPlayerPool alloc] init:self progressBlock:^(NSString *event, NSString *callBack, NSString *callBackData) {
            [self toJSWithEvent:event data:nil callBack:callBack callBackData:callBackData];
        }];
    }
    
    if ([run isEqualToString:@"play"]) {
        [self.pool play:src offsetMs:seekTime newPlayer:newPlayer callback:callBack pauseOthers:pauseOthers needDetails:details isLoop:loop preferLocalFile:useLocal];
    } else {
        [self.pool pause:src callback:callBack];
    }
    
    return true;
}

//播放状态
- (BOOL)jsWebView:(EKJSWebView *)jsWebView playStatusActionWithJsonDic:(NSDictionary *)jsonDic {
    NSString *callBack = [jsonDic js_stringValueForKey:@"callBack"];
    NSString *src = [jsonDic js_stringValueForKey:@"src"];
    
    NSMutableDictionary *output = [[NSMutableDictionary alloc] init];
    [output setValue:src forKey:@"src"];
    [output setValue:[NSNumber numberWithBool:[self.pool isPlaying:src]] forKey:@"isPlaying"];
    [output setValue:[NSNumber numberWithLong:[self.pool getDuration:src]] forKey:@"duration"];
    
    [self toJSWithEvent:@"playStatus" data:jsonDic callBack:callBack callBackData:output];
    
    return true;
}

//预加载音频
- (BOOL)jsWebView:(EKJSWebView *)jsWebView fetchLocalAudioSrcActionWithJsonDic:(NSDictionary *)jsonDic {
    NSArray *list = [jsonDic objectForKey:@"oriAudioSrcArr"];
    NSString *callBack = [jsonDic js_stringValueForKey:@"callBack"];

    BOOL requestHandle = NO;
    NSString *uid = [[self getRequestParameters] js_stringValueForKey:@"uid"];
    EKX5DownloadUtils *utils = [[EKX5DownloadUtils alloc] initWitUid:uid];
    if (list) {
        NSMutableArray *listM = [NSMutableArray array];
        BOOL need4GDecide = NO;
        for (NSString *urlStr in list) {
            if (![[NSFileManager defaultManager] fileExistsAtPath:[EKX5DownloadUtils getDownloadedFilePath:urlStr uid:uid]]) {
                [listM addObject:urlStr];
                if (!need4GDecide && ![urlStr containsString:@"zippedaudio"]) {
                    need4GDecide = YES;
                }
            }
        }
        
        NSString *netWorkType = [JSAmasBaseUtils getNetworkString];
        if ([netWorkType isEqualToString:@"2G"] || [netWorkType isEqualToString:@"3G"] || [netWorkType isEqualToString:@"4G"]) {
            if (need4GDecide && listM.count) {
                requestHandle = YES;
                UIWindow *window = [UIApplication sharedApplication].delegate.window;
                if (!window) {
                    window = [UIApplication sharedApplication].keyWindow;
                }
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"正在使用数据流量, 是否继续下载?" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *cancelConform = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
                UIAlertAction *actionConform = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    [utils downloadBatch:listM progress:^(NSString *json) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self toJSWithEvent:@"fetchLocalAudioSrc" data:jsonDic callBack:callBack callBackData:json];
                        });
                    }];
                }];
                [alertController addAction:cancelConform];
                [alertController addAction:actionConform];
                [window.rootViewController presentViewController:alertController animated:YES completion:nil];
            }
        }
    }
    
    if (!requestHandle) {
        [utils downloadBatch:list progress:^(NSString *json) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self toJSWithEvent:@"fetchLocalAudioSrc" data:jsonDic callBack:callBack callBackData:json];
            });
        }];
    }
    
    return true;
}

@end
