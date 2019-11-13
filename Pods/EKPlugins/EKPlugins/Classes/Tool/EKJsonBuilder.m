//
//  EKJsonBuilder.m
//  EKStudent-iphone
//
//  Created by 首磊 on 16/7/27.
//  Copyright © 2016年 ekwing. All rights reserved.
//

#import "EKJsonBuilder.h"
#import <objc/runtime.h>

@implementation EKJsonBuilder

+ (NSString *) toJsonString:(id)obj {
    return [self toJsonString:obj inherit:NO];
}

+ (NSString *) toJsonString:(id)obj inherit:(BOOL)parent {
    if ([obj isKindOfClass:[NSString class]])
        return (NSString *)obj;
    
    NSData *jsonData = [EKJsonBuilder getJSON:obj inherit:parent];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

#pragma mark private method
+ (NSData *) getJSON:(id)obj inherit:(BOOL)parent {
    id input = obj;
    NSDictionary *dic = [self getObjectData:obj inherit:parent];
    if ([dic count] > 0) {
        input = dic;
    }
    
    if ([NSJSONSerialization isValidJSONObject:input]) {
        return [NSJSONSerialization dataWithJSONObject:input options:NSJSONWritingPrettyPrinted error:nil];
    }
    
    return nil;
}

+ (NSDictionary *) getObjectData:(id)obj inherit:(BOOL)parent {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int propsCount;
    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);
    for (int i = 0; i < propsCount; ++i) {
        objc_property_t prop = props[i];
        
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
        id value = [obj valueForKey:propName];
        if (value == nil) {
            continue;
        } else {
            value = [self getObjectInternal:value];
        }
        [dic setObject:value forKey:propName];
    }
    
    if (parent) {
        objc_property_t *parentProps = class_copyPropertyList([obj superclass], &propsCount);
        for (int i = 0; i < propsCount; ++i) {
            objc_property_t prop = parentProps[i];
            
            NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
            id value = [obj valueForKey:propName];
            if (value == nil) {
                continue;
            } else {
                value = [self getObjectInternal:value];
            }
            [dic setObject:value forKey:propName];
        }
    }
    
    return dic;
}

+ (id) getObjectInternal:(id)obj {
    if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSArray *objarr = obj;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        for(int i = 0; i < objarr.count; i++) {
            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arr;
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *objdic = obj;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        for (NSString *key in objdic.allKeys) {
            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
        }
        return dic;
    }
    return [self getObjectData:obj inherit:NO];
}

@end
