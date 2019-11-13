//
//  EKJsonBuilder.h
//  EKStudent-iphone
//
//  Created by 首磊 on 16/7/27.
//  Copyright © 2016年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EKJsonBuilder : NSObject

+ (NSString *) toJsonString:(id)obj;
+ (NSString *) toJsonString:(id)obj inherit:(BOOL)parent;

@end
