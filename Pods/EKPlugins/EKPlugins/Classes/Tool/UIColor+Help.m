//
//  UIColor+Help.m
//  EKPlugins
//
//  Created by Skye on 2018/12/24.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "UIColor+Help.h"

@implementation UIColor (JSHex)
+ (UIColor *)js_colorWithHex:(NSString *)hexString {
    return [self colorWithHex:hexString alpha:1.0];
}

+ (UIColor *)colorWithHex:(NSString *)hexString alpha:(CGFloat) alpha {
    NSString *cString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    //string should be 6 or 8 characters
    if ([cString length] < 6) {
        
        return [UIColor clearColor];
    }
    
    //strip OX if it appears
    if ([cString hasPrefix:@"0X"]) {
        
        cString = [cString substringFromIndex:2];
    }
    if ([cString hasPrefix:@"#"]) {
        
        cString = [cString substringFromIndex:1];
    }
    
    if ([cString length] != 6) {
        
        return [UIColor clearColor];
    }
    
    //separate into r, g, b substrings
    NSRange range;
    
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString  = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    //Scan values
    unsigned int r,g,b;
    
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}

@end
