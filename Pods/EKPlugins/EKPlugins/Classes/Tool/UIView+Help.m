//
//  Plugins+Helper.m
//  KFramework
//
//  Created by Kv.h on 12-8-25.
//  Copyright (c) 2012年 Kv.h. All rights reserved.
//

#import "UIView+Help.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "UIColor+Help.h"

#pragma mark - image
@implementation UIView (image)

- (UIImage *)js_viewImage {
    @autoreleasepool {
        
        UIScreen *screen = [UIScreen mainScreen];
        CGFloat scale = 1.0;
        if ([screen respondsToSelector:@selector(scale)]) {
            
            scale = [screen scale];
        }
        
        CGSize size = self.frame.size;
        size.width *= scale;
        size.height *= scale;
        
        UIGraphicsBeginImageContext(size);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) {
            
            UIGraphicsEndImageContext();
            return nil;
        }
        
        CGContextSaveGState(context);
        CGContextScaleCTM(context, scale, scale);
        [self.layer renderInContext:context];
        CGContextRestoreGState(context);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (scale > 1) {
            
            image = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
            
        } else {
            
            image = [[UIImage alloc] initWithCGImage:image.CGImage];
        }
        return image;
    }
}

@end

#pragma mark - loading
@implementation UIView (loading)

static char pri_loadViewKey;
static char pri_activityViewKey;
static char pri_failPageKey;
static char pri_failPageClickKey;

- (void)js_view_startWaiting {
    if (!self.load_View) {
        
        self.load_View = [[UIView alloc] init];
        self.load_View.frame = CGRectMake(0, 0, 100.0, 100.0);
        self.load_View.backgroundColor = [UIColor clearColor];
        
        if (!self.activity_view) {
            self.activity_view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.activity_view.frame = CGRectMake(0, 0, 24, 24);
            self.activity_view.center = CGPointMake(self.load_View.bounds.size.width/2.0, self.load_View.bounds.size.height/2.0);
        }
        
        UILabel *tipLabel =  [[UILabel alloc] init];
        tipLabel.frame = CGRectMake(14.0, CGRectGetMaxY(self.activity_view.frame)+8, 80.0, 20.0);
        tipLabel.textAlignment = NSTextAlignmentCenter;
        tipLabel.font = [UIFont systemFontOfSize:13.0];
        tipLabel.textColor = [UIColor js_colorWithHex:@"999999"];
        tipLabel.text = @"正在加载...";
        [self.load_View addSubview:tipLabel];
    }
    
    [self js_view_removeFailPage];
    
    [self.activity_view startAnimating];
    [self.load_View addSubview:self.activity_view];
    
    self.load_View.center = CGPointMake(self.bounds.size.width/2.0, self.bounds.size.height/2.0-20);
    [self addSubview:self.load_View];
}

- (void)js_view_stopWaiting {
    if (self.load_View) {
        
        [self.activity_view stopAnimating];
        [self.load_View removeFromSuperview];
    }
}

- (void)priview_loadFailPage:(UIImage *) failImage imageOffset:(CGPoint) offset tip:(NSAttributedString *) tipString click:(void(^)(void))clickBlock {
    
    if (!self.fail_View) {
        self.fail_View = [[UIView alloc] init];
        self.fail_View.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        self.fail_View.backgroundColor = [UIColor whiteColor];
        self.fail_View.userInteractionEnabled = YES;
        
        UIImageView *failView = [[UIImageView alloc] init];
        failView.frame = CGRectMake(0, 0, failImage.size.width, failImage.size.height);
        failView.image = failImage;
        failView.userInteractionEnabled = YES;
        failView.center = CGPointMake(self.fail_View.bounds.size.width/2.0+offset.x, self.fail_View.bounds.size.height/2.0+offset.y);
        [self.fail_View addSubview:failView];
        
        if (tipString != nil) {
            CGPoint oldCenter = failView.center;
            failView.center = CGPointMake(oldCenter.x, oldCenter.y-20.0);
            
            UILabel *tipLabel =  [[UILabel alloc] init];
            tipLabel.frame = CGRectMake(0, CGRectGetMaxY(failView.frame)+10, self.fail_View.bounds.size.width, 60.0);
            tipLabel.textAlignment = NSTextAlignmentCenter;
            tipLabel.numberOfLines = 0;
            tipLabel.attributedText = tipString;
            [self.fail_View addSubview:tipLabel];
        }
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onFailPageTap:)];
        [self.fail_View addGestureRecognizer:tapGesture];
    }
    
    [self js_view_stopWaiting];
    
    if (clickBlock) {
        self.failClick_Block = [clickBlock copy];
    }
    
    self.fail_View.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self addSubview:self.fail_View];
}

- (void)priView_loadFailPage:(UIImage *) failImage tip:(NSAttributedString *) tipString click:(void(^)(void))clickBlock {
    [self priview_loadFailPage:failImage imageOffset:CGPointZero tip:tipString click:clickBlock];
}

- (void)js_view_loadFailPage:(void(^)(void))clickBlock {
    NSString *tip = @"加载失败\n 轻触屏幕重新加载";
    
    NSMutableAttributedString *mutAtt = [[NSMutableAttributedString alloc] initWithString:tip];
    
    [mutAtt addAttribute:NSForegroundColorAttributeName
                   value:[UIColor js_colorWithHex:@"cccccc"]
                   range:NSMakeRange(0, mutAtt.length)];
    [mutAtt addAttribute:NSFontAttributeName
                   value:[UIFont systemFontOfSize:15]
                   range:NSMakeRange(0, mutAtt.length)];
    
    UIImage *fImage = [UIImage imageNamed:@"ekw_fail_image"];
    
    
    [self priView_loadFailPage:fImage tip:mutAtt click:clickBlock];
}

- (void)js_view_removeFailPage {
    if (self.fail_View) {
        [self.fail_View removeFromSuperview];
        self.failClick_Block = nil;
    }
}

#pragma mark -- event

- (void)onFailPageTap:(UIGestureRecognizer *) gesture {
    if (self.failClick_Block) {
        self.failClick_Block();
    }
}

#pragma mark -- get

- (UIView *)load_View {
    return objc_getAssociatedObject(self, &pri_loadViewKey);
}

- (UIActivityIndicatorView *)activity_view {
    return objc_getAssociatedObject(self, &pri_activityViewKey);
}

- (UIView *)fail_View {
    return objc_getAssociatedObject(self, &pri_failPageKey);
}

- (void(^)(void))failClick_Block {
    return objc_getAssociatedObject(self, &pri_failPageClickKey);
}


#pragma mark -- set

- (void)setLoad_View:(UIView *) view {
    objc_setAssociatedObject(self, &pri_loadViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setActivity_view:(UIActivityIndicatorView *) view {
    objc_setAssociatedObject(self, &pri_activityViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFail_View:(UIView *) view {
    objc_setAssociatedObject(self, &pri_failPageKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setFailClick_Block:(void(^)(void)) failBlock {
    objc_setAssociatedObject(self, &pri_failPageClickKey, failBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


