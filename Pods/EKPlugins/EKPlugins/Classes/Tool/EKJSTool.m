//
//  EKJSTool.m
//  EKPlugins
//
//  Created by Skye on 2018/12/13.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "EKJSTool.h"
#import "NSDictionary+Help.h"
#import "EKWebVC.h"

@implementation EKJSTool

+ (UIImage *)getImageFromBundleWithImageName:(NSString *)imageName {
    UIImage *image = nil;
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[EKWebVC class]] pathForResource:@"JSResource" ofType:@"bundle"]];
    
    if (bundle) {
        image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    }
    if(!image) {
        image = [UIImage imageNamed:imageName];
    }
    
    return image;
}

//获取UIViewController
+ (UIViewController *)priFindViewController:(UIView *)sourceView {
    id target = sourceView;
    while (target) {
        target = ((UIResponder *)target).nextResponder;
        if ([target isKindOfClass:[UIViewController class]]) {
            break;
        }
    }
    
    return target;
}

//通过导航栏颜色 获取状态条的style
+ (UIStatusBarStyle)getStatusBarStyleWithNaviBarColor:(UIColor *)naviBarColor {
    CGFloat red = 0.0, green = 0.0, blue = 0.0;
    if ([naviBarColor getRed:&red green:&green blue:&blue alpha:nil]) {
        //设置与导航栏同步的状态栏
        float colorValue = (red * 0.299 + green * 0.587 + blue * 0.114) * 255;
        return colorValue <= 192?  UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
    }
    return UIStatusBarStyleDefault;
}

#pragma mark - openView 事件相关的工具方法

+ (NSString *)getOpenViewJump:(NSDictionary *)dic {
    id intentData = [dic objectForKey:@"intentData"];
    if (intentData && [intentData isKindOfClass:[NSDictionary class]]) {
        id className = [intentData objectForKey:@"jump"];
        if (className && [className isKindOfClass:[NSString class]]) {
            return className;
        }
    }
    
    return nil;
}

+ (NSString *)getOpenViewClassName:(NSDictionary *)dic {
    id intentData = [dic objectForKey:@"intentData"];
    if (intentData && [intentData isKindOfClass:[NSDictionary class]]) {
        id className = [intentData objectForKey:@"className_ios"];
        if (className && [className isKindOfClass:[NSString class]]) {
            return className;
        }
        
        className = [intentData objectForKey:@"className"];
        if (className && [className isKindOfClass:[NSString class]]) {
            return className;
        }
    }
    
    return nil;
}

//当openView 的data中不存在className或者className_ios时，使用候选 alternativeVCStr
+ (UIViewController *)openView:(NSDictionary *)data alternativeVCStr:(NSString *)alternativeVCStr {
    if (!data && !alternativeVCStr) {
        return nil;
    }
    
    UIViewController *newVC = nil;
    EKWebVC *webVC = nil;
    NSMutableDictionary *intentData = NULL;
    id obj = [data objectForKey:@"intentData"];
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
        intentData = [[NSMutableDictionary alloc] initWithDictionary:obj];
    }
    
    // intentData has className_xx option, use specified View Controller
    newVC = [self createVCFromIntentData:intentData alternativeVCStr:alternativeVCStr];
    
    if (newVC) {
        if ([newVC isKindOfClass:[EKWebVC class]]) {
            webVC = (EKWebVC *)newVC;
            webVC.data = data;
            
            if (intentData) {
                [intentData removeObjectForKey:@"className"];
                [intentData removeObjectForKey:@"className_ios"];
                [intentData removeObjectForKey:@"jump"];
                webVC.intentData = intentData;
            }
        } else {
            //如果不是EKWebVC的话，统一设置data数据
            //必须保证项目中，使用的VC中有这个data属性 chen
            [newVC setValue:intentData forKey:@"data"];
        }
        
        webVC.hidesBottomBarWhenPushed = YES;
    }
    
    return newVC;
}

+ (UIViewController *)openView:(NSDictionary *)data {
    return [self openView:data alternativeVCStr:nil];
}

+ (UIViewController *)createVCFromIntentData:(NSDictionary *)intentData alternativeVCStr:(NSString *)alternativeVCStr {
    NSString * vailedClassName = nil;
    if (intentData) {
        NSString *className_ios = [intentData js_stringValueForKey:@"className_ios"];
        NSString *className = [intentData js_stringValueForKey:@"className"];
        
        if (className_ios && className_ios.length > 0) {
            vailedClassName = className_ios;
        } else if (className && className.length > 0) {
            vailedClassName = className;
        }
    }
    
    UIViewController *newVC = [self creatVCWithClassName:vailedClassName];
    if (!newVC) {
        newVC = [self creatVCWithClassName:alternativeVCStr];
    }
    
    return newVC;
}

+ (UIViewController *)creatVCWithClassName:(NSString *)className {
    id tempVC;
    if (className && className.length > 0) {
        Class clz = NSClassFromString((NSString *)className);
        if (clz) {
            tempVC = [[clz alloc] init];
        } else {
            // swift need define namespace
            NSString *namespace = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
            NSString *vailedClassName = [NSString stringWithFormat:@"%@.%@", namespace, className];
            clz = NSClassFromString((NSString *)vailedClassName);
            if (clz) {
                tempVC = [[clz alloc] init];
            } else {
                NSLog(@"Warning, class %@(oc) and %@(swift) are not exsit!!!", className, vailedClassName);
            }
        }
    }
    if ([tempVC isKindOfClass:UIViewController.class]) {
        return (UIViewController *)tempVC;
    }
    
    return nil;
}

+ (void)pushToNewVC:(UIViewController *)newVC fromNavi:(UINavigationController *)fromNavi anim:(NSString *)anim {
    if ([anim isEqualToString:@"leftIn"] || [anim isEqualToString:@"topIn"] || [anim isEqualToString:@"bottomIn"] || [anim isEqualToString:@"rightIn"]) {
        NSString *pushType = kCATransitionFromRight;
        if ([anim isEqualToString:@"leftIn"]) {
            pushType = kCATransitionFromLeft;
        } else if ([anim isEqualToString:@"topIn"]) {
            pushType = kCATransitionFromBottom;
        } else if ([anim isEqualToString:@"bottomIn"]) {
            pushType = kCATransitionFromTop;
        }
        
        //保存进入动画
        if ([newVC isKindOfClass:[EKWebVC class]]) {
            EKWebVC *webVC = (EKWebVC *)newVC;
            webVC.pushType = pushType;
        }
        
        //动画跳转
        /* 不使用系统push跳转，否则在 iOS8系统上（或者是UIWebView的原因） 会出现 openView之后 移除历史移除错误的问题
         *1、removeHistory 设置navigationController.viewControllers 有线程保护，不是立即生效的
         *2、iOS8上是先调用removeHistory，再调用viewWillAppear方法
         *3、iOS11上是先调用viewWillAppear，再调用removeHistory
         */
        //        [self.navigationController pushViewController:newVC animated:YES];
        
        CATransition* transition = [self getPushCATransitionWithSubType:pushType type:kCATransitionMoveIn timingFunctionName:kCAMediaTimingFunctionEaseOut];
        [fromNavi.view.layer addAnimation:transition forKey:kCATransition];
        [fromNavi pushViewController:newVC animated:NO];
    } else {
        [fromNavi pushViewController:newVC animated:NO];
    }
}

//获取转场的方式
+ (CATransition *)getPushCATransitionWithSubType:(NSString *)subType
                                            type:(NSString *)type
                              timingFunctionName: (NSString *)timingFunctionName {
    CATransition* transition = [CATransition animation];
    transition.timingFunction = [CAMediaTimingFunction functionWithName:timingFunctionName];
    transition.type = type;
    transition.subtype = subType;
    
    return transition;
}

+ (UIColor *)colorFromRGBColorDic:(NSDictionary *)colorDic {
    if ( ![colorDic isKindOfClass:[NSDictionary class]]) { return nil; }
    
    int red = [colorDic js_intValueForKey:@"red" defaultValue:255];
    int green = [colorDic js_intValueForKey:@"green" defaultValue:215];
    int blue = [colorDic js_intValueForKey:@"blue" defaultValue:68];
    int alpha = [colorDic js_intValueForKey:@"alpha" defaultValue:255];
    
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:alpha / 255.0];
}

//根据跳转方式以及状态栏颜色获取对应的返回按钮
+ (UIButton *)priGainLeftButtonWithPushType:(NSString *)pushType
                       statusBarStyle:(UIStatusBarStyle)statusBarStyle
                                     target:(nullable id)target
                                     action:(SEL)action {
    UIImage *normalImg = nil;
    UIImage *highlighImg = nil;
    if ([pushType isEqualToString:kCATransitionFromTop] || [pushType isEqualToString:kCATransitionFromBottom]) {
        //图片获取
        normalImg = statusBarStyle == UIStatusBarStyleLightContent ? [EKJSTool getImageFromBundleWithImageName:@"white_nav_close"] : [EKJSTool getImageFromBundleWithImageName:@"nav_close"];
        highlighImg = statusBarStyle == UIStatusBarStyleLightContent ? [EKJSTool getImageFromBundleWithImageName:@"white_nav_close_highlight"] : [EKJSTool getImageFromBundleWithImageName:@"nav_close"];
    } else {
        //图片获取
        normalImg = statusBarStyle == UIStatusBarStyleLightContent ? [EKJSTool getImageFromBundleWithImageName:@"white_back_normal"] : [EKJSTool getImageFromBundleWithImageName:@"back_normal"];
        highlighImg = statusBarStyle == UIStatusBarStyleLightContent ? [EKJSTool getImageFromBundleWithImageName:@"white_back_higlight"] : [EKJSTool getImageFromBundleWithImageName:@"back_higlight"];
    }
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [leftButton setImage:normalImg forState:UIControlStateNormal];
    [leftButton setImage:highlighImg forState:UIControlStateHighlighted];
    [leftButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    return leftButton;
}

@end
