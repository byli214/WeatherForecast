//
//  EKJSWebView+Help.m
//  EKPlugins
//
//  Created by Skye on 2018/5/17.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "EKJSWebView+Help.h"
#import <objc/runtime.h>

//参考链接： https://blog.csdn.net/longshihua/article/details/78001336
@implementation WKWebView (Keyboard)

static void (*originalIMP)(id self, SEL _cmd, void* arg0, BOOL arg1, BOOL arg2, id arg3) = NULL;

void interceptIMP (id self, SEL _cmd, void* arg0, BOOL arg1, BOOL arg2, id arg3) {
    originalIMP(self, _cmd, arg0, TRUE, arg2, arg3);
}

//该函数只能调用一次，否则会导致循环调用，程序崩溃
+ (void)wkWebViewShowKeybord{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"WKContentView");
        SEL originalSelector = NSSelectorFromString(@"_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:");
        Method originalMethod = class_getInstanceMethod(cls, originalSelector);
        IMP impOvverride = (IMP) interceptIMP;
        originalIMP = (void *)method_getImplementation(originalMethod);
        method_setImplementation(originalMethod, impOvverride);
    });
}

@end

@implementation EKJSWebView (Tool)

#pragma mark - public

//清理缓存
+ (void)clearWebViewCache{
#ifdef supportsWKWebKit
    //WKWebView在ios8系统上，JS进行post请求有问题，所以从9.0开始使用WKWebView
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0){
        //清理WKWebView 缓存
        [self clearWKWebViewCache];
    } else {
        //清理UIWebView 缓存
        [self clearUIWebViewCache];
    }
#else
    //清理UIWebView 缓存
    [self clearUIWebViewCache];
#endif
}

#pragma mark - private

//清理缓存
+ (void)clearUIWebViewCache{
    // Clear the webview cache...
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self removeApplicationLibraryDirectoryWithDirectory:@"Caches"];
    [self removeApplicationLibraryDirectoryWithDirectory:@"WebKit"];
    // Empty the cookie jar...
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    [self removeApplicationLibraryDirectoryWithDirectory:@"Cookies"];
}

+ (void)removeApplicationLibraryDirectoryWithDirectory:(NSString *)dirName {
    NSString *dir = [[[[NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSUserDomainMask, YES) lastObject]stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:dirName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];
    }
}


/*
 * WKWebsiteDataTypeDiskCache: 在磁盘缓存上
 * WKWebsiteDataTypeOfflineWebApplicationCache:  html离线Web应用程序缓存。
 * WKWebsiteDataTypeMemoryCache: 内存缓存
 * WKWebsiteDataTypeLocalStorage: 本地存储
 * WKWebsiteDataTypeCookies:  Cookies
 * WKWebsiteDataTypeSessionStorage: 会话存储
 * WKWebsiteDataTypeIndexedDBDatabases: IndexedDB数据库
 * WKWebsiteDataTypeWebSQLDatabases: 查询数据库
 */

+ (void)clearWKWebViewCache{
    NSSet *websiteDataTypes = [NSSet setWithArray:@[
                                                    WKWebsiteDataTypeDiskCache,
                                                    WKWebsiteDataTypeOfflineWebApplicationCache,
                                                    WKWebsiteDataTypeMemoryCache,
                                                    WKWebsiteDataTypeLocalStorage,
                                                    WKWebsiteDataTypeCookies,
                                                    WKWebsiteDataTypeSessionStorage,
                                                    WKWebsiteDataTypeIndexedDBDatabases,
                                                    WKWebsiteDataTypeWebSQLDatabases
                                                    ]];
    //    NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
    }];
}

@end
