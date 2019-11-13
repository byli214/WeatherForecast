//
//  EKContactManager.m
//  EKPlugins
//
//  Created by Skye on 2017/10/25.
//  Copyright © 2017年 ekwing. All rights reserved.
//

#import "EKContactManager.h"
#import <AddressBookUI/AddressBookUI.h>
#import <ContactsUI/ContactsUI.h>

#define IOS9_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)

@interface EKContactManager () <CNContactPickerDelegate, ABPeoplePickerNavigationControllerDelegate>

@property (nonatomic, copy) void (^completcion) (NSString *, NSString *);
@property (nonatomic, assign) BOOL isNotFirstVisitContact; //是否App第一次访问通讯录

@end

@implementation EKContactManager

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.isNotFirstVisitContact = [[NSUserDefaults standardUserDefaults] boolForKey:@"isNotFirstVisitContact"];
    }
    
    return self;
}

#pragma mark - Public

- (void)selectContactAtController:(UIViewController *)controller
                      complection:(void (^)(NSString *, NSString *))completcion {
    self.completcion = completcion;

    [self presentToContactVCFromController:controller];
}



#pragma mark - Private

- (void)authorizationAddressBook:(void (^) (BOOL succeed))completion {
    if (IOS9_OR_LATER) {
        CNContactStore *store = [CNContactStore new];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (completion) {
                completion(granted);
            }
        }];
    } else {
        ABAddressBookRef addressBook = ABAddressBookCreate();
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            CFRelease(addressBook);
            if (completion) {
                completion(granted);
            }
        });
    }
}

- (void)requestAddressBookAuthorization:(void (^) (BOOL authorization))completion {
    __block BOOL authorization;
    
    if (IOS9_OR_LATER) {
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        
        if (status == CNAuthorizationStatusNotDetermined) {
            [self authorizationAddressBook:^(BOOL succeed) {
                authorization = succeed;
            }];
        } else if (status == CNAuthorizationStatusAuthorized) {
            authorization = YES;
        } else {
            authorization = NO;
        }
    } else {
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            [self authorizationAddressBook:^(BOOL succeed) {
                authorization = succeed;
            }];
        } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            authorization = YES;
        } else {
            authorization = NO;
        }
    }
    
    if (completion) {
        completion(authorization);
    }
}

- (void)presentToContactVCFromController:(UIViewController *)controller {
    if (IOS9_OR_LATER) {
        CNContactPickerViewController *pc = [[CNContactPickerViewController alloc] init];
        pc.delegate = self;
        
        pc.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
        
        [self requestAddressBookAuthorization:^(BOOL authorization) {
            if (authorization) {
                [controller presentViewController:pc animated:YES completion:nil];
           } else {
                [self showPermissionAlert];
            }
        }];
    } else {
        ABPeoplePickerNavigationController *pvc = [[ABPeoplePickerNavigationController alloc] init];
        pvc.displayedProperties = @[@(kABPersonPhoneProperty)];
        
        pvc.peoplePickerDelegate = self;
        
        [self requestAddressBookAuthorization:^(BOOL authorization) {
            
            if (authorization) {
                [controller presentViewController:pvc animated:YES completion:nil];
           } else {
                [self showPermissionAlert];
            }
            
        }];
    }
}

- (void)showPermissionAlert {
    //如果首次刚问通讯录 不弹出该弹窗
    if (!self.isNotFirstVisitContact){
        self.isNotFirstVisitContact = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isNotFirstVisitContact"];
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:@"您的通讯录暂未允许访问，请去设置->隐私里面授权!" delegate:self cancelButtonTitle:nil otherButtonTitles:@"确定", nil];
    [alert show];
}

#pragma mark - ABPeoplePickerNavigationControllerDelegate  iOS8 - iOS9

- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
                         didSelectPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier {
    [self getUserNameAndPhoneWithSelectPerson:person identifier:identifier];
    
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}

//iOS8之前 未调试
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    [self getUserNameAndPhoneWithSelectPerson:person identifier:identifier];
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];

    return YES;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    if (self.completcion) {
        self.completcion(nil, nil);
    }
}

#pragma mark - private

- (void)getUserNameAndPhoneWithSelectPerson:(ABRecordRef)person
                                identifier:(ABMultiValueIdentifier)identifier {
    NSString *name = CFBridgingRelease(ABRecordCopyCompositeName(person));
    
    ABMultiValueRef multi = ABRecordCopyValue(person, kABPersonPhoneProperty);
    long index = ABMultiValueGetIndexForIdentifier(multi, identifier);
    NSString *phone = CFBridgingRelease(ABMultiValueCopyValueAtIndex(multi, index));
    CFRelease(multi);
    
    if (self.completcion) {
        self.completcion(name, phone);
    }
}

#pragma mark - CNContactPickerDelegate iOS9以后

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContactProperty:(CNContactProperty *)contactProperty {
    CNContact *contact = contactProperty.contact;
    NSString *name = [CNContactFormatter stringFromContact:contact style:CNContactFormatterStyleFullName];
    CNPhoneNumber *phoneValue= contactProperty.value;
    NSString *phoneNumber = phoneValue.stringValue;
    
    if (self.completcion) {
        self.completcion(name, phoneNumber);
    }
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
    if (self.completcion) {
        self.completcion(nil, nil);
    }
}


@end
