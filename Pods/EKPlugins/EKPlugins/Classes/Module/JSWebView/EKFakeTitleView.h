//
//  EKFakeTitleView.h
//  EKWTeacher
//
//  Created by Skye on 2019/3/19.
//  Copyright © 2019年 ekwing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EKFakeTitleView : UIView
///标题
@property (nonatomic, strong) UILabel *titleLbl;
//返回按钮
@property (nonatomic, strong) UIButton *leftBtn;

/**
 * 使用初始值，快速创建一个titleBar
 * @param statusBarStyle 状态的style
 * @param pushType 切入该页面的方式（左右切换为< ，上下切换为✘）
 * @param title 标题的文字
 * @param target 返回按钮的target
 * @param action 返回按钮的action
 */
+ (EKFakeTitleView *)getFakeTitle:(UIStatusBarStyle)statusBarStyle
                         pushType:(NSString *)pushType
                            title:(NSString *)title
                           target:(nullable id)target
                           action:(SEL)action;

@end

