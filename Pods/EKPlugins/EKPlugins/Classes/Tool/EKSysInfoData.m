//
//  EKSysInfoData.m
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/23.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKSysInfoData.h"
#import "JSAmasBaseUtils.h"
#import <AVFoundation/AVFoundation.h>

@implementation EKSysInfoData

- (instancetype) initWithReq:(NSString *)req {
    self = [super init];
    
    if (self) {
        self.data = [[NSMutableDictionary alloc] init];
        [self fillData:req];
    }
    
    return self;
}

- (void)fillData:(NSString *)req {
    [_data setValue:[JSAmasBaseUtils getOSVersion] forKey:@"osVersion"];
    [_data setValue:[JSAmasBaseUtils getNetworkString] forKey:@"network"];
    [_data setValue:[JSAmasBaseUtils getDeviceModel] forKey:@"device"];
    
    if (req) {
        NSArray *option = [req componentsSeparatedByString:@" "];
        NSUInteger optionLen = option.count;
        for (int i = 0; i < optionLen; ++i) {
            NSString *r = [option objectAtIndex:i];
            if ([r isEqualToString:@"IMEI"]) {
                [_data setValue:[JSAmasBaseUtils getIMEI] forKey:@"IMEI"];
            } else if ([r isEqualToString:@"ram"]) {
                [_data setValue:[NSString stringWithFormat:@"%llu MB", [JSAmasBaseUtils getMemSize] / 1024 / 1024] forKey:@"ram"];
            } else if ([r isEqualToString:@"volume"]) {
                int value = (int)([[AVAudioSession sharedInstance] outputVolume] * 100);
                [_data setValue:[NSNumber numberWithInt:value] forKey:@"volume"];
            }
        }
    }
}

@end
