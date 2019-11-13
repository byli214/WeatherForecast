//
//  EKH5CacheManager.h
//  EKStudent
//
//  Created by 首磊 on 2017/5/8.
//  Copyright © 2017年 ekwing. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface EKH5CacheManager : NSObject

+ (instancetype)sharedInstance;

- (void)setData:(NSString *)key value:(id)value;
- (void)setData:(NSString *)key value:(id)value replace:(BOOL)r saveToFile:(BOOL)persistent;
- (void)removeData:(NSString *)key;
- (void)clearAll;
- (NSString *)getData:(NSString *)key;

@end


