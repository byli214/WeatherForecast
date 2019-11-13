//
//  EKNetWorkTimer.m
//
//  Created by chen on 2018/1/16.

#import "EKNetWorkTimer.h"

#import <libkern/OSAtomic.h>

#if !__has_feature(objc_arc)
    #error EKWeakTimer is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

#if OS_OBJECT_USE_OBJC
    #define ms_gcd_property_qualifier strong
    #define ms_release_gcd_object(object)
#else
    #define ms_gcd_property_qualifier assign
    #define ms_release_gcd_object(object) dispatch_release(object)
#endif

@interface EKNetWorkTimer ()
{
    struct
    {
        uint32_t timerIsInvalidated;
    } _timerFlags;
}

@property (nonatomic, assign) NSTimeInterval tolerance;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) id userInfo;
@property (nonatomic, assign) BOOL repeats;
@property (nonatomic, assign) BOOL isSuspend;
@property (nonatomic, copy) void(^excuteBlock)(void);

@property (nonatomic, ms_gcd_property_qualifier) dispatch_queue_t privateSerialQueue;

@property (nonatomic, ms_gcd_property_qualifier) dispatch_source_t timer;

@end

@implementation EKNetWorkTimer

@synthesize tolerance = _tolerance;


#pragma mark -- init

- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                           block:(void(^)(void))block{
    return [self initWithInterval:interval
                          repeats:repeats
                            queue:dispatch_get_main_queue()
                            block:block];
}

- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                           queue:(dispatch_queue_t)queue
                           block:(void(^)(void))block
{
    return [self initWithInterval:interval
                           target:nil
                         selector:NULL
                         userInfo:nil
                          repeats:repeats
                            queue:queue
                            block:block];
}

- (instancetype)initWithInterval:(NSTimeInterval)interval
                          target:(id)target
                        selector:(SEL)selector
                            info:(id)info
                         repeats:(BOOL)repeats{
    return [self initWithInterval:interval
                           target:target
                         selector:selector
                             info:info
                          repeats:repeats
                            queue:dispatch_get_main_queue()];
    
}


- (instancetype)initWithInterval:(NSTimeInterval)interval
                          target:(id)target
                        selector:(SEL)selector
                            info:(id)info
                         repeats:(BOOL)repeats
                           queue:(dispatch_queue_t)queue{
    return [self initWithInterval:interval
                           target:target
                         selector:selector
                         userInfo:info
                          repeats:repeats
                            queue:queue
                            block:nil];
}

- (instancetype)initWithInterval:(NSTimeInterval)interval
                          target:(id)target
                        selector:(SEL)selector
                        userInfo:(id)userInfo
                         repeats:(BOOL)repeats
                           queue:(dispatch_queue_t)queue
                           block:(void(^)(void))block
{
    NSParameterAssert(queue);
    
    if ((self = [super init]))
    {
        self.timeInterval = interval;
        self.target = target;
        self.selector = selector;
        self.userInfo = userInfo;
        self.repeats = repeats;
        self.excuteBlock = block;
        
        NSString *privateQueueName = [NSString stringWithFormat:@"com.mindsnacks.EKWeakTimer.%p", self];
        self.privateSerialQueue = dispatch_queue_create([privateQueueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.privateSerialQueue, queue);
        
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                            0,
                                            0,
                                            self.privateSerialQueue);
        self.isSuspend = YES;
    }
    
    return self;
}


- (id)init
{
    return [self initWithInterval:0
                           target:nil
                         selector:NULL
                         userInfo:nil
                          repeats:NO
                            queue:nil
                            block:nil];
}


#pragma mark -- scheduled

+ (instancetype)scheduledWithInterval:(NSTimeInterval)interval
                               target:(id)target
                             selector:(SEL)selector
                             userInfo:(id)userInfo
                              repeats:(BOOL)repeats{
    
    return [self scheduledWithInterval:interval
                                target:target
                              selector:selector
                              userInfo:userInfo
                               repeats:repeats
                                 queue:dispatch_get_main_queue()];
}

+ (instancetype)scheduledWithInterval:(NSTimeInterval)interval
                               target:(id)target
                             selector:(SEL)selector
                             userInfo:(id)userInfo
                              repeats:(BOOL)repeats
                                queue:(dispatch_queue_t)queue
{
    EKNetWorkTimer *timer = [[self alloc] initWithInterval:interval
                                                 target:target
                                               selector:selector
                                               userInfo:userInfo
                                                repeats:repeats
                                                  queue:queue
                                                  block:nil];

    [timer schedule];

    return timer;
}

+ (instancetype)scheduledWithInterval:(NSTimeInterval)interval
                              repeats:(BOOL)repeats
                                queue:(dispatch_queue_t)queue
                                block:(void(^)(void))block{
    
    EKNetWorkTimer *timer = [[self alloc] initWithInterval:interval
                                                repeats:repeats
                                                  queue:queue
                                                  block:block];
    
    [timer schedule];
    return timer;
}

+ (instancetype)scheduledWithInterval:(NSTimeInterval)interval
                              repeats:(BOOL)repeats
                                block:(void(^)(void))block{
    
    EKNetWorkTimer *timer = [[self alloc] initWithInterval:interval
                                                repeats:repeats
                                                  queue:dispatch_get_main_queue()
                                                  block:block];
    
    [timer schedule];
    return timer;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> time_interval=%f target=%@ selector=%@ userInfo=%@ repeats=%d timer=%@",
            NSStringFromClass([self class]),
            self,
            self.timeInterval,
            self.target,
            NSStringFromSelector(self.selector),
            self.userInfo,
            self.repeats,
            self.timer];
}

- (void)dealloc
{
    [self invalidate];
    
    ms_release_gcd_object(_privateSerialQueue);
    
    NSLog(@"EKWeakTimer dealloc");
}


#pragma mark -

- (void)setTolerance:(NSTimeInterval)tolerance
{
    @synchronized(self)
    {
        if (tolerance != _tolerance)
        {
            _tolerance = tolerance;
            [self resetTimerProperties];
        }
    }
}

- (NSTimeInterval)tolerance
{
    @synchronized(self)
    {
        return _tolerance;
    }
}

- (void)resetTimerProperties
{
    int64_t intervalInNanoseconds = (int64_t)(self.timeInterval * NSEC_PER_SEC);
    int64_t toleranceInNanoseconds = (int64_t)(self.tolerance * NSEC_PER_SEC);

    dispatch_source_set_timer(self.timer,
                              dispatch_time(DISPATCH_TIME_NOW, intervalInNanoseconds),
                              (uint64_t)intervalInNanoseconds,
                              toleranceInNanoseconds
                              );
}

- (void)schedule
{
    if (NO == self.isSuspend) {
        return;
    }
    
    [self resetTimerProperties];

    __weak EKNetWorkTimer *weakSelf = self;

    dispatch_source_set_event_handler(self.timer, ^{
        [weakSelf timerFired];
    });

    dispatch_resume(self.timer);
    self.isSuspend = NO;
}

- (void)fire
{
    [self timerFired];
}

- (void)invalidate
{
    // We check with an atomic operation if it has already been invalidated. Ideally we would synchronize this on the private queue,
    // but since we can't know the context from which this method will be called, dispatch_sync might cause a deadlock.
    if (!OSAtomicTestAndSetBarrier(7, &_timerFlags.timerIsInvalidated))
    {
        if (self.isSuspend) {
            dispatch_resume(self.timer);
        }
        dispatch_source_t timer = self.timer;
        dispatch_async(self.privateSerialQueue, ^{
            dispatch_source_cancel(timer);
            ms_release_gcd_object(timer);
        });
    }
}

- (void)timerFired
{
    // Checking attomatically if the timer has already been invalidated.
    if (OSAtomicAnd32OrigBarrier(1, &_timerFlags.timerIsInvalidated))
    {
        return;
    }

    // We're not worried about this warning because the selector we're calling doesn't return a +1 object.
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (self.excuteBlock) {
        self.excuteBlock();
    }else{
        if ([self.target respondsToSelector:self.selector]) {
            [self.target performSelector:self.selector withObject:self];
        }
    }
    #pragma clang diagnostic pop
    

    if (!self.repeats)
    {
        [self invalidate];
    }
}

- (void)setIsSuspend:(BOOL)isSuspend{
    
    NSLock *lock = [[NSLock alloc] init];
    [lock tryLock];
    _isSuspend = isSuspend;
    [lock unlock];
}

- (void)pause{
    if (self.timer && !self.isSuspend) {
        dispatch_suspend(self.timer);
        self.isSuspend = YES;
    }
}
- (void)resume{
    if (self.timer && self.isSuspend) {
        dispatch_resume(self.timer);
        self.isSuspend = NO;
    }
}

- (id)getUserInfo{
    
    return self.userInfo;
}

@end
