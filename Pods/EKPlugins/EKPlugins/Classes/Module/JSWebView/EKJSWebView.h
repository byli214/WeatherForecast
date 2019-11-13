//
//  EKJSWebView.h
//  EKPlugins
//
//  Created by chen on 2017/8/21.
//  Copyright © 2017年 ekwing. All rights reserved.
//  JS和Native交互中，显示H5类，代替UIWebView和WKWebView

#import <UIKit/UIKit.h>
#import "IEKJSWebViewProtocol.h"

@protocol IEKJSWebViewDelegate;
@protocol IEKWebViewJS2LocalDelegate;
@protocol IEKLocalBridgeProtocol;
@class EKJSToLocalBridge;

@interface EKJSWebView: UIView<IEKJSWebViewProtocol>

#pragma mark - webView 属性

/// webView的scrollView
@property (nullable, nonatomic, readonly) UIScrollView* scrollView;

/// webView的 在加载页面的时候 设置焦距 直接显示键盘的权限 默认 true,苹果默认是不允许h5直接调起键盘的
@property (nonatomic, assign) BOOL keyboardDisplayRequiresUserAction;

#pragma mark - webView代理对象

/// IEKJSWebViewDelegate: 网页加载状态 变更 回调事件
@property (nullable, nonatomic, weak) id<IEKJSWebViewDelegate> webViewDelegate;

/**
 * 各个APP需要实现新的JS交互方法：
 * 1.需要使用通用的JS交互方法时，jsToLocalDelegate应该为EKJSToLocalBridge的子类
 * 2.在自定义的子类中实现各个App需要实现的JS交互方法
 * 3.当JS交互方法成为通用方法，则移植到通用JS交互库
 */
@property (nullable, nonatomic, weak) EKJSToLocalBridge *jsToLocalDelegate;

#pragma mark - 与单个App业务相关的（待转移到具体App）

/// webView 是否支持接收到 SY_NOTIFICATION_USERINFO通知 时 reload, default is YES
@property (nonatomic, assign) BOOL noticeReload;

//网页加载的url允许转码的特殊字符，默认为：" #\"%<>@[\\]^`{|}"
- (NSCharacterSet *_Nullable)allowedCharactersByAddingPercentEncodingForWebLoadUrl;

@end


