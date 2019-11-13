//
//  BaseUtils.m
//  EKStudent
//
//  Created by 首磊 on 16/4/21.
//  Copyright © 2016年 ekwing. All rights reserved.
//

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <mach/mach.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "JSAmasBaseUtils.h"

@implementation JSTrafficData

- (id)initWith: (uint32_t)input andEnd:(uint32_t)output andTime:(struct IF_DATA_TIMEVAL)time {
    self = [super init];
    
    if (self) {
        _iBytes = input;
        _oBytes = output;
        _time = time;
    }
    
    return self;
}

@end


@implementation JSAmasBaseUtils

// phone_type
+ (NSString *) getDeviceType {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

// device_type
+ (NSString *) getDeviceModel {
    return [UIDevice currentDevice].model;
}

// os
+ (NSString *) getDeviceOS {
    return [[UIDevice currentDevice] systemName];
}

// os_version
+ (NSString *) getOSVersion {
    return [UIDevice currentDevice].systemVersion;
}

// phone_brand
+ (NSString *) getDeviceBrand {
    return @"Apple";
}

// app
+ (NSString *) getAppName {
    NSDictionary* bundleInfo = [[NSBundle mainBundle] infoDictionary];
    return [bundleInfo objectForKey:@"CFBundleName"];
}

// app_version
+ (NSString *) getAppVersion {
    NSDictionary* bundleInfo = [[NSBundle mainBundle] infoDictionary];
    return [bundleInfo objectForKey:@"CFBundleShortVersionString"];
}

 // device_id
+ (NSString *) getIMEI {
    return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

+ (JSTrafficData *) checkNetworkflow {
    struct IF_DATA_TIMEVAL time = {0, 0};
    JSTrafficData *ret = [[JSTrafficData alloc] initWith:0 andEnd:0 andTime:time];
    struct ifaddrs *ifa_list = 0, *ifa;
    if (getifaddrs(&ifa_list) == -1) {
        return ret;
    }
    
    uint32_t inBytes = 0;
    uint32_t outBytes = 0;
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;
        
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            continue;
        
        if (ifa->ifa_data == 0)
            continue;
        
        // network flow
        if (strncmp(ifa->ifa_name, "lo", 2)) {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            inBytes += if_data->ifi_ibytes;
            outBytes += if_data->ifi_obytes;
            ret.time = if_data->ifi_lastchange;
        }
    }
    
    freeifaddrs(ifa_list);
    ret.iBytes = inBytes;
    ret.oBytes = outBytes;
    return ret;
}

// mem_size
+ (unsigned long long) getMemSize {
    return [NSProcessInfo processInfo].physicalMemory;
}

// mem_usage
+ (float) getMemUsagePercent {
    vm_statistics_data_t vmStats;
    if ([JSAmasBaseUtils memoryInfo:&vmStats]) {
        float total = (float)vmStats.free_count + vmStats.active_count + vmStats.inactive_count + vmStats.wire_count;
        return (vmStats.free_count + vmStats.inactive_count) / total;
    }
    
    return 1;
}

// cpu_usage
+ (float) getCpuUsage {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;

    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;

    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;

    for (j = 0; j < thread_count; j++) {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }

        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }

    } // for each thread

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);

    return tot_cpu;
}

// network_type
+ (NSString *) getNetworkString {
    NSString *strNetworkType = @"Unknown network";

    //创建零地址，0.0.0.0的地址表示查询本机的网络连接状态
    struct sockaddr_storage zeroAddress;

    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.ss_len = sizeof(zeroAddress);
    zeroAddress.ss_family = AF_INET;

    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;

    //获得连接的标志
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);

    //如果不能获取连接标志，则不能连接网络，直接返回
    if (!didRetrieveFlags) {
        return strNetworkType;
    }

    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        // if target host is reachable and no connection is required
        // then we'll assume (for now) that your on Wi-Fi
        strNetworkType = @"WIFI";
    }

    if (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
            (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0) {
        // ... and the connection is on-demand (or on-traffic) if the
        // calling application is using the CFSocketStream or higher APIs
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            // ... and no [user] intervention is needed
            strNetworkType = @"WIFI";
        }
    }

    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
            NSString *currentRadioAccessTechnology = info.currentRadioAccessTechnology;
                
            if (currentRadioAccessTechnology) {
                if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
                    strNetworkType = @"4G";
                } else if ([currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge] ||[currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS]) {
                    strNetworkType = @"2G";
                } else {
                    strNetworkType = @"3G";
                }
            }
        } else {
            if((flags & kSCNetworkReachabilityFlagsReachable) == kSCNetworkReachabilityFlagsReachable) {
                if ((flags & kSCNetworkReachabilityFlagsTransientConnection) == kSCNetworkReachabilityFlagsTransientConnection) {
                    if((flags & kSCNetworkReachabilityFlagsConnectionRequired) == kSCNetworkReachabilityFlagsConnectionRequired) {
                        strNetworkType = @"2G";
                    } else {
                        strNetworkType = @"3G";
                    }
                }
            }
        }
    }


    if ([strNetworkType isEqualToString:@"Unknown network"]) {
        strNetworkType = @"WWAN";
    }

    return strNetworkType;
}

+ (NSString *) getUniqueString {
    NSString *before = [[JSAmasBaseUtils getIMEI] stringByAppendingString: @"EKSTU"];
    return [JSAmasBaseUtils md5Encode32Bit:before];
}

#pragma mark private method
+ (BOOL) memoryInfo: (vm_statistics_data_t *)vmStats {
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)vmStats, &infoCount);
    
    return kernReturn == KERN_SUCCESS;
}

+ (NSString *) md5Encode32Bit: (NSString *) inPutText {
    const char *cStr = [inPutText UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)inPutText.length, digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [result appendFormat:@"%02x", digest[i]];
    
    return result;
}

@end
