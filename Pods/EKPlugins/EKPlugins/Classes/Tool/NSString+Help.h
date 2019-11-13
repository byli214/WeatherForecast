//
//  NSString+Help.h
//  EKPlugins
//
//  Created by Skye on 2018/12/24.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Json)

- (id)JSONToObject;

@end

@interface NSString (TelPhone)

///以1 开头的11位 手机号验证
- (BOOL)isTelephone;

///严格的手机号验证
- (BOOL)idTelephoneInStrict;

@end

@interface NSString (Url)

- (BOOL)isUrlEqual:(NSString *)url;
- (NSString *)decodeFromPercentEscapeString;
//@"?!@#$^&%*+,:;='\"`<>()[]{}/\\| "
- (NSString *)percentEncoding;
- (NSURL *)getUrl;

@end;
