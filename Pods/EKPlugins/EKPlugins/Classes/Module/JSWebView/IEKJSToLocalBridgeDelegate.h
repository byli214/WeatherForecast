//
//  IEKJSToLocalBridgeProtocol.h
//  EKPlugins
//
//  Created by Skye on 2018/12/21.
//  Copyright © 2018年 ekwing. All rights reserved.
//

/*
 EKJSToLocalBridge基础回调 代理需要传递localBridge 当页面内多个localBridge 可区分是哪一个localBridge
 */
#import <Foundation/Foundation.h>
#import "IEKJSWebViewDelegate.h"
#import <EKNetWork/EKResultProtocol.h>
@class EKJSToLocalBridge;

#pragma mark - JS回调方法处理完成后的回调事件

@protocol IEKJSToLocalBridgeDelegate<NSObject>

 // JS回调方法处理完成后的回调事件

@optional

//proxy回调（旧版）

- (void)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge onProxyRequest:(NSString * _Nullable)reqData;
- (void)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge onProxySuccess:(NSString * _Nullable)url params:(NSString * _Nullable)reqData result:(NSString * _Nullable)resultJson;
- (void)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge onProxyFailed:(NSString * _Nullable)url params:(NSString * _Nullable)reqData result:(NSString * _Nullable)resultString;
- (void)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge onProxyExpired:(NSString * _Nullable)url result:(NSString * _Nullable)resultString;

//netProxy回调（新版）
//网络请求开始前
- (void)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge onNetProxyRequest:(NSString * _Nullable)reqData;
//网络请求结束后
- (void)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge onNetProxyResult:(id<EKDataResultProtocol> _Nonnull)result;

//setNaviBar 回调
- (void)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge changeStatusBarColor:(NSDictionary * _Nullable)colorDic;

//changeOpenViewData 回调
- (void)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge changeOpenViewDataWithJsonDic:(NSDictionary * _Nullable)jsonDic;

//goback 回调
- (void)gobackInLocalBridge:(EKJSToLocalBridge * _Nonnull)localBridge;

@end

@protocol IEKJSToLocalBridgeDataSource<NSObject>

@optional
#pragma mark - openView
//获取 openView,打开相册 等 跳转依赖的VC
- (UINavigationController * _Nullable)naviForOpenViewInLocalBridge:(EKJSToLocalBridge * _Nonnull)localBridge;

//bridge当前所在VC
- (UIViewController * _Nullable)vcInLocalBridge:(EKJSToLocalBridge * _Nonnull)localBridge;

/*
 * 自定义需要打开的openView的className
 * 获取 openView需要打开的VC的规则如下：
 * 1. 优先使用intendData中className创建VC
 * 2. 当intendData中className无有效值时，则使用方法 getVClassNameForOpenView 获取对应的className。若dataSource为webVC的子类且未重写该方法，则使用该父类中返回的“EKWebVC”进行创建
 * 3. 若以上都没有对应实现或参数，则返回nil
 */
- (NSString * _Nullable)newVCClassNameForOpenViewInLocalBridge:(EKJSToLocalBridge * _Nonnull)localBridge;

#pragma mark - removeHistory
//移除历史 依赖的UINavigationController
- (UINavigationController * _Nullable)naviForRemoveHistoryInLocalBridge:(EKJSToLocalBridge * _Nonnull)localBridge;


#pragma mark -proxy
//获取proxy上报到服务端的错误原因（主要兼容双语优榜\翼课教师-智慧课堂，待1.1 版本使用新的proxy规则后该方法会被移除）
- (NSString * _Nullable)localBridge:(EKJSToLocalBridge * _Nonnull)localBridge getErrorStrOnProxyFailed:(NSString * _Nullable)url result:(NSString * _Nullable)resultString httpCode:(int)code;

@end
