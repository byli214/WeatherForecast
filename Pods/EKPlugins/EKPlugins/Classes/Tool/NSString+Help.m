//
//  NSString+Help.m
//  EKPlugins
//
//  Created by Skye on 2018/12/24.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import "NSString+Help.h"

#pragma mark - json

@implementation NSString (Json)

- (id) JSONToObject {
    id jsonId = nil;
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    jsonId = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves| NSJSONReadingAllowFragments error:nil];
    return jsonId;
}

@end

#pragma mark - 手机号验证

@implementation NSString (TelPhone)

//以1 开头的11位 手机号验证
- (BOOL)isTelephone {
    NSString *regex = @"^1[0-9]{10}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    
    return [predicate evaluateWithObject:self];
}

//严格的手机号验证 （从学生除移植过来）
- (BOOL)idTelephoneInStrict {
    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188  //@"^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";
     * 联通：130,131,132,152,155,156,185,186
     * 电信：133,1349,153,180,189
     */
    NSString * MOBILE = @"^1(3[0-9]|5[0-35-9]|8[029])\\d{8}$";
    /**
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188  //@"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$"
     12         */
    NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$";
    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,152,155,156,185,186   //@"^1(3[0-2]|5[256]|8[56])\\d{8}$"
     17         */
    NSString * CU = @"^1(3[0-2]|5[256]|8[6])\\d{8}$";
    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,180,189   @"^1((33|53|8[09])[0-9]|349)\\d{7}$"
     22         */
    NSString * CT = @"^1((33|53|8[039])[0-9]|349)\\d{7}$";
    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
    // NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
    
    MOBILE = @"^1\\d{10}$";
    CM = @"^1\\d{10}$";
    CU = @"^1\\d{10}$";
    CT = @"^1\\d{10}$";
    
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    
    if (([regextestmobile evaluateWithObject:self] == YES)
        || ([regextestcm evaluateWithObject:self] == YES)
        || ([regextestct evaluateWithObject:self] == YES)
        || ([regextestcu evaluateWithObject:self] == YES)) {
        return YES;
    } else {
        return NO;
    }
}

@end

#pragma mark - url

@implementation NSString (Url)

- (BOOL)isUrlEqual:(NSString *)url {
    NSString *decodedSelf = [self decodeFromPercentEscapeString];
    NSString *decodedOther = [url decodeFromPercentEscapeString];
    
    return [decodedSelf isEqualToString:decodedOther];
}

- (NSString *)decodeFromPercentEscapeString {
    //此处移除了对+号的判断，并且替换了方法：stringByRemovingPercentEncoding（旧方法已废弃）
    return [self stringByRemovingPercentEncoding];
}

- (NSString *)percentEncoding {
    NSString *charactersToEscape = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
    return [self stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
}

- (NSURL *)getUrl {
    if ([self containsString:@"http"]) {
        return [NSURL URLWithString:self];
    }
    
    return [NSURL fileURLWithPath:self];
}

@end
