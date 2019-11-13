//
//  EKNetDemand.h
//  EKNetWork
//
//  Created by mac on 2018/11/23.
//  Copyright © 2018 EKing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKInfoProtocol.h"
#import "EKResultProtocol.h"
#import "EKRequestProtocol.h"

NS_ASSUME_NONNULL_BEGIN

// data
@interface EKNetDemand : NSObject

@property (nonatomic, strong) NSURLRequest *oriRequest;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) id responseObject;
@property (nonatomic, strong) NSData *responseData;
@property (nonatomic, strong) NSString *responseString;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, weak) NSURLSessionTask *task;
@property (nonatomic, strong) id argument;

@end

NS_ASSUME_NONNULL_END
