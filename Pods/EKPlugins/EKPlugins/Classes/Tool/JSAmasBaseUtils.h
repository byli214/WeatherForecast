//
//  BaseUtils.h
//  EKStudent
//
//  Created by 首磊 on 16/4/21.
//  Copyright © 2016年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <net/if_var.h>

@interface JSTrafficData : NSObject

@property uint32_t iBytes;
@property uint32_t oBytes;
@property struct IF_DATA_TIMEVAL time;

-(id)initWith: (uint32_t)input andEnd:(uint32_t)output andTime:(struct IF_DATA_TIMEVAL)time;

@end

@interface JSAmasBaseUtils : NSObject

+ (NSString *) getDeviceType;       // phone_type
+ (NSString *) getDeviceModel;      // device_type
+ (NSString *) getDeviceOS;         // os
+ (NSString *) getOSVersion;        // os_version
+ (NSString *) getDeviceBrand;      // phone_brand
+ (NSString *) getAppName;          // app
+ (NSString *) getAppVersion;       // app_version
+ (NSString *) getIMEI;             // device_id

+ (JSTrafficData *) checkNetworkflow; // calculate net_rx_device_rate & net_tx_device_rate here

+ (unsigned long long) getMemSize;                // mem_size
+ (float) getMemUsagePercent;       // mem_usage
+ (float) getCpuUsage;              // cpu_usage
+ (NSString *) getNetworkString;    // network_type

+ (NSString *) getUniqueString;

@end


