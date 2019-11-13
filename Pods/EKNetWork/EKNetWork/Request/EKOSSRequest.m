//
//  EKOSSRequest.m
//  EKNetWork
//
//  Created by mac on 2018/11/30.
//  Copyright © 2018 EKing. All rights reserved.
//

#import "EKOSSRequest.h"
#import "EKNetWorkTool.h"
#import "EKDataRequest.h"
#import "EKUploadRequest.h"
#import "EKNetPackData.h"
#import "EKNetDataResult.h"

@interface EKOSSRequest()
@property (nonatomic, copy) NSString *SHKKEY;
@property (nonatomic, strong) EKDataRequest *urlRequest;
@property (nonatomic, strong) EKUploadRequest *uploadRequest;
@end

@implementation EKOSSRequest

- (void)cancelOSSUpload;
{
    [self.uploadRequest silenceCancel];
}

- (void)cancelOSSRequest
{
    [self.urlRequest silenceCancel];
}

- (void)startRequestOSSInfo:(NSString *)url
                   argument:(NSDictionary<NSString*, NSString*> *)argument
                  hookBlock:(nullable void(^)(EKDataRequest*dataRequest))hookBlock
                   complete:(void(^)(EKOSSRequest* ossReq, NSString *ossJson, id<EKDataResultProtocol>result))complete
{
    
    NSString *SHK = argument[@"SHK"];
    NSMutableDictionary *mutDic = [NSMutableDictionary dictionaryWithDictionary:argument];
    if (SHK.length == 0)
    {
        SHK = [EKNetWorkTool generatingSHK:300];
        mutDic[@"SHK"] = SHK;
    }

    self.SHKKEY = [SHK substringWithRange:NSMakeRange(0, 16)];
    
    __weak typeof(self) weakSelf = self;
    EKDataRequest *request = [[EKDataRequest alloc] initWithUrl:url];
    request.method = EKNetGet;
    
    if (hookBlock != nil)
    {
        hookBlock(request);
    }
        
    [request startWithArgument:mutDic complete:^(id<EKDataResultProtocol>  _Nonnull result) {
        
        NSString *resultJson = result.resonseString;
        if (weakSelf.SHKKEY.length > 0 && result.responseData != nil)
        {
            resultJson = [EKNetWorkTool AES128Decrypt:result.responseData key:weakSelf.SHKKEY];
            resultJson = [resultJson stringByReplacingOccurrencesOfString:@"\0" withString:@""];
        }
        if (complete != nil) {
            complete(weakSelf, resultJson, result);
        }
    }];
    self.urlRequest = request;
}


- (void)startUploadWithPath:(NSString *)filePath
                    ossJson:(NSString *)ossJson
                  hookBlock:(nullable void(^)(NSString*lineUrl, EKUploadRequest*upRequest))hookBlock
                   progress:(nullable void(^)(NSProgress*progress))progressBlock
                   complete:(void(^)(id<EKUploadResultProtocol>result))complete
{
    if (ossJson.length>0 && filePath.length>0 && [[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSError *serializatonError;
        NSData *newJsonData = [ossJson dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *ossDic = [NSJSONSerialization JSONObjectWithData:newJsonData options:0 error:&serializatonError];
        
        if (![ossDic isKindOfClass:[NSDictionary class]])
        {
            if (complete != nil) {
                
                EKNetUploadResult *result = [[EKNetUploadResult alloc] init];
                result.error = serializatonError;
                complete(result);
            }
            return;
        }
        
        NSString *ossUrl = [ossDic valueForKey:@"ossAddr"];
        NSString *ossKey = [ossDic valueForKey:@"key"];
        
        if ([ossUrl isKindOfClass:[NSString class]] == NO || ossUrl.length == 0)
        {
            if (complete != nil)
            {
                EKNetUploadResult *result = [[EKNetUploadResult alloc] init];
                result.error =  [[NSError alloc] initWithDomain:@"ErrorUrl" code:-2 userInfo:nil];;
                complete(result);
            }
            return;
        }
        
        //
        NSTimeInterval uploadTimeOut = 20;
        
        EKUploadRequest *uploadRequest = [[EKUploadRequest alloc] initWithUrl:ossUrl];
        uploadRequest.timeoutInterval = uploadTimeOut;
        uploadRequest.method = EKNetPost;
        uploadRequest.serializer = EKNetXml;
        
        //
        if (hookBlock != nil) {
            NSString *linkUrl = [NSString stringWithFormat:@"%@/%@",ossUrl,ossKey];
            hookBlock(linkUrl, uploadRequest);
        }
        
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        NSString *fileName = [filePath lastPathComponent];
        NSString *mimeType = [ossDic valueForKey:@"Content-Type"];
        EKNetPackData *formData = [[EKNetPackData alloc] initWithFileURL:fileURL name:@"file" fileName:fileName mimeType:mimeType];
        
        [uploadRequest startUploadWithArgument:ossDic packData:formData progress:^(NSProgress * _Nonnull progress) {
            if (progressBlock != nil) {
                progressBlock(progress);
            }
        } complete:^(id<EKUploadResultProtocol> _Nonnull result) {
            
            if (complete != nil) {
                complete(result);
            }
        }];
        
        self.uploadRequest = uploadRequest;
    }
}

@end
