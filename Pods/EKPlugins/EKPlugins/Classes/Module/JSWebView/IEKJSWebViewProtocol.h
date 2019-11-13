//
//  IEKJSWebViewProtocol.h
//  EKPlugins
//
//  Created by Skye on 2018/11/27.
//  Copyright © 2018年 ekwing. All rights reserved.
//
//webView需要实现的方法

#import <Foundation/Foundation.h>

//webView需要实现的对外开放的
@protocol IEKJSWebViewProtocol<NSObject>

#pragma mark - webView 初始化

/*
 * 设置frame初始化
 */
- (nonnull instancetype)initWithFrame:(CGRect)frame;

#pragma mark - localToJS调用
/*
 * 调用jsevent方法，oldFashion只传String给js，不会传object
 */
- (void)setOldFashion;

/*
 * 调用jsevent方法
 * event：方法名字
 * jsonStr：参数
 */
- (void)toJs:(nullable NSString *)event data:(nullable NSString *)jsonStr;

/*
 * 调用jsevent方法
 * event：方法名字
 * jsonStr：参数
 * string:是否只传string给js
 */
- (void)toJs:(nullable NSString *)event data:(nullable NSString *)jsonStr forceString:(BOOL)string;

/*
 * 直接执行JS方法
 */
- (void)evaluateJavaScript:(nullable NSString *)jsCode block:(void(^_Nullable)(id _Nullable backData))block;

#pragma mark - 网页数据加载

/*
 * 加载失败时，点击重新加载，走重新加载流程
 * 通过loadURL和loadRequest方法加载，会进行againLoad流程，否则没有
 */
- (void)againLoadRequest;

/*
 * 重写WebView系统常用方法
 */
- (void)loadURL:(nullable NSString *)url;
- (void)loadRequest:(nullable NSURLRequest *)request;
- (void)loadHTMLString:(nullable NSString *)string baseURL:(nullable NSURL *)baseURL;
- (void)reload;

@optional

/*
 * 设置frame初始化
 * uiWebView - 是否强制使用UIWebView
 */
- (nonnull instancetype)initWithFrame:(CGRect)frame useUIWebView:(BOOL)uiWebView;

@end
