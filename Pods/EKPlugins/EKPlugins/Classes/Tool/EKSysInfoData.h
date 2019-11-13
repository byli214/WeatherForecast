//
//  EKSysInfoData.h
//  SYDLMYParents
//
//  Created by 首磊 on 2017/3/23.
//  Copyright © 2017年 ekwing. All rights reserved.
//

@interface EKSysInfoData : NSObject

@property (nonatomic, strong) NSMutableDictionary *data;

- (instancetype) initWithReq:(NSString *)req ;

@end
