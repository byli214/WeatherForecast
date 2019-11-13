//
//  IEKJSWebViewDelegate.h
//  EKPlugins
//
//  Created by Skye on 2019/1/7.
//  Copyright © 2019年 ekwing. All rights reserved.
//
//webView的代理需要实现的方法

#import <Foundation/Foundation.h>

#pragma mark - webView基础回调protocol

@class EKJSWebView;

/*
 WebView基础回调 代理需要传递jsWebView 当页面内多个webView 可区分是哪一个webView
 */
@protocol IEKJSWebViewDelegate<NSObject>

@optional;

/*
 webView开始加载调用
 */
- (void)jsWebView:(EKJSWebView * _Nonnull)jsWebView onPageStartedWithUrl:(NSString * _Nullable)url;


/*
 webView加载完成调用
 */
- (void)jsWebView:(EKJSWebView * _Nonnull)jsWebView onPageFinishedWithUrl:(NSString * _Nullable)url;

/*
 webView加载失败调用
 */
- (void)jsWebView:(EKJSWebView * _Nonnull)jsWebView onReceivedErrorWithErrorCode:(int)errorCode des:(NSString * _Nullable)description url:(NSString * _Nullable) failingUrl;

/*
 webView加载进度调用
 */
- (void)jsWebView:(EKJSWebView * _Nonnull)jsWebView onProgressChangedWithProgress:(int)progressInPercent;

@end

#pragma mark - 需要代替webView实现 JS交互的代理方法

@protocol IEKWebViewJS2LocalDelegate<NSObject>

@required
/*
 如果对于特殊event事件需要各自vc处理的，子类拦截处理event并返回YES，如果子类没有处理的事件返回NO
 event：事件传递关键字
 json：事件传递参数
 */
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView customizedLocalEvent:(NSString * _Nonnull)event data:(id _Nullable)json;

@optional

//处理各个事件的方法

#pragma mark - 数据缓存相关

//添加缓存数据
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView setLocalCacheActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//获取缓存数据
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView getLocalCacheActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//清理缓存数据
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView clearLocalCacheActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

#pragma mark - 音频播放

//音频播放
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView playAudioActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//播放状态
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView playStatusActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//预加载音频
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView fetchLocalAudioSrcActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

#pragma mark - 系统调用

//获取系统的相关信息
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView getSysInfoActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//调起通讯录
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView addressBookActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

#pragma mark - 网络请求

// 网络请求proxy
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView proxyActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//网络请求 newProxy
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView netProxyActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

#pragma mark - 其他需要navi等

//移除历史
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView removeHistoryActionWithJson:(NSString *)json;

//改变openView中的data的数据
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView changeOpenViewDataActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//打开新的页面
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView openViewActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//改变导航栏的颜色
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView setNaviBarActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//返回上一页面
- (BOOL)jsWebView:(EKJSWebView * _Nonnull)jsWebView goBackActionWithJsonDic:(NSDictionary * _Nullable)jsonDic;

@end
