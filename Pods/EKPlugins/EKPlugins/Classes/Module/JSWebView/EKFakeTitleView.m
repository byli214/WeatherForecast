//
//  EKFakeTitleView.m
//  EKWTeacher
//
//  Created by Skye on 2019/3/19.
//  Copyright © 2019年 ekwing. All rights reserved.
//

#import "EKFakeTitleView.h"
#import "EKJSTool.h"


@implementation EKFakeTitleView

#pragma mark - life

- (instancetype)init{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat titleHeight = CGRectGetHeight(self.frame)>44 ? 44 : CGRectGetHeight(self.frame);
    self.leftBtn.frame = CGRectMake(20, (CGRectGetHeight(self.frame) - titleHeight)/2.0, 40, titleHeight);
    CGFloat titleH = titleHeight, titleW = CGRectGetWidth(self.frame) - 160;
    self.titleLbl.frame = CGRectMake(80, (CGRectGetHeight(self.frame) - titleH)/2.0, titleW, titleHeight);
}

#pragma mark - public

+ (EKFakeTitleView *)getFakeTitle:(UIStatusBarStyle)statusBarStyle
                         pushType:(NSString *)pushType
                            title:(NSString *)title
                           target:(nullable id)target
                           action:(SEL)action {
    EKFakeTitleView * fakeView = [[EKFakeTitleView alloc] init];
    UILabel *titleLbl = fakeView.titleLbl;
    titleLbl.textColor = statusBarStyle == UIStatusBarStyleLightContent ? [UIColor whiteColor] : [UIColor blackColor];

    [fakeView addSubview:titleLbl];
    titleLbl.text = title;
    [fakeView addSubview:titleLbl];
    
    UIButton *leftBtn = [EKJSTool priGainLeftButtonWithPushType:pushType statusBarStyle:statusBarStyle target:target action:action];
    leftBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    fakeView.leftBtn = leftBtn;
    [fakeView addSubview:leftBtn];
    
    return fakeView;
}

#pragma mark - lazy

- (UILabel *)titleLbl {
    if (nil == _titleLbl) {
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 1;
        label.textAlignment = NSTextAlignmentCenter;
        _titleLbl = label;
    }

    return _titleLbl;
}

@end
