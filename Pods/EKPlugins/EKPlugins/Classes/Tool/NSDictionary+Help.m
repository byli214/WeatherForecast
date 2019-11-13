//
//  NSDictionary+Help.m
//  EKPlugins
//
//  Created by chen on 2017/8/21.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import "NSDictionary+Help.h"

@implementation NSDictionary (Help)

- (BOOL) isDic {
    return [self isKindOfClass:[NSDictionary class]];
}

- (BOOL)js_hasValueForKey:(NSString *)key {
    if (key) {
        if ([self valueForKey:key]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)js_stringValueForKey:(NSString *) key {
    NSString *string = [NSString string];
    
    if (key) {
        id valueStr = [self valueForKey:key];
        if ([valueStr isKindOfClass:[NSString class]]) {
            string = (NSString *)valueStr;
        }
        
        if ([valueStr isKindOfClass:[NSNumber class]]) {
            string = [NSString stringWithFormat:@"%d",[valueStr intValue]];
        }
    }
    
    return string;
}

- (int)js_intValueForKey:(NSString *)key {
    return [self js_intValueForKey:key defaultValue:0];
}

- (int)js_intValueForKey:(NSString *)key defaultValue:(int)value {
    int intValue = value;
    
    if (key) {
        id object = [self valueForKey:key];
        if (object && [object respondsToSelector:@selector(intValue)]) {
            
            intValue = [object intValue];
        }
    }
    
    return intValue;
}

- (BOOL)js_boolValueForKey:(NSString *)key {
    BOOL boolValue = NO;

    if (key) {
        id object = [self valueForKey:key];
        if (object && [object respondsToSelector:@selector(boolValue)]) {
            boolValue = [object boolValue];
        }
    }
    
    return boolValue;
}

- (BOOL)js_boolValueForKey:(NSString *)key defaultValue:(BOOL)value {
    BOOL boolValue = value;
    
    if (key) {
        id object = [self valueForKey:key];
        if (object && [object respondsToSelector:@selector(boolValue)]) {
            boolValue = [object boolValue];
        }
    }
    
    return boolValue;
}

- (float)js_floatValueForKey:(NSString *)key {
    return [self js_floatValueForKey:key defaultValue:0];
}

- (float)js_floatValueForKey:(NSString *)key defaultValue:(float)value {
    float floatValue = value;
    
    if (key) {
        id object = [self valueForKey:key];
        if (object && [object respondsToSelector:@selector(floatValue)]) {
            
            floatValue = [object floatValue];
        }
    }
    
    return floatValue;
}

@end

@implementation NSDictionary (Json)

- (NSString *) JSONToString {
    NSString *jsonString = nil;
    
    if ([NSJSONSerialization isValidJSONObject:self]) {
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:self options:0 error:nil];
        jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}

@end
