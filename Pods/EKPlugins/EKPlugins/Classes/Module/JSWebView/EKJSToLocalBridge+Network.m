//
//  EKJSToLocalBridge+Network.m
//  EKPlugins
//
//  Created by Skye on 2018/12/13.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "EKJSToLocalBridge+Network.h"
#import "NSDictionary+Help.h"
#import "EKProxyUtils.h"
#import "EKJSWebView.h"
#import <EKNetWork/EKNetWork.h>
#import <objc/runtime.h>

const static int LOGIN_EXPIRED = 10000;// 登录失效
static char EKJSToLocalBridge_HttpReq;

@implementation EKJSToLocalBridge (Network)

@dynamic httpReq;
    
- (void)setHttpReq:(EKProxyUtils *)httpReq {
    objc_setAssociatedObject(self, &EKJSToLocalBridge_HttpReq, httpReq, OBJC_ASSOCIATION_RETAIN);
}

- (EKProxyUtils *)httpReq {
    return objc_getAssociatedObject(self, &EKJSToLocalBridge_HttpReq);
}

// MARK: - 网络请求
- (BOOL)jsWebView:(EKJSWebView *)jsWebView proxyActionWithJsonDic:(NSDictionary *)jsonDic {
    NSString *jsonStr = [jsonDic JSONToString];
    if (self.delegate && [self.delegate respondsToSelector:@selector(localBridge:onProxyRequest:)]) {
        [self.delegate localBridge:self onProxyRequest:jsonStr];
    }
    NSString *sucCB = [jsonDic js_stringValueForKey:@"success"];
    NSString *failCB = [jsonDic js_stringValueForKey:@"fail"];
    
    NSDictionary *baseParam = [self getRequestParameters];
    NSString *proxyUrl = [jsonDic js_stringValueForKey:@"url"];
    if (!self.httpReq) {
        self.httpReq = [[EKProxyUtils alloc] init];
    }
    
    [self.httpReq handleRequest:jsonDic baseParam:baseParam success:^(NSDictionary *respon) {
        NSString *success = [respon JSONToString];
        [self toJSWithEvent:@"proxy" data:jsonDic callBack:sucCB callBackData:success];
        if (self.delegate && [self.delegate respondsToSelector:@selector(localBridge:onProxySuccess:params:result:)]) {
            [self.delegate localBridge:self onProxySuccess:proxyUrl params:jsonStr result:success];
        }
    } failed:^(NSString *failedReason, int httpCode, int code) {
        if (self.delegate) {
            if (code == LOGIN_EXPIRED) {
                [self toJSWithEvent:@"proxy" data:jsonDic callBack:failCB callBackData:failedReason];
                
                if ( [self.delegate respondsToSelector:@selector(localBridge:onProxyExpired:result:)]) {
                    [self.delegate localBridge:self onProxyExpired:proxyUrl result:failedReason];
                }
            } else {
                /// 项目中，根据httpCode重新提示
                NSString *grabReason;
                if (self.dataSource && [self.dataSource respondsToSelector:@selector(localBridge:getErrorStrOnProxyFailed:result:httpCode:)]) {
                    grabReason = [self.dataSource localBridge:self getErrorStrOnProxyFailed:proxyUrl result:failedReason httpCode:httpCode];
                }
                NSString *requestFailReson = (grabReason && grabReason.length > 0) ? grabReason : failedReason;
                [self toJSWithEvent:@"proxy" data:jsonDic callBack:failCB callBackData:requestFailReson];
                
                if ( [self.delegate respondsToSelector:@selector(localBridge:onProxyFailed:params:result:)]) {
                    [self.delegate localBridge:self onProxyFailed:proxyUrl params:jsonStr result:failedReason];
                }
            }
        } else {
            [self toJSWithEvent:@"proxy" data:jsonDic callBack:failCB callBackData:failedReason];
        }
    }];
    
    return true;
}

#pragma mark - newProxy
- (BOOL)jsWebView:(EKJSWebView *)jsWebView netProxyActionWithJsonDic:(NSDictionary *)jsonDic {
    NSString *jsonStr = [jsonDic JSONToString];
    if (self.delegate && [self.delegate respondsToSelector:@selector(localBridge:onNetProxyRequest:)]) {
        [self.delegate localBridge:self onNetProxyRequest:jsonStr];
    }
    NSString *sucCB = [jsonDic js_stringValueForKey:@"success"];
    NSString *failCB = [jsonDic js_stringValueForKey:@"fail"];
    
    NSString *url = [jsonDic js_stringValueForKey:@"url"];
    NSDictionary *baseParam = [self getRequestParameters];
    
    if (!jsonDic || url.length < 5) {
        //回调失败（需要一种统一的方式来优化处理）
        //        [self toJSWithEvent:@"netProxy" callBack:failCB data:errorDic];
        return true;
    }
    
    NSDictionary *datas = [jsonDic objectForKey:@"data"];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:baseParam];
    [parameters addEntriesFromDictionary:datas];
    NSString *method = [jsonDic js_stringValueForKey:@"type"];
    //设置允许获取的数据类型（默认数据类型，不支持html格式）
    //    [EKNetWorkConfg.shared setAcceptableContentTypes:@[@"application/json", @"text/json", @"text/javascript"]];
    EKDataRequestManager *shareManager = [EKDataRequestManager shared];
    EKDataInfo *dataInfo = [[EKDataInfo alloc] initWithUrl:url];
    dataInfo.method = [method isEqualToString:@"GET"] ? EKNetGet : EKNetPost;
    __weak typeof(self) weakSelf = self;

    [shareManager startWithInfo:dataInfo argument:parameters complete:^(id<EKDataResultProtocol>  _Nonnull result) {
        //回调代理执行 网络请求后的结果
        if ([weakSelf.delegate respondsToSelector:@selector(localBridge:onNetProxyResult:)]) {
            [weakSelf.delegate localBridge:weakSelf onNetProxyResult:result];
        }
        if (result.error) {
            //网络错误，自己封装
            NSDictionary *errorDic = [self getErrorDicFromResult: result];
            [weakSelf toJSWithEvent:@"netProxy" data:jsonDic callBack:failCB callBackData:errorDic];
        } else {
            //连接服务器成功，统一按照成功回调
            [weakSelf toJSWithEvent:@"netProxy" data:jsonDic callBack:sucCB callBackData:result.resonseString];
        }
    }];
    
    return true;
}

// MARK: - private
- (NSDictionary *)getErrorDicFromResult:(id<EKDataResultProtocol> _Nonnull)result {
    
    int errCode = -1;
    int detailCode = INT_MIN;
    NSString *errMsg = nil;
    if (result.response && [result.response isKindOfClass:[NSHTTPURLResponse class]]) {
        detailCode = (int)[(NSHTTPURLResponse *)result.response statusCode];
    } else {
        detailCode = result.error.code;
    }
    if (detailCode == kCFURLErrorNotConnectedToInternet) {
        //无网络连接
        detailCode = -1;
        errMsg = @"网络未连接，请设置网络（-1）";
    } else if (detailCode >= 500 && detailCode < 600) {
        errMsg = [[NSString alloc] initWithFormat:@"服务器连接不稳定，请稍候再试（%d）", detailCode] ;
    } else {
        errMsg = [[NSString alloc] initWithFormat:@"网络较差，无法连接到服务器（%d）", detailCode] ;
    }
    
    NSDictionary *dataDic = @{@"errCode": @(errCode),
                              @"detailCode": @(detailCode),
                              @"errMsg": errMsg};
    NSDictionary *errorDic = @{@"status": @(-1),
                               @"data":dataDic};
    
    return errorDic;
}

@end
