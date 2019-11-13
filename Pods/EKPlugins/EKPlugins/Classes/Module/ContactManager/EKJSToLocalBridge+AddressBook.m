//
//  EKJSToLocalBridge+AddressBook.m
//  AFNetworking
//
//  Created by 王亚娟 on 2019/9/23.
//

#import "EKJSToLocalBridge+AddressBook.h"
#import "NSDictionary+Help.h"
#import "EKSysInfoData.h"
#import "EKContactManager.h"
#import "NSString+Help.h"
#import "JSAmasBaseUtils.h"
#import "EKJSWebView.h"
#import <objc/runtime.h>

static char EKJSToLocalBridge_ContactManager;

@implementation EKJSToLocalBridge (AddressBook)
    
@dynamic contactManager;

- (void)setContactManager:(EKContactManager *)contactManager {
    objc_setAssociatedObject(self, &EKJSToLocalBridge_ContactManager, contactManager, OBJC_ASSOCIATION_RETAIN);
}
    
- (EKContactManager *)contactManager {
    return objc_getAssociatedObject(self, &EKJSToLocalBridge_ContactManager);
}
    
    //调起通讯录
- (BOOL)jsWebView:(EKJSWebView *)jsWebView addressBookActionWithJsonDic:(NSDictionary *)jsonDic {
    NSString *callBack = [jsonDic js_stringValueForKey:@"callBack"];
    __weak typeof(self) weakSelf = self;
    
    UIViewController *vc = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(vcInLocalBridge:)]) {
        vc = [self.dataSource vcInLocalBridge:self];
    }
    if (!vc) {
        NSLog(@"没有返回有效的可供跳转的VC");
        return true;
    }
    
    if (!self.contactManager) {
        self.contactManager = [[EKContactManager alloc] init];
    }
    
    [self.contactManager selectContactAtController:vc complection:^(NSString *name, NSString *phone) {
        NSString *phone2 = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
        phone2 = [phone2 stringByReplacingOccurrencesOfString:@"(" withString:@""];
        phone2 = [phone2 stringByReplacingOccurrencesOfString:@")" withString:@""];
        phone2 = [phone2 stringByReplacingOccurrencesOfString:@">" withString:@""];
        phone2 = [phone2 stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%c",32] withString:@""];
        phone2 = [phone2 stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%c",160] withString:@""];
        NSMutableString *phone3 = [NSMutableString string];
        for (int i = 0; i < phone2.length; i++) {
            int asciiCode = [phone2 characterAtIndex:i];
            if (asciiCode != 160) {
                [phone3 appendString:[NSString stringWithFormat:@"%c", asciiCode]];
            }
        }
        //手机号验证
        if (callBack != nil && callBack.length > 0) {
            if (phone3 != nil && phone3.length > 0 && name != nil && name.length > 0) {
                BOOL isTelPhone = [phone3 isTelephone];
                NSDictionary *callBackDic = @{@"number": ( isTelPhone ? [phone3 copy] : @""), @"userName": name};
                [weakSelf toJSWithEvent:@"addressBook" data:jsonDic callBack:callBack callBackData:callBackDic];
            } else {
                [weakSelf toJSWithEvent:@"addressBook" data:jsonDic callBack:callBack callBackData:@""];
            }
        }
    }];
    
    return true;
}
    
    @end
