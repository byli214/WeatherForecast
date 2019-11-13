//
//  EKJSTool.h
//  EKPlugins
//
//  Created by Skye on 2018/12/13.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EKJSTool : NSObject

/// 获取bundle中的image
+ (UIImage *)getImageFromBundleWithImageName:(NSString *)imageName;

/// 获取UIViewController
+ (UIViewController *)priFindViewController:(UIView *)sourceView;

/// 通过导航栏颜色 获取状态条的style
+ (UIStatusBarStyle)getStatusBarStyleWithNaviBarColor:(UIColor *)naviBarColor;

#pragma mark - openView 事件相关的工具方法

/**
 * openView时从传过来的dic获取intentData里面的className，用于判断要不要特殊处理而不是走openView逻辑
 */
+ (NSString *)getOpenViewClassName:(NSDictionary *)dic;

/**
 * openView时从传过来的dic获取intentData里面的jump值，用于判断要不要特殊处理
 */
+ (NSString *)getOpenViewJump:(NSDictionary *)dic;

/**
 * openView时从传过来的dic生成UIViewController，供推送以及类似openView的逻辑调用直接生成VC。如果UIViewController
 * 不是EKWebVC的子类，需要自行实现对dic里面其他参数的处理（主要是IntentData里面的各种值）
 */
+ (UIViewController *)openView:(NSDictionary *)dic;

/**
 * 当openView 的data中不存在className或者className_ios时，使用候选 alternativeVCStr
 */
+ (UIViewController *)openView:(NSDictionary *)data alternativeVCStr:(NSString *)alternativeVCStr;

/**
 * 从指定页面 以 某种动画 跳转到对应页面
 */
+ (void)pushToNewVC:(UIViewController *)newVC fromNavi:(UINavigationController *)fromNavi anim:(NSString *)anim;

/**
 * push跳转
 */
+ (CATransition *)getPushCATransitionWithSubType:(NSString *)subType
                                            type:(NSString *)type
                              timingFunctionName: (NSString *)timingFunctionName;
/**
 * 通过传入的字典 获取对应的色值
 */
+ (UIColor *)colorFromRGBColorDic:(NSDictionary *)colorDic;
/**
 * 根据跳转方式以及状态栏颜色获取对应的返回按钮
 */
+ (UIButton *)priGainLeftButtonWithPushType:(NSString *)pushType
                       statusBarStyle:(UIStatusBarStyle)statusBarStyle
                                     target:(nullable id)target
                                     action:(SEL)action;

@end
