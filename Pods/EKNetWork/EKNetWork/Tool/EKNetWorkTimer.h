//
//  EKNetWorkTimer.h
//  EKUtils
//
//  Created by chen on 2018/1/16.
//  Copyright © 2017年 chen. All rights reserved.

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double EKWeakTimerVersionNumber;
FOUNDATION_EXPORT const unsigned char EKWeakTimerVersionString[];

/**
 EKWeakTimer类似NSTimer的功能，功能调用分两种方式，target和block，
 target方式，EKWeakTimer对象不会retain对应target,当target调用dealloc时，会自动释放EKWeakTimer
 block方式，切记block中，要使用__weak，此block中使用strong target时，会造成循环引用，导致无法释放。
 内部通过GCD实现。
 */
@interface EKNetWorkTimer : NSObject

/**
 * 创建EKWeakTimer对象，创建后此对象默认suspend，调用‘schedule’或者‘fire’,
 * 其中'fire'会在外部调用线程中执行，并且是立即执行，只执行一次，跟dispatch_queue_t没有关系
 * 此方法调用默认是在dispatch_get_main_queue线程中调用
 * @param interval 间隔时间
 * @param repeats  是否重复
 * @block block 执行块
 * return EKWeakTimer
 */
- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                           block:(void(^)(void))block;

/**
 * 类似initWithInterval:repeats:block:方法，此方法可以传入执行线程dispatch_queue_t
 * queue 需要再哪个线程上执行
 */
- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                           queue:(dispatch_queue_t)queue
                           block:(void(^)(void))block;

/**
 * 创建EKWeakTimer对象，创建后此对象默认suspend，调用‘schedule’或者‘fire’,
 * 其中'fire'会在外部调用线程中执行，并且是立即执行，只执行一次，跟dispatch_queue_t没有关系
 * 此方法调用默认是在dispatch_get_main_queue线程中调用
 * @param interval 间隔时间
 * @param target  对象
 * @block selector 执行方法
 * @info 执行方法传入的参数
 * @repeats 是否重复执行
 * return EKWeakTimer
 */
- (instancetype)initWithInterval:(NSTimeInterval)interval
                          target:(id)target
                        selector:(SEL)selector
                            info:(id)info
                         repeats:(BOOL)repeats;

/**
 * 类似initWithInterval:target:selector:info:repeats方法，此方法可以传入执行线程dispatch_queue_t
 * queue 需要再哪个线程上执行
 */
- (instancetype)initWithInterval:(NSTimeInterval)interval
                          target:(id)target
                        selector:(SEL)selector
                            info:(id)info
                         repeats:(BOOL)repeats
                           queue:(dispatch_queue_t)queue;

/**
 * 创建一个‘EKWeakTimer’对象，并且直接调用‘schedules’执行
 * 通过target方式
 * 默认是在主线程下执行
 */
+ (instancetype)scheduledWithInterval:(NSTimeInterval)interval
                               target:(id)target
                             selector:(SEL)selector
                             userInfo:(id)userInfo
                              repeats:(BOOL)repeats;

/**
 * 创建一个‘EKWeakTimer’对象，并且直接调用‘schedules’执行
 * 通过block方式，使用时注意循环引用问题，块中要weak处理
 * 默认是在dispatch_get_main_queue，主线程下执行
 */
+ (instancetype)scheduledWithInterval:(NSTimeInterval)interval
                              repeats:(BOOL)repeats
                                block:(void(^)(void))block;


/**
 * 启动timer执行任务，如果调用一个已经启动过的timer，会没有反应，内部直接return处理。
 *
 */
- (void)schedule;

/**
 * 立刻执行，执行所在的线程是在你外部调用的线程中，‘fire’会忽略只传入的repeats，interval等信息，只会执行一次
 * 此方法和‘schedule’有区别，‘schedule’会根据你传入的参数和控制执行，'fire'不会
 * target方式，相当于直接 target-->selector方法
 * blcok方式，相当于直接执行block()
 */
- (void)fire;
/**
 * 你可以在需要停止或者销毁的地方调用‘invalidate’，不管repeats是1或者1++次，执行线程不会强引用EKWeakTimer
 * 执行后target和block不会再继续执行。使用NSTimer时，再dealloc中调用invalidate，target是无法释放的，即使你使用weak处理
 * 此方法会随时释放，除非使用block时，出现了循环引用。执行后后台会把dispatch_source_t销毁
 */
- (void)invalidate;
/*
 * 暂停方法， 后台会suspend dispatch_source_t
 */
- (void)pause;

/*
 * 继续执行，后台会resume dispatch_source_t
 */
- (void)resume;

/*
 * 通过target传入参数
 */
- (id)getUserInfo;

@end
