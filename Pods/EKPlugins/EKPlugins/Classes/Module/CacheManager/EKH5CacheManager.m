//
//  EKH5CacheManager.m
//  EKStudent
//
//  Created by 首磊 on 2017/5/8.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKH5CacheManager.h"
#import "NSDictionary+Help.h"
#import "EKJsonBuilder.h"

NSString * const CACHE_FILE = @"webViewCache.dat";

@interface EKH5CacheManager()

@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSMutableDictionary *datas;
@property (nonatomic, strong) NSMutableDictionary *datasToFile;

@end

@implementation EKH5CacheManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static EKH5CacheManager *staticOnce;
    dispatch_once(&onceToken, ^{
        staticOnce = [[EKH5CacheManager alloc] init];
    });
    return staticOnce;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        self.path = [[paths objectAtIndex:0] stringByAppendingPathComponent:CACHE_FILE];
        NSDictionary *datas = [self readFromFile];
        if (datas && datas.count > 0) {
            self.datas = [[NSMutableDictionary alloc] initWithDictionary:datas];
            self.datasToFile = [[NSMutableDictionary alloc] initWithDictionary:datas];
        } else {
            self.datas = [[NSMutableDictionary alloc] init];
            self.datasToFile = [[NSMutableDictionary alloc] init];
        }
    }
    
    return self;
}

- (void)setData:(NSString *)key value:(id )value {
    [self setData:key value:value replace:YES saveToFile:NO];
}

- (void)setData:(NSString *)key value:(id)value replace:(BOOL)r saveToFile:(BOOL)persistent {
    if (!key) return;
    
    NSString *valueStr = nil;
    if ([value isKindOfClass:[NSString class]]) {
        valueStr = (NSString *)value;
    } else {
        valueStr = [EKJsonBuilder toJsonString:value];
    }
    
    if (valueStr == nil) {
        valueStr = @"";
    }
    
    if (r || ![_datas objectForKey:key]) {
        [_datas setObject:valueStr forKey:key];
        if (persistent) {
            [_datasToFile setObject:valueStr forKey:key];
            [self saveToFile];
        }
    }
}

- (void)removeData:(NSString *)key {
    if (!key)
        return;
    
    if ([_datas objectForKey:key]) {
        [_datas removeObjectForKey:key];
    }
    
    if ([_datasToFile objectForKey:key]) {
        [_datasToFile removeObjectForKey:key];
        [self saveToFile];
    }
}

- (void)clearAll {
    [_datas removeAllObjects];
    [_datasToFile removeAllObjects];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:_path]) {
        [fileMgr removeItemAtPath:_path error:nil];
    }
}

- (NSString *)getData:(NSString *)key {
    if (!key)
        return @"";
    
    NSString *v = [_datas js_stringValueForKey:key];
    return v ? v : @"";
}

- (void)saveToFile {
    [_datasToFile writeToFile:_path atomically:YES];
}

- (NSDictionary *)readFromFile {
    return [NSDictionary dictionaryWithContentsOfFile:_path];
}

@end
