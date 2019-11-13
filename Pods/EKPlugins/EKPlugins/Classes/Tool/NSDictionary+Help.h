//
//  NSDictionary+Help.h
//  EKPlugins
//
//  Created by chen on 2017/8/21.
//  Copyright © 2017年 ekwing. All rights reserved.
//
//后期考虑引入封装好的工具库

#import <UIKit/UIKit.h>

@interface NSDictionary (Help)

- (BOOL)js_hasValueForKey:(NSString *)key;

- (NSString *)js_stringValueForKey:(NSString *) key;

- (int)js_intValueForKey:(NSString *)key;

- (int)js_intValueForKey:(NSString *)key defaultValue:(int)value;

- (BOOL)js_boolValueForKey:(NSString *)key;

- (BOOL)js_boolValueForKey:(NSString *)key defaultValue:(BOOL)value;

- (float)js_floatValueForKey:(NSString *)key;

- (float)js_floatValueForKey:(NSString *)key defaultValue:(float)value;

@end

@interface NSDictionary (Json)

- (NSString *)JSONToString;

@end
