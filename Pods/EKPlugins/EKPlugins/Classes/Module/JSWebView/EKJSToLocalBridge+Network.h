//
//  EKJSToLocalBridge+Network.h
//  EKPlugins
//
//  Created by Skye on 2018/12/13.
//  Copyright © 2018年 ekwing. All rights reserved.
//
//网络请求相关的交互

#import "EKJSToLocalBridge.h"
#import <EKNetWork/EKNetWork.h>
@class EKProxyUtils;

@interface EKJSToLocalBridge (Network)

///网络请求
@property (nonatomic, strong, readonly) EKProxyUtils *httpReq;

@end
