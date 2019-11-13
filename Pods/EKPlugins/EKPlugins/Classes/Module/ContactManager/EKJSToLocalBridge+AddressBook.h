//
//  EKJSToLocalBridge+AddressBook.h
//  AFNetworking
//
//  Created by 王亚娟 on 2019/9/23.
//

#import <EKPlugins/EKPlugins.h>
@class EKContactManager;

@interface EKJSToLocalBridge (AddressBook)
    
///通讯录访问
@property (nonatomic, strong, readonly) EKContactManager *contactManager;
    
@end
