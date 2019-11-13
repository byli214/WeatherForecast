//
//  NSArray+Help.m
//  EKPlugins
//
//  Created by Skye on 2018/12/24.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "NSArray+Help.h"

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

