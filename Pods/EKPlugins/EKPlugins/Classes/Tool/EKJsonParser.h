//
//  EKJsonParser.h
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/14.
//  Copyright © 2017年 ekwing. All rights reserved.
//

@interface Status1Message : NSObject

@property (nonatomic, assign, readonly) int intent;
@property (nonatomic, copy, readonly) NSString *reason;

- (id)init:(int)intent reason:(NSString *)reason;

@end

@interface EKJsonParser : NSObject

// status 1返回Status1Message，否则返回正常NSDictionary。非json或者非EK格式json返回nil
+ (id)parse:(id)response;

@end
