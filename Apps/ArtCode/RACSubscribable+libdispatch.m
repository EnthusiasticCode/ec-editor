//
//  RACSubscribable+libdispatch.m
//  ArtCode
//
//  Created by Uri Baghin on 11/5/12.
//
//

#import "RACSubscribable+libdispatch.h"

@implementation RACSubscribable (libdispatch)

+ (RACSubscribable *)interval:(NSTimeInterval)interval withLeeway:(NSTimeInterval)leeway {
  return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_current_queue());
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, leeway * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
      [subscriber sendNext:[NSDate date]];
    });
    dispatch_resume(timer);
    
    return [RACDisposable disposableWithBlock:^{
      dispatch_source_cancel(timer);
      dispatch_release(timer);
    }];
  }];
}

@end
