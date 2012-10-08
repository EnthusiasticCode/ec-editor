//
//  RACPropertySyncSubject.m
//  ReactiveCocoa
//
//  Created by Uri Baghin on 10/1/12.
//
//

#import "RACPropertySyncSubject.h"

@interface RACPropertySyncSubject ()

@property (nonatomic, strong, readonly) RACReplaySubject *switchboard;

@end

@implementation RACPropertySyncSubject

@synthesize switchboard = _switchboard;

- (RACSubject *)switchboard {
  if (!_switchboard) {
    _switchboard = [RACReplaySubject replaySubjectWithCapacity:1];
  }
  return _switchboard;
}

- (void)sendNext:(id)value {
  [self.switchboard sendNext:[RACTuple tupleWithObjectsFromArray:@[value ? : [RACTupleNil tupleNil], [RACTupleNil tupleNil]]]];
}

- (void)sendError:(NSError *)error {
  [self.switchboard sendError:error];
}

- (void)sendCompleted {
  [self.switchboard sendCompleted];
}

- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
  return [[self.switchboard select:^id(RACTuple *x) {
    return x.first;
  }] subscribe:subscriber];
}

+ (instancetype)replaySubjectWithCapacity:(NSUInteger)capacity {
  RACPropertySyncSubject *subject = [self subject];
  subject->_switchboard = [RACReplaySubject replaySubjectWithCapacity:capacity];
  return subject;
}

- (RACDisposable *)syncProperty:(NSString *)keyPath ofObject:(NSObject *)target {
  ASSERT_MAIN_QUEUE();
  __block BOOL suppressEcho = NO;
  RACDisposable *propertySubscribingDisposable = nil;
  RACDisposable *propertyUpdatingDisposable = nil;
  void (^stopSyncing)(void) = ^{
    [propertySubscribingDisposable dispose];
    [propertyUpdatingDisposable dispose];
  };
  
  propertySubscribingDisposable = [[target rac_subscribableForKeyPath:keyPath onObject:self] subscribeNext:^(id x) {
    if (!suppressEcho) {
      [self.switchboard sendNext:[RACTuple tupleWithObjectsFromArray:@[x ? : [RACTupleNil tupleNil], target, keyPath]]];
    }
  }];
  propertyUpdatingDisposable = [[self.switchboard deliverOn:[RACScheduler mainQueueScheduler]] subscribeNext:^(RACTuple *x) {
    if (x.second != target || x.third != keyPath) {
      suppressEcho = YES;
      [target setValue:x.first forKeyPath:keyPath];
      suppressEcho = NO;
    }
  } error:^(NSError *error) {
    stopSyncing();
  } completed:^{
    stopSyncing();
  }];
  return [RACDisposable disposableWithBlock:^{
    stopSyncing();
  }];
}

@end
