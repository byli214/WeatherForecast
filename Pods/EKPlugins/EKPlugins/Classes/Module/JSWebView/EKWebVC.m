//
//  EKWebVC.m
//  EKPlugins
//
//  Created by chen on 2017/8/31.
//  Copyright © 2017年 ekwing. All rights reserved.
//  JS和app交互通用vc

#import "EKWebVC.h"
#import "EKJSToLocalBridge.h"
#import "NSDictionary+Help.h"
#import "NSString+Help.h"
#import "EKUrlStringSplice.h"
#import "EKJSTool.h"
#import "UIView+Help.h"
#import "EKFakeTitleView.h"

/// 是否是 iPhone X系列
#define isIPhoneXAll UIApplication.sharedApplication.statusBarFrame.size.height == 44
#define _SY_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

@interface EKWebVC ()<IEKJSWebViewDelegate>

#pragma mark - 状态栏
///设置系统状态栏的颜色
@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;

#pragma mark - 导航栏（返回按钮，title）
///导航条颜色
@property (nonatomic, strong) UIColor *fakeTitleBarColor;
///导航栏中间标题
@property (nonatomic, copy) NSString *titleStr;

#pragma mark - webView
@property (nonatomic, copy) NSString *loadedUrl;
@property (nonatomic, assign) BOOL webViewLoading;
@property (nonatomic, assign) BOOL observerAdded;
@property (nonatomic, strong) EKJSToLocalBridge * jsToLocalBridge;

@end

@implementation EKWebVC

#pragma mark - lifecycle
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.observerAdded) {
        [self removeObserver:self forKeyPath:@"webViewLoading"];
        self.observerAdded = NO;
    }
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        //设置初始值
        self.fullScreen = NO; //默认显示状态栏
        self.localTitleBar = NO;//默认导航栏由H5绘制
        self.retainFlag = YES; // 默认会在vc栈保存
        self.needRefresh = NO; //默认页面出现不刷新
        self.webViewLoading = NO;
        self.observerAdded = NO;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //根据data赋值
    [self initParameterWithData];
    
    //根据赋值添加对应的View
    [self customWebVCWithData];
}

//此方法兼容iPad横版中，控件根据view自动布局
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGFloat webMinY = 0;
    CGFloat viewWidth = CGRectGetWidth(self.view.frame);
    if (_fakeStatusBar != nil && _fakeStatusBar.superview != nil && !_fakeStatusBar.hidden) {
        CGFloat height = CGRectGetHeight(self.fakeStatusBar.frame);
        self.fakeStatusBar.frame = CGRectMake(0, 0, viewWidth, height);
        webMinY += height;
    }
    
    if (_fakeTitleBar != nil && _fakeTitleBar.superview != nil && !_fakeTitleBar.hidden) {
        CGFloat height = CGRectGetHeight(self.fakeTitleBar.frame);
        self.fakeTitleBar.frame = CGRectMake(0, webMinY, viewWidth, height);
    }
    
    if (_webView != nil && _webView.superview != nil) {
        CGFloat height = CGRectGetHeight(self.view.frame)-webMinY;
        self.webView.frame = CGRectMake(0, webMinY, viewWidth, height);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //设置导航栏颜色以及状态栏颜色
    [self setNaigationBarAndStatusBarColor];
    
    BOOL hideTitle = !self.localTitleBar;
    [self.navigationController setNavigationBarHidden:hideTitle animated:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:self.fullScreen];
    [self judgeAndRefreshWebView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self addNotificatioin];
    NSDictionary *dic = @{@"type": @"pageJump"};
    [self.jsToLocalBridge toJSWithEvent:nil data:nil callBack:@"jsPageShow" callBackData:dic];
}

//界面将要消失状态栏颜色改回之前值
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //界面消失，添加类型-在viewDidDisappear处理，会出现调用H5的jsPageHide后，H5回调本地时（诸葛IO埋点），VC已被释放
    NSDictionary *dic = @{@"type": @"pageJump"};
    [self.jsToLocalBridge toJSWithEvent:nil data:nil callBack:@"jsPageHide" callBackData:dic];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.jsToLocalBridge onWebViewHide];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 自定义对象
- (EKJSToLocalBridge *)getJSToLocalBridge {
    EKJSToLocalBridge *bridge = [[EKJSToLocalBridge alloc] init];
    //代理可指定为你想让处理相关事件的对象
    bridge.delegate = self;
    bridge.dataSource = self;
    
    return bridge;
}

- (EKJSWebView *)getJSWebView {
    EKJSWebView *webView = [[EKJSWebView alloc] init];
    //指定webView代理的对象
    webView.jsToLocalDelegate = self.jsToLocalBridge;
    webView.webViewDelegate = self;
    
    return webView;
}

- (UIView *)getFakeStatusBar {
    UIView *fakeStatusBar = [[UIView alloc] init];
    fakeStatusBar.backgroundColor = [UIColor whiteColor];
    fakeStatusBar.frame = CGRectMake(0, 0, CGFLOAT_MIN, CGFLOAT_MIN);
    
    return fakeStatusBar;
}

///获取自定义的导航栏
- (UIView *)getFakeTitleBar {
    UIView *fakeTitleBar =  [EKFakeTitleView getFakeTitle:self.statusBarStyle pushType:self.pushType title:self.titleStr target:self action:@selector(onBackButtonClick)];;
    fakeTitleBar.frame = CGRectMake(0, 0, CGFLOAT_MIN, CGFLOAT_MIN);
    fakeTitleBar.backgroundColor = self.fakeTitleBarColor;
    
    return fakeTitleBar;
}

#pragma mark - event
- (void)onBackButtonClick {
    if ([self.pushType isEqualToString: kCATransitionFromRight]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if (self.pushType != nil) {
        NSString *pushType = kCATransitionFromLeft;
        if ([self.pushType isEqualToString: kCATransitionFromLeft]) {
            pushType = kCATransitionFromRight;
        } else if ([self.pushType isEqualToString: kCATransitionFromTop]) {
            pushType = kCATransitionFromBottom;
        } else if ([self.pushType isEqualToString: kCATransitionFromBottom]) {
            pushType = kCATransitionFromTop;
        }
        
        CATransition* transition = [EKJSTool getPushCATransitionWithSubType:pushType type:kCATransitionReveal timingFunctionName:kCAMediaTimingFunctionEaseIn];
        [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
        [self.navigationController popViewControllerAnimated:false];
    } else {
        [self.navigationController popViewControllerAnimated:false];
    }
}

#pragma mark - notification
- (void)enterBackground {
    NSDictionary *dic = @{@"type": @"homeOrLock"};
    [self.jsToLocalBridge toJSWithEvent:nil data:nil callBack:@"jsPageHide" callBackData:dic];
}

- (void)enterForeground {
    NSDictionary *dic = @{@"type": @"homeOrLock"};
    [self.jsToLocalBridge toJSWithEvent:nil data:nil callBack:@"jsPageShow" callBackData:dic];
}

- (void)addNotificatioin {
    //上下拉不影响答题流程，只有home键会调 js action
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

#pragma mark - private

- (void)initParameterWithData {
    //解析JS交互传入的参数赋值
    if (self.data && [self.data isKindOfClass:[NSDictionary class]]) {
        //导航栏相关
        self.titleStr = [self.data js_stringValueForKey:@"title"];
        self.localTitleBar = [self.data js_boolValueForKey:@"localTitleBar" defaultValue:NO];
        self.fullScreen = [self.data js_boolValueForKey:@"fullScreen" defaultValue:NO];
        self.needRefresh = [self.data js_boolValueForKey:@"needRefresh" defaultValue:NO];
        self.retainFlag = [self.data js_boolValueForKey:@"retain" defaultValue:YES];
    }
}

- (void)customWebVCWithData {
    self.fakeTitleBarColor = [self getFakeTitleBarOriginColor];
    
    //H5绘制本地导航栏且 不是全屏 添加自定义状态栏
    if (!self.fullScreen && !self.localTitleBar) {
        [self.view addSubview:self.fakeStatusBar];
        self.fakeStatusBar.backgroundColor = self.fakeTitleBarColor;
        self.fakeStatusBar.frame = CGRectMake(0, 0, 0, [self getFakeStatusBarOriginHeight]);
    }
    
    //初始化titleBar
    [self initTitleBar];
    [self.view addSubview:self.webView];
}

//临时状态栏 已赋值的 > 默认设置
- (CGFloat)getFakeStatusBarOriginHeight {
    CGFloat height = CGRectGetHeight(self.fakeStatusBar.frame);
    
    if (height == CGFLOAT_MIN) {
        //未自定义高度 且 H5绘制导航栏
        if (!self.localTitleBar){
            height = self.fullScreen ? (isIPhoneXAll ? 24 : 0) : (isIPhoneXAll ? 44 : 20);
        } else {
            height = 0;
        }
    }
    
    return height;
}

//页面加载完成
- (void)webViewPageFinishToInvoke:(NSString *) url {
    if (url && ![url isEqualToString:@"about:blank"]) {
        [self.fakeTitleBar setHidden:YES];
        self.loadedUrl = url;
        self.webViewLoading = NO;
    }
}

//页面开始加载
- (void)webViewPageStartToInvoke {
    [self.fakeTitleBar setHidden:NO];
    if (self.fakeTitleBar.superview) {
        [self.view bringSubviewToFront:self.fakeTitleBar];
    }
}

#pragma mark - lazy
- (UIView *)fakeStatusBar {
    if (nil == _fakeStatusBar) {
        _fakeStatusBar = [self getFakeStatusBar];
    }
    
    return _fakeStatusBar;
}
- (UIView *)fakeTitleBar {
    if (nil == _fakeTitleBar) {
        _fakeTitleBar = [self getFakeTitleBar];
    }
    
    return _fakeTitleBar;
}

- (EKJSWebView *)webView {
    if (nil == _webView) {
        _webView = [self getJSWebView];
    }
    
    return _webView;
}

- (EKJSToLocalBridge *)jsToLocalBridge {
    if (nil == _jsToLocalBridge) {
        _jsToLocalBridge = [self getJSToLocalBridge];
    }
    
    return _jsToLocalBridge;
}

#pragma mark - setter/getter
- (void)setFakeTitleBarColor:(UIColor *)fakeTitleBarColor {
    _fakeTitleBarColor = fakeTitleBarColor;
    //记录状态栏的style(浅色、深色)
    self.statusBarStyle = [EKJSTool getStatusBarStyleWithNaviBarColor:self.fakeTitleBarColor];
}

#pragma mark - tool
/**
 * 参数分三类,优先级如下
 * 1. data中传递参数
 * 2. url中已经包含的参数
 * 3. 规定必传的基本参数
 */
- (NSString *)priGainVailedUrlStrWithUrlStr:(NSString *)urlStr dataParagram:(id)dataParagram {
    NSDictionary *dataDic = [dataParagram isKindOfClass:[NSDictionary class]] ? (NSDictionary *)dataParagram : nil;
    NSDictionary *baseDic = [self.jsToLocalBridge getRequestParameters];
    NSMutableDictionary *baseParaDic = [[NSMutableDictionary alloc] initWithDictionary:baseDic];
    [baseParaDic setObject:@"ios" forKey:@"os"];
    [baseParaDic setObject:@"1" forKey:@"isself.http"];
    
    return [EKUrlStringSplice getVailedUrlStrWithBaseUrlStr:urlStr baseParameter:baseParaDic extraParameter:dataDic];
}

//判断是否需要刷新webView,若需要进行刷新
- (void)judgeAndRefreshWebView {
    self.webViewLoading = NO;
    if (self.data && [self.data isKindOfClass:[NSDictionary class]]) {
        NSString *url = [self.data js_stringValueForKey:@"url"];
        if (url && url.length > 4) {
            id dic = [self.data objectForKey:@"data"];
            url = [self priGainVailedUrlStrWithUrlStr:url dataParagram:dic];
        }
        
        if (self.needRefresh) {
            //有回调参数，回调h5
            NSString *refreshCallBack = [self.data js_stringValueForKey:@"refreshCallBack"];
            //self.loadedUrl为nil认为是首次加载，不做回调；如果有值，认为不是首次加载，需要回调
            if (refreshCallBack && refreshCallBack.length > 0 && self.loadedUrl) {
                [self.jsToLocalBridge toJSWithEvent:nil data:nil callBack:refreshCallBack callBackData:@""];
            } else {
                if (url && [url length] > 4) {
                    [self.webView loadURL:url];
                    self.webViewLoading = YES;
                } else {
                    if (self.loadedUrl) {
                        [self.webView reload];
                    } else if (self.url) {
                        [self.webView loadURL:self.url];
                    }
                    self.webViewLoading = YES;
                }
            }
        } else {
            if (url && url.length > 4 && ![url isUrlEqual:self.loadedUrl]) {
                [self.webView loadURL:url];
                self.webViewLoading = YES;
            }
        }
    } else if (self.url && self.url.length > 0) {
        if (!self.webViewLoading && (![self.url isUrlEqual:self.loadedUrl] || self.needRefresh)) {
            [self.webView loadURL:self.url];
            self.webViewLoading = YES;
        }
    }
    
    if (self.loadedUrl) {
        // js通过实现gobackCB实现无差异的局部更新
        [self.jsToLocalBridge toJSWithEvent:nil data:nil callBack:@"gobackCB" callBackData:@""];
    }
}

//刷新webView
- (void)refreshWebView {
    self.webViewLoading = NO;
    NSString *url = nil;
    if (self.data && [self.data isKindOfClass:[NSDictionary class]]) {
        url = [self.data js_stringValueForKey:@"url"];
        if (url && url.length > 4) {
            id dic = [self.data objectForKey:@"data"];
            url = [self priGainVailedUrlStrWithUrlStr:url dataParagram:dic];
        }
    }
    
    if (url && [url length] > 4) {
        [self.webView loadURL:url];
        self.webViewLoading = YES;
    } else if (self.loadedUrl) {
        [self.webView reload];
        self.webViewLoading = YES;
    } else if (self.url) {
        [self.webView loadURL:self.url];
        self.webViewLoading = YES;
    }
}

#pragma mark - Title bar
- (void)initTitleBar {
    if (!self.localTitleBar) {
        [self initFakeTitleBar];
    } else {
        [self initSystemTitleBar];
    }
}

- (void)initSystemTitleBar {
    UIButton *leftButton = [EKJSTool priGainLeftButtonWithPushType:self.pushType statusBarStyle:self.statusBarStyle target:self action:@selector(onBackButtonClick)];
    leftButton.frame = CGRectMake(0, 0, 40.0, 44.0);
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
    self.navigationItem.leftBarButtonItem = backButton;
    
    if (self.titleStr && self.titleStr.length > 0) {
        self.navigationItem.title = self.titleStr;
    }
    
    if (self.fakeTitleBarColor) {
        self.navigationController.navigationBar.barTintColor = self.fakeTitleBarColor;
    }
}

- (void)initFakeTitleBar {
    self.fakeTitleBar.frame = CGRectMake(0, 0, 0, [self getFakeTitleBarOriginHeight]);
    self.fakeTitleBar.backgroundColor = self.fakeTitleBarColor;
    [self.view addSubview:self.fakeTitleBar];
    
    [self addObserver:self forKeyPath:@"webViewLoading" options:NSKeyValueObservingOptionNew context:nil];
    self.observerAdded = YES;
}

//临时导航栏 H5赋值的 > 已赋值的 > 默认设置
- (CGFloat)getFakeTitleBarOriginHeight {
    CGFloat height = CGFLOAT_MIN;
    if ([self.data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dataDic = (NSDictionary *)self.data;
        if ([dataDic.allKeys containsObject:@"titleBarHeight"]) {
            height = [dataDic js_floatValueForKey:@"titleBarHeight" defaultValue:CGFLOAT_MIN];
        }
    }
    //优先使用H5传递的bar的高度
    if (height == CGFLOAT_MIN) {
        height = CGRectGetHeight(self.fakeTitleBar.frame);
        height = (height != CGFLOAT_MIN) ? height : (self.localTitleBar ? 0 : [self navBarHeight]);
    }
    
    return height;
}

//H5传递的 > 已赋值的 > 默认设置
- (UIColor *)getFakeTitleBarOriginColor {
    UIColor *color = nil;
    //H5设置了颜色
    if (self.data && [self.data isKindOfClass:[NSDictionary class]]) {
        id colorObj = [self.data objectForKey:@"naviBarColor"];
        if ([colorObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *colorDic = (NSDictionary *)colorObj;
            color = [EKJSTool colorFromRGBColorDic:colorDic];
        }
    }
    if (!color) {
        //自定义的颜色
        color = self.fakeTitleBar.backgroundColor;
        color = color ? color : UIColor.whiteColor;
    }
    
    return color;
}

//设置系统导航栏颜色
- (void)setNaigationBarAndStatusBarColor {
    if (nil == self.fakeTitleBarColor) { return; }
    if (!self.fullScreen) {
        [UIView animateWithDuration:0.25 animations:^{
            if (self.fakeStatusBar) {
                self.fakeStatusBar.backgroundColor = self.fakeTitleBarColor;
            } else {
                self.navigationController.navigationBar.barTintColor = self.fakeTitleBarColor;
            }
        }];
    } else {
        self.view.backgroundColor = self.fakeTitleBarColor;
    }
    //改变导航栏字体的颜色/状态栏的颜色
    NSDictionary *titleAttrDic = nil;
    UIFont *titleFont = [UIFont systemFontOfSize:18.0];
    if (self.statusBarStyle == UIStatusBarStyleLightContent) {
        UIColor *titleColor = [UIColor whiteColor];
        titleAttrDic = [NSDictionary dictionaryWithObjectsAndKeys:titleColor, NSForegroundColorAttributeName, titleFont, NSFontAttributeName, nil];
    } else {
        UIColor *titleColor = [UIColor blackColor];
        titleAttrDic = [NSDictionary dictionaryWithObjectsAndKeys:titleColor, NSForegroundColorAttributeName, titleFont, NSFontAttributeName, nil];
    }
    
    self.navigationController.navigationBar.titleTextAttributes = titleAttrDic;
    [[UIApplication sharedApplication] setStatusBarStyle:self.statusBarStyle];
}

- (CGFloat)navBarHeight {
    return self.navigationController.navigationBar ? self.navigationController.navigationBar.bounds.size.height : (isIPhoneXAll ? 64.0 : 44.0);
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"webViewLoading"]) {
        BOOL v = [change[NSKeyValueChangeNewKey] boolValue];
        if (!self.localTitleBar && self.fakeTitleBar) {
            [self.fakeTitleBar setHidden:!v];
        }
    } else {
        [self willChangeValueForKey:keyPath];
        [self didChangeValueForKey:keyPath];
    }
}

#pragma mark - IEKJSWebViewDelegate
- (void)jsWebView:(EKJSWebView *)jsWebView onPageFinishedWithUrl:(NSString *)url {
    [self webViewPageFinishToInvoke:url];
}

- (void)jsWebView:(EKJSWebView *)jsWebView onPageStartedWithUrl:(NSString *)url{
    [self webViewPageStartToInvoke];
}

- (void)jsWebView:(EKJSWebView *)jsWebView onReceivedErrorWithErrorCode:(int)errorCode des:(NSString *)description url:(NSString *)failingUrl {
    //加载失败子类实现，实现后调用super此方法
    if (self.fakeTitleBar.superview) {
        self.fakeTitleBar.hidden = NO;
        [self.view bringSubviewToFront:self.fakeTitleBar];
    }
}

- (void)jsWebView:(EKJSWebView *)jsWebView onProgressChangedWithProgress:(int)progressInPercent {}

#pragma mark -  IEKJSToLocalBridgeDelegate

//setNaviBar 回调
- (void)localBridge:(EKJSToLocalBridge *)localBridge changeStatusBarColor:(NSDictionary *)colorDic {
    if (colorDic) {
        UIColor *color = [EKJSTool colorFromRGBColorDic:colorDic];
        self.fakeTitleBarColor = color;
        [self setNaigationBarAndStatusBarColor];
    }
}

//goback 回调
- (void)gobackInLocalBridge:(EKJSToLocalBridge *)localBridge {
    [self onBackButtonClick];
}

//changeOpenViewData回调
-(void)localBridge:(EKJSToLocalBridge *)localBridge changeOpenViewDataWithJsonDic:(NSDictionary *)jsonDic {
    if (self.data && [self.data isKindOfClass:[NSDictionary class]]) {
        //原始data
        NSDictionary *origDataDic = (NSDictionary *)self.data;
        id origParagram = self.data[@"data"];
        NSDictionary *origParagramDic = [origParagram isKindOfClass:[NSDictionary class]] ? (NSDictionary *)origParagram : nil;
        
        //新data
        NSString *url = [jsonDic js_stringValueForKey:@"url"];
        id jsonParagram = [jsonDic objectForKey:@"data"];
        NSDictionary *jsonParagramDic = [jsonParagram isKindOfClass:[NSDictionary class]] ? (NSDictionary *)jsonParagram : nil;
        
        //存放新的数据
        //参数
        NSMutableDictionary *newParagramDic = [[NSMutableDictionary alloc] init];
        if (origParagramDic) {
            [newParagramDic addEntriesFromDictionary:origParagramDic];
        }
        
        if (jsonParagramDic) {
            [newParagramDic addEntriesFromDictionary:jsonParagramDic];
        }
        //data
        NSMutableDictionary *newDic = [[NSMutableDictionary alloc] init];
        if (origDataDic) {
            [newDic addEntriesFromDictionary:origDataDic];
        }
        
        //更换url
        if (nil != url) {
            [newDic setObject:url forKey:@"url"];
        }
        
        [newDic setObject:newParagramDic forKey:@"data"];
        
        self.data = newDic;
    }
}

#pragma mark - IEKJSToLocalBridgeDataSource

//获取 openView  打开相册 等 跳转依赖的VC
- (UINavigationController *)naviForOpenViewInLocalBridge:(EKJSToLocalBridge *)localBridge {
    return self.navigationController;
}

//bridge
- (UIViewController * _Nullable)vcInLocalBridge:(EKJSToLocalBridge * _Nonnull)localBridge {
    return self;
}

//移除历史的VC
- (UINavigationController *)naviForRemoveHistoryInLocalBridge:(EKJSToLocalBridge *)localBridge {
    return self.navigationController;
}

- (NSString *)newVCClassNameForOpenViewInLocalBridge:(EKJSToLocalBridge *)localBridge {
    return NSStringFromClass(self.class);
}

- (NSString *)localBridge:(EKJSToLocalBridge *)localBridge getErrorStrOnProxyFailed:(NSString *)url result:(NSString *)resultString httpCode:(int)code {
    return nil;
}

@end
