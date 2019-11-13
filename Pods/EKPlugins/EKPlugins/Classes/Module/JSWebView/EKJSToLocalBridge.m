//
//  EKJSToLocalBridge.m
//  EKPlugins
//
//  Created by Skye on 2018/11/27.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "EKJSToLocalBridge.h"
#import <Foundation/Foundation.h>
#import "NSDictionary+Help.h"
#import "NSArray+Help.h"
#import "EKProxyUtils.h"
#import "JSAmasBaseUtils.h"
#import "IEKJSWebViewProtocol.h"
#import "EKJSTool.h"
#import "NSString+Help.h"
#import "EKJSWebView.h"

//第三方库
#import <EKNetWork/EKNetWork.h>

@interface EKJSToLocalBridge()

@property (nonatomic, strong) EKProxyUtils *httpReq; //网络请求
@property (nonatomic, strong) EKDataRequest *dataReq; //新封装的网络请求库
@property (nonatomic, strong) NSDictionary *parameterDic; //传进的网页加载参数

@end

@implementation EKJSToLocalBridge

#pragma mark - IEKWebViewJS2LocalDelegate
- (BOOL)jsWebView:(EKJSWebView *)jsWebView customizedLocalEvent:(NSString *)event data:(id)json {
    NSDictionary *jsonDic = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        jsonDic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        id jsonData = [(NSString *)json JSONToObject];
        if ([jsonData isKindOfClass:[NSDictionary class]]) {
            jsonDic = jsonData;
        }
    }
    
    //分类处理事件
    if ([event isEqualToString:@"playAudio"]) {
        //播放音频
        if ([self respondsToSelector:@selector(jsWebView:playAudioActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView playAudioActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"playStatus"]) {
        //播放状态
        if ([self respondsToSelector:@selector(jsWebView:playStatusActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView playStatusActionWithJsonDic:jsonDic];
        }
    }  else if ([event isEqualToString:@"fetchLocalAudioSrc"]) {
        //预加载音频
        if ([self respondsToSelector:@selector(jsWebView:fetchLocalAudioSrcActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView fetchLocalAudioSrcActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"getSysInfo"]) {
        //获取系统信息
        if ([self respondsToSelector:@selector(jsWebView:getSysInfoActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView getSysInfoActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"proxy"]) {
        //proxy网络请求代理
        if ([self respondsToSelector:@selector(jsWebView:proxyActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView proxyActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"netProxy"]) {
        //新的网络代理请求
        if ([self respondsToSelector:@selector(jsWebView:netProxyActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView netProxyActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"setLocalCache"]) {
        //添加缓存
        if ([self respondsToSelector:@selector(jsWebView:setLocalCacheActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView setLocalCacheActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"getLocalCache"]) {
        //获取缓存内容
        if ([self respondsToSelector:@selector(jsWebView:getLocalCacheActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView getLocalCacheActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"clearLocalCache"]) {
        //清理缓存内容
        if ([self respondsToSelector:@selector(jsWebView:clearLocalCacheActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView clearLocalCacheActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"addressBook"]) {
        //打开通讯录
        if ([self respondsToSelector:@selector(jsWebView:addressBookActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView addressBookActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"changeOpenViewData"]) {
        //改变openView传进的data的数据
        if ([self respondsToSelector:@selector(jsWebView:changeOpenViewDataActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView changeOpenViewDataActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"setNaviBar"]) {
        //设置导航栏的颜色
        if ([self respondsToSelector:@selector(jsWebView:setNaviBarActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView setNaviBarActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"goback"]) {
        //返回上一页面
        if ([self respondsToSelector:@selector(jsWebView:goBackActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView goBackActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"openView"]) {
        //打开新的页面
        if ([self respondsToSelector:@selector(jsWebView:openViewActionWithJsonDic:)]) {
            return [self jsWebView:jsWebView openViewActionWithJsonDic:jsonDic];
        }
    } else if ([event isEqualToString:@"removeHistory"]) {
        //移除历史（移除已打开页面 中 的个别页面）
        if ([json isKindOfClass:[NSString class]]) {
            NSString *jsonStr = (NSString *)json;
            if ([self respondsToSelector:@selector(jsWebView:removeHistoryActionWithJson:)]) {
                return [self jsWebView:jsWebView removeHistoryActionWithJson:jsonStr];
            }
        }
    }

    return false;
}

#pragma mark - public

- (void)setWebViewParameterDic:(NSDictionary *) parameterDic {
    self.parameterDic = parameterDic;
}

- (NSDictionary *)getRequestParameters {
    NSMutableDictionary *mutParam = [NSMutableDictionary dictionary];
    if ([self.parameterDic isKindOfClass:[NSDictionary class]] && self.parameterDic.count) {
        mutParam = [NSMutableDictionary dictionaryWithDictionary:self.parameterDic];
    }
    NSString *uid = [self.parameterDic js_stringValueForKey:@"uid"];
    if (uid && uid.length) {
        [mutParam setValue:uid forKey:@"uid"];
        [mutParam setValue:uid forKey:@"author_id"];
    }
    
    return [mutParam copy];
}

- (void)onWebViewHide {
    if ([self respondsToSelector:@selector(stopMediaPlayerPool)]) {
        [self performSelector:@selector(stopMediaPlayerPool)];
    }
}
    
- (void)toJSWithEvent:(NSString *_Nullable)event data:(id _Nullable )data  callBack:(NSString *_Nullable)callBack callBackData:(id _Nullable)callBackData {
    NSString *json = nil;
    if ([callBackData isKindOfClass:[NSString class]]) {
        json = (NSString *)callBackData;
    } else if ([callBackData isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dataDic = (NSDictionary *)callBackData;
        json = [dataDic JSONToString];
    } else if ([data isKindOfClass:[NSArray class]]) {
        NSArray *dataArr = (NSArray *)callBackData;
        json = [dataArr JSONToString];
    }
    
    [self.webView toJs:callBack data:json];
}

#pragma mark - setter/getter

- (void)setParameterDic:(NSDictionary *)parameterDic {
    _parameterDic = parameterDic;
}

@end
