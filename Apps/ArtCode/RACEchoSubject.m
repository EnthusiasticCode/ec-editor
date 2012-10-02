//
//  RACEchoSubject.m
//  ReactiveCocoa
//
//  Created by Uri Baghin on 10/1/12.
//
//

#import "RACEchoSubject.h"

@interface RACEchoSubject ()

@property (nonatomic, strong, readonly) RACReplaySubject *echo;

@end

@implementation RACEchoSubject

@synthesize echo = _echo;

- (RACSubject *)echo {
  if (!_echo) {
    _echo = [RACReplaySubject replaySubjectWithCapacity:RACReplaySubjectUnlimitedCapacity];
  }
  return _echo;
}

- (void)sendNext:(id)value {
  [self.echo sendNext:[RACTuple tupleWithObjectsFromArray:@[value ? : [RACTupleNil tupleNil], [RACTupleNil tupleNil]]]];
}

- (void)sendError:(NSError *)error {
  [self.echo sendError:error];
}

- (void)sendCompleted {
  [self.echo sendCompleted];
}

- (RACDisposable *)subscribe:(id<RACSubscriber>)subscriber {
  return [[self.echo select:^id(RACTuple *x) {
    return x.first;
  }] subscribe:subscriber];
}

- (id<RACSubscribable>)echoSubscribable:(id<RACSubscribable>)subscribable {
  NSParameterAssert(subscribable != nil);
  RACDisposable *subscribableDisposable = [subscribable subscribeNext:^(id x) {
    [self.echo sendNext:[RACTuple tupleWithObjectsFromArray:@[x, subscribable]]];
  }];
  return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
    RACDisposable *echoCancellerDisposable = [self.echo subscribeNext:^(RACTuple *x) {
      if (x.second != subscribable) {
        [subscriber sendNext:x.first];
      }
    } error:^(NSError *error) {
      [subscriber sendError:error];
    } completed:^{
      [subscriber sendCompleted];
    }];
    return [RACDisposable disposableWithBlock:^{
      [subscribableDisposable dispose];
      [echoCancellerDisposable dispose];
    }];
  }];
}

+ (instancetype)replaySubjectWithCapacity:(NSUInteger)capacity {
  RACEchoSubject *subject = [self subject];
  subject->_echo = [RACReplaySubject replaySubjectWithCapacity:capacity];
  return subject;
}

@end
