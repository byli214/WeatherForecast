//
//  EKNetWorkFormData.m
//  EKNetWork
//
//  Created by mac on 2018/11/29.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKNetPackData.h"

@implementation EKNetPackData
@synthesize data;
@synthesize fileName;
@synthesize fileURL;
@synthesize mimeType;
@synthesize name;

- (instancetype)initWithFileURL:(NSURL *)fileURL name:(NSString *)name
{
    self = [super init];
    if (self) {
        self.fileURL = fileURL;
        self.name = name;
    }
    return self;
}

- (instancetype)initWithFileURL:(NSURL *)fileURL name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType
{
    self = [self initWithFileURL:fileURL name:name];
    if (self) {
        self.fileName = fileName;
        self.mimeType = mimeType;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data name:(NSString *)name
{
    self = [super init];
    if (self) {
        self.data = data;
        self.name = name;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data name:(NSString *)name fileName:(NSString *)fileName mimeType:(NSString *)mimeType
{
    self = [self initWithData:data name:name];
    if (self) {
        self.fileName = fileName;
        self.mimeType = mimeType;
    }
    return self;
}

@end
