//
//  EKFileSizeGetter.h
//  EKPlugins
//
//  Created by 首磊 on 2018/5/10.
//  Copyright © 2018年 ekwing. All rights reserved.
//

typedef void(^FileLength)(long long length, NSError *error);

@interface EKFileSizeGetter : NSObject<NSURLConnectionDataDelegate>
- (void)getUrlFileLength:(NSString *)url withResultBlock:(FileLength)block;
@end
