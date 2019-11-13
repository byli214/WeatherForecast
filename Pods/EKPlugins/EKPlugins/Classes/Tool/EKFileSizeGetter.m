//
//  EKFileSizeGetter.m
//  EKPlugins
//
//  Created by 首磊 on 2018/5/10.
//  Copyright © 2018年 ekwing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EKFileSizeGetter.h"

@interface EKFileSizeGetter()
@property (nonatomic, copy)FileLength cbBlock;
@end

@implementation EKFileSizeGetter

- (void)getUrlFileLength:(NSString *)url withResultBlock:(FileLength)block {
    self.cbBlock = block;
    if ([url containsString:@"http"]) {
        [self getFileLengthInNetwork:url];
    } else {
        [self getFileLengthInLocal:url];
    }
}

-(void)getFileLengthInNetwork:(NSString *)url {
    NSMutableURLRequest *mURLRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [mURLRequest setHTTPMethod:@"HEAD"];
    mURLRequest.timeoutInterval = 5.0;
    NSURLConnection *URLConnection = [NSURLConnection connectionWithRequest:mURLRequest delegate:self];
    [URLConnection start];
}

-(void)getFileLengthInLocal:(NSString *)path {
    NSFileManager *filemanager = [NSFileManager defaultManager];
    if ([filemanager fileExistsAtPath:path]) {
        long long length = [[filemanager attributesOfItemAtPath:path error:nil] fileSize];
        if (_cbBlock) {
            _cbBlock(length, nil);
        }
    } else {
        if (_cbBlock) {
            _cbBlock(-1, nil);
        }
    }
}

#pragma mark NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSDictionary *dict = [(NSHTTPURLResponse *)response allHeaderFields];
    NSNumber *length = [dict objectForKey:@"Content-Length"];
    [connection cancel];
    if (_cbBlock) {
        if (length) {
            _cbBlock([length longLongValue], nil);
        } else {
            if ([dict objectForKey:@"Cache-Control"])  // byte stream in unisound {
                _cbBlock(9999, nil);
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (_cbBlock) {
        _cbBlock(-1, error);
    }
    
    [connection cancel];
}

@end
