//
//  RACEchoSubject.h
//  ReactiveCocoa
//
//  Created by Uri Baghin on 10/1/12.
//
//


// An echo subject subscribes to subscribables and resends `next`, `error` and
// `complete` to subscribers
@interface RACEchoSubject : RACReplaySubject

// Tells the echo subject to echo the `next`s sent by `subscribable`. The returned
// subscribable cancels out the echo: it sends `next`s sent to the echo subject,
// unless they were sent by `subscribable`. It will also send `error` and
// `complete` sent directly to the echo subject.
- (id<RACSubscribable>)echoSubscribable:(id<RACSubscribable>)subscribable;

@end
