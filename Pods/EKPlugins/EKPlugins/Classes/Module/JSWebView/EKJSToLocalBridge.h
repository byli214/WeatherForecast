//
//  EKJSToLocalBridge.h
//  EKPlugins
//
//  Created by Skye on 2018/11/27.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IEKJSToLocalBridgeDelegate.h"
#import "IEKJSWebViewDelegate.h"

@class EKJSWebView;

@interface EKJSToLocalBridge: NSObject<IEKWebViewJS2LocalDelegate>

@property (nonatomic, weak, nullable) EKJSWebView *webView;

///JS交互需要代理处理的事件,如：设置导航栏颜色，改变openView中的data的数据
@property (nonatomic, weak, nullable) id<IEKJSToLocalBridgeDelegate> delegate;
///JS交互处理事件需要获取的数据,如：openView时 跳转页面需要的跳板：VC
@property (nonatomic, weak, nullable) id<IEKJSToLocalBridgeDataSource> dataSource;

#pragma mark - public

/**
 * 设置应用加载的信息
 * token：token信息
 * uid：用户uid信息
 * driverCode：应用版本号
 * v：接口请求版本号
 * 等等其他参数
 * 格式：[key1:value1,key2:value2]
 */
- (void)setWebViewParameterDic:(NSDictionary *_Nullable) parameterDic;

/**
 * 获取外部设置的参数
 * 格式[key1:value1,key2:value2]
 */
- (NSDictionary *_Nullable)getRequestParameters;

/**
 * webView隐藏, 停止音频播放(其它功能待增加)
 */
- (void)onWebViewHide;

/**
 * 回调H5，暴露该方法，在回调前可对回调数据进行补充、修改等操作
 * event：处理...事件时需要处理的回调，方便各个App进行事件捕获。如：proxy，getSysInfo
 * data: JS交互传递过来的数据
 * callBack 方法名，需要回调H5的方法名
 * callBackData：回调参数
 */
- (void)toJSWithEvent:(NSString *_Nullable)event data:(id _Nullable )data  callBack:(NSString *_Nullable)callBack callBackData:(id _Nullable)callBackData;

@end
