//
//  EKContactManager.h
//  EKPlugins
//
//  Created by Skye on 2017/10/25.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EKContactManager : NSObject

/**
 * 请求授权
 * @param completion 回调
 */
- (void)requestAddressBookAuthorization:(void (^) (BOOL authorization))completion;

/**
 * 选择联系人
 * @param controller 控制器
 * @param completcion 回调
 */
- (void)selectContactAtController:(UIViewController *)controller
                      complection:(void (^)(NSString *name, NSString *phone))completcion;

@end
