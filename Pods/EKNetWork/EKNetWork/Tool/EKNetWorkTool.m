//
//  EKNetWorkTool.m
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKNetWorkTool.h"
#import "GTMBase64.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import "RegExCategories.h"

static NSString *const ALL_CHAR = @"qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM";
static NSString *const ALL_CHAR_NUM = @"0123456789qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM";

@implementation EKNetWorkTool

//
+ (NSString *)getMD5WithString:(NSString *)string
{
    if (self == nil || [string length] == 0) return nil;
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (uint32_t)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++) {
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    return outputString;
}

+ (NSString *)deleteTempKeyWithMediaPath:(NSString *)filePath
{
    NSString *tmpPath = filePath;
    NSRange tmpKeyRange = [tmpPath rangeOfString:@"__&&__"];
    if (tmpKeyRange.location == NSNotFound) {
        return tmpPath;
    }
    return [tmpPath stringByReplacingCharactersInRange:tmpKeyRange withString:@""];
}

+ (NSString *)appendTempKeyWithMediaPath:(NSString *)filePath
{
    NSString *tmpPath = filePath;
    NSRange tmpKeyRange = [tmpPath rangeOfString:@"__&&__"];
    if (tmpKeyRange.location != NSNotFound) {
        return tmpPath;
    }
    
    return [tmpPath stringByAppendingString:@"__&&__"];
}

+ (NSString *)getMediaFileNameWithUrl:(NSString *)url
{
    //删除扩展名后的url，进行md5
    return [self getMD5WithString:url.stringByDeletingPathExtension];
}

+ (BOOL)resonseEnableByRangeDownload:(NSURLResponse *)resonse
{
    BOOL enable = NO;
    if ([resonse isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSDictionary *allHeader = ((NSHTTPURLResponse *)resonse).allHeaderFields;
        NSString *acceptRangeKey = allHeader[@"Accept-Ranges"];
        NSString *contentRangeKey = allHeader[@"Content-Range"];
        if ([acceptRangeKey containsString:@"bytes"] || contentRangeKey.length > 0)
        {
            enable = YES;
        }
    }
    return enable;
}

+ (int64_t)getContentFileLength:(NSString *)filePath
{
    NSError *fileError;
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&fileError];
    if (fileError != nil) {
        return 0;
    }
    return [fileInfo[@"NSFileSize"] integerValue];
}


/*
 生成规则，
 过期时间+'s'+6位随机字符+1位数字+6位随机字符+1位字母(a-Z)+12位随机字符
 */
+ (NSString *) generatingSHK:(int)expired
{
    NSMutableString *ret = [[NSMutableString alloc] initWithFormat:@"%ds", expired];
    [self appendRandomChar:ret pool:ALL_CHAR count:6];
    int singleNum = arc4random_uniform(10);
    [ret appendFormat:@"%d", singleNum];
    [self appendRandomChar:ret pool:ALL_CHAR count:6];
    char c = [self randomCharWith:singleNum];
    [ret appendFormat:@"%c", c];
    [self appendRandomChar:ret pool:ALL_CHAR_NUM count:12];
    
    return ret;
}

+ (void) appendRandomChar:(NSMutableString *)target pool:(NSString *)pool count:(int)num
{
    u_int32_t length = (u_int32_t)pool.length;
    for (int i = 0; i < num; i++)
    {
        NSUInteger index = arc4random_uniform(length);
        [target appendFormat:@"%c", [pool characterAtIndex:index]];
    }
}

+ (char) randomCharWith:(int)num
{
    int base = num + 48; // '0' = 48
    char all[5] = {0};
    int index = 0;
    for (int i = 0; i < 8; i++)
    {
        int n = base + i * 10;
        if ([self isChar:n])
        {
            all[index++] = n;
        }
    }
    
    return (char)all[arc4random_uniform(index)];
}

+ (BOOL) isChar:(int)num
{
    return (num >= 'A' && num <= 'Z') || (num >= 'a' && num <= 'z');
}

+ (NSString *) AES128Decrypt:(NSData *)encryptData key:(NSString *)key
{
    char keyPtr[kCCKeySizeAES128 + 1];
    memset(keyPtr, 0, sizeof(keyPtr));
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    char ivPtr[kCCBlockSizeAES128 + 1];
    memset(ivPtr, 0, sizeof(ivPtr));
    
    NSData *data = [GTMBase64 decodeData:encryptData];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    
    size_t numBytesCrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          0x0000,
                                          keyPtr,
                                          kCCBlockSizeAES128,
                                          ivPtr,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesCrypted);
    
    if (cryptStatus == kCCSuccess)
    {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesCrypted freeWhenDone:YES];
        return [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    }
    
    free(buffer);
    return nil;
}

+ (NSString *)changeJsonIntToString:(NSString *)oriJson
{
    // 有html片段不进行替换
    NSRegularExpression *htmlRegex = [[NSRegularExpression alloc] initWithPattern:@"\\\"<!DOCTYPE html>"];
    if ([htmlRegex isMatch:oriJson]) {
        return oriJson;
    }
    
    NSString *numRex = @"(\\-)?(\\d+)(\\.\\d+)?";
    NSString *allRex = @"[^\\]]*";
    
    // 先检索字典中含有int
    // 检索 \":数字[,|}]此类数据，比如：【\":34,】，【\":34}】，【\":-34】等，替换成【\":"34",】，【\":"34"}】，【\":"-34"】
    // 如果再一个字符串中也含有此类特殊数据，也会被替换
    NSString *dicIntRex = [NSString stringWithFormat:@"\\\":(%@)([,\\}])",numRex];
    NSRegularExpression *dicExRex = [[NSRegularExpression alloc] initWithPattern:dicIntRex];
    NSString *newJson = oriJson;
    if ([dicExRex isMatch:oriJson] == YES)
    {
        newJson = [dicExRex replace:oriJson withDetailsBlock:^NSString *(RxMatch *match) {
            
            NSMutableString *marchStr = [match.value mutableCopy];
            [marchStr insertString:@"\"" atIndex:marchStr.length-1];
            [marchStr insertString:@"\"" atIndex:2];
            return marchStr;
        }];
    }
    
    // 检索数组，数组中第一个字符是数字的情况，如果数组中有多个数据类型，并且第一个不是数字，则检索不出来，先检索出数组
    // 检索, [数字, 任意非]字符 ]，比如:【[30, 20]】,【[-10, "hello"]】，替换成 【["30", "20"]】,【["-10", "hello"]】
    NSString *arrayRex = [NSString stringWithFormat:@"\\[%@,(%@)\\]",numRex,allRex];
    NSRegularExpression *arrayExRex = [[NSRegularExpression alloc] initWithPattern:arrayRex];
    
    if ([arrayExRex isMatch:newJson] == NO) {
        return newJson;
    }
    
    NSString *newJson1 = [arrayExRex replace:newJson withDetailsBlock:^NSString *(RxMatch *match) {
        
        // 上面匹配到的是数组中，再检索 【[数字】和【,数字】情况，p
        NSMutableString *marchStr = [match.value mutableCopy];
        NSString *subRex = [NSString stringWithFormat:@"\\[(%@)|,(%@)",numRex, numRex];
        NSRegularExpression *subExRex = [[NSRegularExpression alloc] initWithPattern:subRex];
        if ([subExRex isMatch:marchStr] == YES)
        {
            NSString *subJson = [subExRex replace:marchStr withDetailsBlock:^NSString *(RxMatch *subMatch) {
                NSMutableString *subMarchStr = [subMatch.value mutableCopy];
                [subMarchStr insertString:@"\"" atIndex:subMarchStr.length];
                [subMarchStr insertString:@"\"" atIndex:1];

                return subMarchStr;
            }];
            return subJson;
        } else
        {
            return marchStr;
        }
    }];
    return newJson1;
}

@end
