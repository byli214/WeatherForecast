//
//  EKJSWebView+Help.h
//  EKPlugins
//
//  Created by Skye on 2018/5/17.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "EKJSWebView.h"


@interface WKWebView (Keyboard)

/**
 * 在加载页面的时候 设置焦距 直接显示键盘的权限
 * UIWebView 有属性 keyboardDisplayRequiresUserAction 默认 true
 * WKWebView 无该属性 wkWebViewShowKeybord解决不能自动弹出键盘的问题
 */
+ (void)wkWebViewShowKeybord;

@end

@interface EKJSWebView (Tool)

/**
 * 清理 webView 缓存的内容
 */
+ (void)clearWebViewCache;

@end
