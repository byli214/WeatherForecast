//
//  UIView+Help.h
//  KFramework
//
//  Created by Kv.h on 12-8-25.
//  Copyright (c) 2012年 Kv.h. All rights reserved.
//

#import <UIKit/UIKit.h>

//截屏
@interface UIView (iamge)

- (UIImage *)js_viewImage;

@end

//默认加载动画
@interface UIView (loading)

- (void)js_view_startWaiting;
- (void)js_view_stopWaiting;
- (void)js_view_removeFailPage;
- (void)js_view_loadFailPage:(void(^)(void))clickBlock;

@end
