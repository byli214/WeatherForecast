//
//  EKJSWebView.m
//  EKPlugins
//
//  Created by chen on 2017/8/21.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#if (__MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_9 || __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0)
#define supportsWKWebKit
#endif

#import "EKJSWebView.h"
#import "EKJSWebViewHeader.h"
#import "EKJSWebView+Help.h"

#import "EKJSWebView.h"
#import "EKJsonParser.h"
#import "EKJsonBuilder.h"

#import "NSString+Help.h"
#import "EKJSToLocalBridge.h"
#import "IEKJSWebViewProtocol.h"
#import "EKJSTool.h"

#ifdef supportsWKWebKit
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#endif

@interface EKJSWebView()<UIWebViewDelegate, WKNavigationDelegate, WKUIDelegate>

///使用的系统webView
@property (nullable, nonatomic, strong) id realWebView;
///localToBridge 传递的数据类型 是否只传递字符串
@property (nonatomic, assign) BOOL stringOnly;
@property (nonatomic, strong) NSURLRequest *oldRequest;

@end

@implementation EKJSWebView

#pragma mark - webView life

- (void)dealloc {
    if ([self.realWebView isKindOfClass:[UIWebView class]]) {
        UIWebView* webView = self.realWebView;
        webView.delegate = nil;
        [webView loadHTMLString:@"" baseURL:nil];
        [webView stopLoading];
    } else {
        WKWebView* webView = self.realWebView;
        webView.UIDelegate = nil;
        webView.navigationDelegate = nil;
        [webView stopLoading];
        
        [webView removeObserver:self forKeyPath:@"estimatedProgress"];
    }
    
    [self.realWebView scrollView].delegate = nil;
    [self.realWebView removeFromSuperview];
    self.realWebView = nil;
}

- (nonnull instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame useUIWebView:NO];
}

- (nonnull instancetype)initWithFrame:(CGRect)frame useUIWebView:(BOOL)uiWebView {
    self = [super initWithFrame:frame];
    
    if (self) {
        _stringOnly = NO;
        _noticeReload = YES;
        if (uiWebView) {
            self.realWebView = [self initialUIWebView];
        } else {
#ifdef supportsWKWebKit
            //WKWebView在ios8系统上，JS进行post请求有问题，所以从9.0开始使用WKWebView
            //翼课学院的游戏题型在5s+UIWebView 上显示空白，暂时遗留
            if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
                self.realWebView = [self initialWKWebView];
            } else {
                self.realWebView = [self initialUIWebView];
            }
#else
            self.realWebView = [self initialUIWebView];
#endif
        }
        
        [self.realWebView setFrame:self.bounds];
        [self.realWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self addSubview:self.realWebView];
        
#warning -todo- 与App业务相关，需要移植到App内部
        //监听支付成功后,个人信息vip状态刷新,reload webView
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadWebViewFunc:)
                                                     name:@"SY_NOTIFICATION_USERINFO"
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - setter/getter

- (UIScrollView *)scrollView {
    return [(id)self.realWebView scrollView];
}

- (void)setKeyboardDisplayRequiresUserAction:(BOOL)keyboardDisplayRequiresUserAction {
    if ([self.realWebView isKindOfClass:[WKWebView class]]){
        if (!keyboardDisplayRequiresUserAction){
            [WKWebView wkWebViewShowKeybord];
        }
    }else if ([self.realWebView isKindOfClass:[UIWebView class]]){
        UIWebView *webView = (UIWebView *)self.realWebView;
        webView.keyboardDisplayRequiresUserAction = keyboardDisplayRequiresUserAction;
    }
}

- (void)setJsToLocalDelegate:(EKJSToLocalBridge *)jsToLocalDelegate {
    _jsToLocalDelegate = jsToLocalDelegate;
    _jsToLocalDelegate.webView = self;
}

#pragma mark - public
- (NSCharacterSet *_Nullable)allowedCharactersByAddingPercentEncodingForWebLoadUrl {
    NSCharacterSet *combinedCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@" #\"%<>@[\\]^`{|}"] invertedSet];

    return combinedCharacterSet;
}

#pragma mark - localToJS调用

- (void)setOldFashion {
    _stringOnly = YES;
    
}

- (void)toJs:(nullable NSString *)event data:(nullable NSString *)jsonStr {
    [self toJs:event data:jsonStr forceString:_stringOnly];
}

- (void)toJs:(nullable NSString *)event data:(nullable NSString *)jsonStr forceString:(BOOL)string {
    if (!event || event.length <= 0) { return; }
    
    NSString *format = JS_EVENT_STR_FORMAT;
    if (!jsonStr) { jsonStr = @""; }
    
    if (!string) {
        if (jsonStr) {
            id dic = [jsonStr JSONToObject];
            format = dic ? JS_EVENT_JSON_FORMAT : JS_EVENT_STR_FORMAT;
        }
    }
    
    NSString *escapeStr = [jsonStr stringByReplacingOccurrencesOfString:@"\'" withString:@"&#39;"];
    NSString *jsCode = [NSString stringWithFormat:format, event, escapeStr];
    
    if ([self.realWebView isKindOfClass:[UIWebView class]]) {
        [(UIWebView *)self.realWebView stringByEvaluatingJavaScriptFromString:jsCode];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [(WKWebView *)self.realWebView evaluateJavaScript:jsCode completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                
            }];
        });
    }
}

- (void)evaluateJavaScript:(nullable NSString *) jsCode block:(void(^)(id backData))block {
    if ([self.realWebView isKindOfClass:[UIWebView class]]) {
        NSString *backStr = [(UIWebView *)self.realWebView stringByEvaluatingJavaScriptFromString:jsCode];
        if (block) {
            block(backStr);
        }
    } else {
        [(WKWebView *)self.realWebView evaluateJavaScript:jsCode completionHandler:^(id _Nullable backData, NSError * _Nullable error) {
            if (block) {
                block(backData);
            }
        }];
    }
}

#pragma mark - 网页数据加载

- (void)againLoadRequest {
    if ([self.oldRequest isKindOfClass:[NSURLRequest class]]) {
        [self loadRequest:self.oldRequest];
    }
}

- (void)loadRequest:(nullable NSURLRequest *)request {
    self.oldRequest = request;
    
    if ([self.realWebView isKindOfClass:[UIWebView class]]) {
        [(UIWebView *)self.realWebView loadRequest:request];
    } else {
        [(WKWebView *)self.realWebView loadRequest:request];
    }
}

- (void)loadHTMLString:(nullable NSString *)string baseURL:(nullable NSURL *)baseURL {
    if ([self.realWebView isKindOfClass:[UIWebView class]]) {
        [(UIWebView *)self.realWebView loadHTMLString:string baseURL:baseURL];
    } else {
        [(WKWebView *)self.realWebView loadHTMLString:string baseURL:baseURL];
    }
}

- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL {
    if ([self.realWebView isKindOfClass:[UIWebView class]]) {
        [(UIWebView *)self.realWebView loadData:data MIMEType:MIMEType textEncodingName:textEncodingName baseURL:baseURL];
    } else {
        [(WKWebView *)self.realWebView loadData:data MIMEType:MIMEType characterEncodingName:textEncodingName baseURL:baseURL];
    }
}

- (void)loadURL:(nullable NSString *)url {
    // Desperated because it converses # to %23
    //NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    
    // all set is @" \"#%/:<>?@[\\]^`{|}", remove '?' '/' ':' '#' for it is supported
    // 参考：encodeURI不编码字符有82个：!，#，$，&，'，(，)，*，+，,，-，.，/，:，;，=，?，@，_，~，0-9，a-z，A-Z
    //URLQueryAllowedCharacterSet    "#%<>[\]^`{|} ;当前默认 比URLQueryAllowedCharacterSet多了" \\#"
    NSCharacterSet *combinedCharacterSet = [self allowedCharactersByAddingPercentEncodingForWebLoadUrl];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:combinedCharacterSet]]];
    
    [self loadRequest:req];
}

- (void)reload {
    if ([self.realWebView isKindOfClass:[UIWebView class]]) {
        [(UIWebView *)self.realWebView reload];
    } else {
        [(WKWebView *)self.realWebView reload];
    }
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onProgressChangedWithProgress:)]) {
            int estimatedProgress = [change[NSKeyValueChangeNewKey] doubleValue] * 100;
            if (estimatedProgress > 100) estimatedProgress = 100;
            [self.webViewDelegate jsWebView:self onProgressChangedWithProgress:estimatedProgress];
        }
    } else {
        [self willChangeValueForKey:keyPath];
        [self didChangeValueForKey:keyPath];
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onProgressChangedWithProgress:)]) {
        [self.webViewDelegate jsWebView:self onProgressChangedWithProgress:1];
    }
    
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onPageStartedWithUrl:)]) {
        [self.webViewDelegate jsWebView:self onPageStartedWithUrl:[[[webView request] URL] absoluteString]];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onProgressChangedWithProgress:)]) {
        [self.webViewDelegate jsWebView:self onProgressChangedWithProgress:100];
    }
    
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onPageFinishedWithUrl:)]) {
        [self.webViewDelegate jsWebView:self onPageFinishedWithUrl:[[[webView request] URL] absoluteString]];
    }
    
    [self showSource];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onProgressChangedWithProgress:)]) {
        [self.webViewDelegate jsWebView:self onProgressChangedWithProgress:100];
    }
    
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onReceivedErrorWithErrorCode:des:url:)]) {
        [self.webViewDelegate jsWebView:self onReceivedErrorWithErrorCode:(int)[error code] des:[error description] url:[[[webView request] URL] absoluteString]];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *urlString = request.URL.absoluteString;
    
    #warning -todo- 增加ekwing:jsExam，暂时先修改错题本中考试错题数据，待学生端中全面替换JS交互时，再统一，使用关键字有所不同 chen加
    if ([urlString rangeOfString:@"ekwing:abc"].length > 0 || [urlString rangeOfString:@"ekwing:jsExam"].length > 0) {
        [self handleLocalEvent:urlString];
        return NO;
    };
    
    return YES;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onProgressChangedWithProgress:)]) {
        [self.webViewDelegate jsWebView:self onProgressChangedWithProgress:1];
    }
    
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onPageStartedWithUrl:)]) {
        [self.webViewDelegate jsWebView:self onPageStartedWithUrl:[[webView URL] absoluteString]];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onProgressChangedWithProgress:)]) {
         [self.webViewDelegate jsWebView:self onProgressChangedWithProgress:100];
    }
    
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onPageFinishedWithUrl:)]) {
        [self.webViewDelegate jsWebView:self onPageFinishedWithUrl:[[webView URL] absoluteString]];
    }
    
    [self showSource];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onProgressChangedWithProgress:)]) {
        [self.webViewDelegate jsWebView:self onProgressChangedWithProgress:100];
    }
    
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onReceivedErrorWithErrorCode:des:url:)]) {
        [self.webViewDelegate jsWebView:self onReceivedErrorWithErrorCode:(int)[error code] des:[error description] url:[[webView URL] absoluteString]];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onProgressChangedWithProgress:)]) {
        [self.webViewDelegate jsWebView:self onProgressChangedWithProgress:100];
    }
    
    if (self.webViewDelegate && [self.webViewDelegate respondsToSelector:@selector(jsWebView:onReceivedErrorWithErrorCode:des:url:)]) {
        [self.webViewDelegate jsWebView:self onReceivedErrorWithErrorCode:(int)[error code] des:[error description] url:[[webView URL] absoluteString]];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void(^)(WKNavigationActionPolicy))decisionHandler {
    if (webView != self.realWebView) {
        return;
    }
    
    NSURL *url = navigationAction.request.URL;
    NSString *urlStr = url.absoluteString;
    
    // 增加电话识别
    NSString *scheme = [url scheme];
    if ([scheme isEqualToString:@"tel"]) {
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    
    if ([urlStr rangeOfString:@"ekwing:abc"].length > 0 || [urlStr rangeOfString:@"ekwing:jsExam"].length > 0) {
        [self handleLocalEvent:urlStr];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

// 弹窗
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIViewController *parentVC = [EKJSTool priFindViewController:self];
    if (parentVC) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler();
        }])];
        
        [parentVC presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    
    
    UIViewController *parentVC = [EKJSTool priFindViewController:self];
    if (parentVC) {
        [parentVC presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    UIViewController *parentVC = [EKJSTool priFindViewController:self];
    if (parentVC) {
        [parentVC presentViewController:alertController animated:YES completion:nil];
    }
}

#ifdef DEBUG

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *card = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, card);
    }
}

#endif

#pragma mark -  如果没有找到方法 去realWebView 中调用
- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL hasResponds = [super respondsToSelector:aSelector];
    if (hasResponds == NO) {
        hasResponds = [self.realWebView respondsToSelector:aSelector];
    }
    
    return hasResponds;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature* methodSign = [super methodSignatureForSelector:selector];
    if (methodSign == nil) {
        if ([self.realWebView respondsToSelector:selector]) {
            methodSign = [self.realWebView methodSignatureForSelector:selector];
        }
    }
    
    return methodSign;
}

- (void)forwardInvocation:(NSInvocation*)invocation {
    if ([self.realWebView respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.realWebView];
    } else {
        [invocation invokeWithTarget:self.webViewDelegate];
    }
}

#pragma mark - private UI

- (UIWebView *)initialUIWebView {
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.bounds];
    webView.backgroundColor = [UIColor clearColor];
    webView.allowsInlineMediaPlayback = YES;
    webView.mediaPlaybackRequiresUserAction = NO;
    webView.scrollView.bounces = NO;
    if (@available(iOS 11.0, *)) {
        webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    webView.opaque = NO;
    for (UIView* subview in [webView.scrollView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            ((UIImageView*)subview).image = nil;
            subview.backgroundColor = [UIColor clearColor];
        }
    }
    webView.delegate = self;
    
    return webView;
}

- (WKWebView *)initialWKWebView {
    WKWebViewConfiguration* configuration = [[NSClassFromString(@"WKWebViewConfiguration") alloc] init];
    configuration.userContentController = [NSClassFromString(@"WKUserContentController") new];
    configuration.processPool = [EKJSWebView singleWkProcessPool];//Fix local storage issue
    configuration.allowsInlineMediaPlayback = YES;
    configuration.mediaPlaybackRequiresUserAction = NO;
    
    WKPreferences* preferences = [NSClassFromString(@"WKPreferences") new];
    preferences.javaScriptCanOpenWindowsAutomatically = YES;
    preferences.javaScriptEnabled = YES;
    
    configuration.preferences = preferences;
    
    WKWebView* webView = [[NSClassFromString(@"WKWebView") alloc] initWithFrame:self.bounds configuration:configuration];
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    webView.scrollView.bounces = NO;
    
    if (@available(iOS 11.0, *)) {
        webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    webView.backgroundColor = [UIColor clearColor];
    webView.opaque = NO;
    
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    return webView;
}

#pragma mark - Private method

- (void)handleLocalEvent:(NSString *)longUrl {
    if (self.jsToLocalDelegate) {
        NSString *backUrl = [longUrl decodeFromPercentEscapeString];
        NSRange range = [backUrl rangeOfString:@"?"];
        if (range.location < backUrl.length - 1) {
            NSString *string = [backUrl substringFromIndex:range.location + 1];
            id dataJson = [string JSONToObject];
            NSString *event = [dataJson objectForKey:@"event"];
            if (event && event.length > 0) {
                id params = [dataJson objectForKey:@"params"];
                //调用交互事件
                if ([self.jsToLocalDelegate respondsToSelector: @selector(jsWebView:customizedLocalEvent:data:)]) {
                    [self.jsToLocalDelegate jsWebView:self customizedLocalEvent:event data:params];
                }
            }
        }
    }
}

- (void)showSource {
    if (self.jsToLocalDelegate) {
        [self evaluateJavaScript:@"document.body.innerHTML" block:^(id data) {
            if ([data isKindOfClass:[NSString class]]) {
                id ret = [EKJsonParser parse:data];
                if ([ret isKindOfClass:[Status1Message class]]) {
                    Status1Message *resp = (Status1Message *)ret;
                    NSString *respStr = [EKJsonBuilder toJsonString:resp];
                    if ([self.jsToLocalDelegate respondsToSelector: @selector(jsWebView:customizedLocalEvent:data:)]) {
                        [self.jsToLocalDelegate jsWebView:self customizedLocalEvent:@"html_failure" data:respStr];
                    }
                }
            }
        }];
    }
}

+ (WKProcessPool *)singleWkProcessPool {
    static dispatch_once_t onceToken;
    static WKProcessPool *onceOjb = nil;
    dispatch_once(&onceToken, ^{
        onceOjb = [[WKProcessPool alloc] init];
    });
    
    return onceOjb;
}

#warning -todo-
//支付成功后js回调 界面刷新
- (void)reloadWebViewFunc:(NSNotification *)notice {
    if (_noticeReload) {
        [self reload];
    }
}

@end
