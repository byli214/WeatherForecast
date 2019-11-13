//
//  EKWebVC.h
//  EKPlugins
//
//  Created by chen on 2017/8/31.
//  Copyright © 2017年 ekwing. All rights reserved.

#import <UIKit/UIKit.h>
#import "EKJSWebView.h"
#import "IEKJSToLocalBridgeDelegate.h"
#import "IEKJSWebViewDelegate.h"

@interface EKWebVC : UIViewController<IEKJSWebViewDelegate, IEKJSToLocalBridgeDelegate, IEKJSToLocalBridgeDataSource>

/// JS交互代理事件
@property (nonatomic, strong, readonly) EKJSToLocalBridge * jsToLocalBridge;

/// 加载网页的控件
@property (nonatomic, strong) EKJSWebView *webView;
/// 自定义的状态条
@property (nonatomic, strong) UIView *fakeStatusBar;
/// 自定义导航栏-导航栏H5绘制时，临时titleBar，当h5的界面加载出来后消失
@property (nonatomic, strong) UIView *fakeTitleBar;

/// 进入该页面的方式
@property (nonatomic, copy) NSString *pushType;
/// 当前页面是否在栈中被缓存,默认保存
@property (nonatomic, assign) BOOL retainFlag;
///页面重新出现是否需要刷新, 默认为不刷新
@property (nonatomic, assign) BOOL needRefresh;
///H5传参,默认为否。 false:显示电池条，带自定义状态栏; true:不显示电池条，不带自定义状态栏
@property (nonatomic, assign) BOOL fullScreen;
///是否本地绘制titlebar，默认为否。true：本地绘制导航栏,默认使用系统导航栏; false：H5绘制导航栏
@property (nonatomic, assign) BOOL localTitleBar;

#pragma mark - data
/// 请求url
@property (nonatomic, copy) NSString *url;
/// WebVC里主要用来存放openView放入的数据
@property (nonatomic, strong) id data;
/// openView打开界面时，传递一些子类特殊需要的定制的data(使用场景待确定，可能需要移除)
@property (nonatomic, strong) id intentData;

#pragma mark - public
/**
 * 刷新webView
 */
- (void)refreshWebView;

/**
 * 进入前/后台
 */
- (void)enterBackground;
- (void)enterForeground;

/**
 * 根据data中数据进行初始值设置(可重新自定义参数的值，与状态栏、导航栏、webView相关的属性需要在该方法中设置，否则影响界面展示)
 * 初始值的优先级：JS交互中传入的数据 优先级 > 属性设置的
 * 若JS中未定义的参数，以自定义的为准
 * 均未自定义，则按照默认的
 * 如后期更改自定义的状态栏、导航栏、webView特性，以最后更新的为准
 */
- (void)initParameterWithData;

#pragma mark - override 获取自定义的控件/对象
/**
 * 获取JS交互的对象(子类可传回自定义的bridge,并指定delegate)
 */
- (EKJSToLocalBridge *)getJSToLocalBridge;

/**
 * 获取展示网页的控件(子类可传回自定义的WebView,并指定delegate)
 */
- (EKJSWebView *)getJSWebView;

/**
 * 获取自定义的状态栏
 */
- (UIView *)getFakeStatusBar;

/**
 * 获取自定义的导航栏
 */
- (UIView *)getFakeTitleBar;

@end
