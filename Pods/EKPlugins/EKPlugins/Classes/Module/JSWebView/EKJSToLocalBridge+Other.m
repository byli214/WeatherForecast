//
//  EKJSToLocalBridge+Other.m
//  EKPlugins
//
//  Created by Skye on 2018/12/13.
//  Copyright © 2018年 ekwing. All rights reserved.
//
//暂时不确定怎么分组的一波
//与VC有关的一波

#import "EKJSToLocalBridge+Other.h"
#import "EKWebVC.h"
#import "EKJSTool.h"
#import "NSDictionary+Help.h"

@implementation EKJSToLocalBridge (Other)

//移除历史
- (BOOL)jsWebView:(EKJSWebView *)jsWebView removeHistoryActionWithJson:(NSString *)json {
    NSInteger n = [json integerValue];
    if (n > 0) {
        UINavigationController *navi = nil;
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(naviForRemoveHistoryInLocalBridge:)]) {
            navi = [self.dataSource naviForRemoveHistoryInLocalBridge:self];
        }
        NSMutableArray *array = [[NSMutableArray alloc] initWithArray: navi.viewControllers];
        NSInteger count = [array count];
        while (n > 0 && count > 1) {
            if ([[array objectAtIndex:count - 2] isKindOfClass:[EKWebVC class]]) {
                [array removeObjectAtIndex:count - 2];
                --count;
                --n;
            } else {
                break;
            }
        }
        navi.viewControllers = array;
    }
        
    return YES;
}

//改变openView中的data的数据
- (BOOL)jsWebView:(EKJSWebView *)jsWebView changeOpenViewDataActionWithJsonDic:(NSDictionary *)jsonDic {
    if (self.delegate && [self.delegate respondsToSelector:@selector(localBridge:changeOpenViewDataWithJsonDic:)]) {
        [self.delegate localBridge:self changeOpenViewDataWithJsonDic:jsonDic];
    }
    
    return YES;
}

//打开新的页面
- (BOOL)jsWebView:(EKJSWebView *)jsWebView openViewActionWithJsonDic:(NSDictionary *)jsonDic {
    NSString *callBack = [jsonDic js_stringValueForKey:@"callBack"];
    //使用intendData中数据创建VC,不存在则使用 alternativeVCStr创建
    NSString *alternativeVCStr = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(newVCClassNameForOpenViewInLocalBridge:)]) {
        alternativeVCStr = [self.dataSource newVCClassNameForOpenViewInLocalBridge:self];
    }
    UIViewController *newVC = [EKJSTool openView:jsonDic alternativeVCStr:alternativeVCStr];
    UINavigationController *fromNavi = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(naviForOpenViewInLocalBridge:)]) {
        fromNavi = [self.dataSource naviForOpenViewInLocalBridge:self];
    }
    if (!fromNavi) {
        NSLog(@"没有返回有效的可打开其他页面的跳板Navi");
        return true;
    }
    
    NSString *anim = [jsonDic js_stringValueForKey:@"anim"];
    if (newVC) {
        //跳转到新的页面
        if ([newVC isKindOfClass:[EKWebVC class]]) {
            EKWebVC *webVC = (EKWebVC *)newVC;
            [webVC.jsToLocalBridge setWebViewParameterDic:[self getRequestParameters]];
        }
        
        [EKJSTool pushToNewVC:newVC fromNavi:fromNavi anim:anim];
        
        //naivi中的chiildVC为EKWebVC， 移除不需要缓存在栈中的
        UINavigationController *removeHistoryNavi = nil;
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(naviForRemoveHistoryInLocalBridge:)]) {
            removeHistoryNavi = [self.dataSource naviForRemoveHistoryInLocalBridge:self];
        }
        //移除 之前标记的需要移除的网页
        if (removeHistoryNavi.childViewControllers.count > 0) {
            NSMutableArray *array = [[NSMutableArray alloc] initWithArray: removeHistoryNavi.viewControllers];
            
            for (UIViewController *childVC in removeHistoryNavi.childViewControllers) {
                if ([childVC isKindOfClass:[EKWebVC class]]) {
                    EKWebVC *webVC = (EKWebVC *)childVC;
                    //新打开的VC不做移除
                    if (webVC == newVC) {
                        continue;
                    } else if (!webVC.retainFlag) {
                        [array removeObject:webVC];
                    }
                }
            }
            removeHistoryNavi.viewControllers = array;
        }
        
        // openView成功回调告诉h5
        if ([callBack length] > 0) {
             [self toJSWithEvent:@"openView" data:jsonDic callBack:callBack callBackData:@""];
        }
    }
    
    return YES;
}

//改变当前导航栏的颜色
- (BOOL)jsWebView:(EKJSWebView *)jsWebView setNaviBarActionWithJsonDic:(NSDictionary *)jsonDic {
    if (self.delegate && [self.delegate respondsToSelector:@selector(localBridge:changeStatusBarColor:)]) {
        [self.delegate localBridge:self changeStatusBarColor:jsonDic];
    }
    
    return YES;
}

//返回上一页面
- (BOOL)jsWebView:(EKJSWebView *)jsWebView goBackActionWithJsonDic:(NSDictionary *)jsonDic {
    if (self.delegate && [self.delegate respondsToSelector:@selector(gobackInLocalBridge:)]) {
        [self.delegate gobackInLocalBridge:self];
    }
    
    return YES;
}

@end
