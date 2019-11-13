//
//  EKNetResultInfo.m
//  EKNetWork
//
//  Created by mac on 2018/11/27.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKNetDataResult.h"
#import "EKNetDemand.h"
#import "EKDataDemand.h"
#import "EKDownloadDemand.h"
#import "EKUploadDemand.h"


NS_INLINE int getInterValueWith(NSDictionary *dic, NSString *key)
{
    if ([dic.allKeys containsObject:key]){
        id value = [dic valueForKey:key];
        if ([value isKindOfClass:[NSNumber class]]) {
            return [(NSNumber *)value intValue];
        }
        if ([value isKindOfClass:[NSString class]]) {
            return [(NSString *)value intValue];
        }
    }
    
    return -1;
}

NS_INLINE int getErrorIdWithDic(NSDictionary *dic)
{
    for (NSString *errorId in @[@"intent", @"intend"]){
        if ([dic.allKeys containsObject:errorId]) {
            return getInterValueWith(dic, errorId);
        }
    }
    return -1;
}

NS_INLINE NSString* getErrorMsgWithDic(NSDictionary *dic)
{
    for (NSString *errorKey in @[@"error_msg", @"errorlog"]) {
        if ([dic.allKeys containsObject:errorKey]) {
            return [dic valueForKey:errorKey];
        }
    }
    return nil;
}

NS_INLINE NSString *getJsonWithData(id objc)
{
    NSString *json = nil;
    if (objc != nil && [NSJSONSerialization isValidJSONObject:objc])
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:objc options:0 error:nil];
        json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return json;
}

//
@implementation EKNetResult
@synthesize argument, duration, error, responseObject, resonseString, request, response, responseData, url, userData;

- (instancetype)initWithDemand:(EKNetDemand *)demand
{
    self = [super init];
    if (self) {
        self.error = demand.error;
        self.argument = demand.argument;
        self.response = demand.response;
        self.responseData = demand.responseData;
        self.resonseString = demand.responseString;
        self.responseObject = demand.responseObject;
        self.request = demand.oriRequest;
        self.duration = demand.duration;
    }
    return self;
}
@end

//
@implementation EKNetDataResult
@synthesize data, errorId, errorMsg, status, dataJson;

- (instancetype)initWithNetDataDemand:(EKDataDemand *)demand
{
    self = [super initWithDemand:demand];
    if (self)
    {
        
        self.status = -1;
        self.url = demand.info.url;
        self.userData = demand.info.userData;
        if ([demand.responseObject isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *objectDic = (NSDictionary *)demand.responseObject;
            self.status = getInterValueWith(objectDic, @"status");
            self.data = [objectDic valueForKey:@"data"];
            
            self.errorId = getErrorIdWithDic(objectDic);
            self.errorMsg = getErrorMsgWithDic(objectDic);
            self.dataJson = getJsonWithData(self.data);
            
            if ([self.data isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *dataDic = (NSDictionary *)self.data;
                self.errorId = getErrorIdWithDic(dataDic);
                self.errorMsg = getErrorMsgWithDic(dataDic);
            }
        }
    }
    return self;
}

@end

//

@implementation EKNetUploadResult
- (instancetype)initWithNetUploadDemand:(EKUploadDemand *)demand
{
    self = [super initWithDemand:demand];
    if (self) {
        self.url = demand.info.url;
        self.userData = demand.info.userData;
    }
    return self;
}
@end

//
@implementation EKNetDownloadResult
@synthesize cachePath;
- (instancetype)initWithDemand:(EKDownloadDemand *)demand
{
    self = [super initWithDemand:demand];
    if (self) {
        self.url = demand.info.url;
        self.cachePath = demand.cachePath;
        self.userData = demand.info.userData;
    }
    return self;
}

@end
