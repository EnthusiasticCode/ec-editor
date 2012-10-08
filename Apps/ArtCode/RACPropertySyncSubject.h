//
//  RACPropertySyncSubject.h
//  ReactiveCocoa
//
//  Created by Uri Baghin on 10/1/12.
//
//


// A property sync subject keeps the values of properties synced between objects
// You maybe also subscribe to it directly to get all new values, or send
// `next`s to update values across all objects
@interface RACPropertySyncSubject : RACReplaySubject

// Synchronize the property of `target` identified by `keyPath`
// Only works on the main queue
- (RACDisposable *)syncProperty:(NSString *)keyPath ofObject:(NSObject *)target;

@end
