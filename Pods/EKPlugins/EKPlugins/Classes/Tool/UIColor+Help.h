//
//  UIColor+Help.h
//  EKPlugins
//
//  Created by Skye on 2018/12/24.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (JSHex)

+ (UIColor *)js_colorWithHex:(NSString *)hexString;

@end
