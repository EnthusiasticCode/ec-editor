//
//  Operation.m
//  ArtCode
//
//  Created by Uri Baghin on 4/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Operation.h"
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>

@implementation Operation

#pragma mark - NSObject

- (id)initWithCompletionHandler:(void (^)(BOOL))completionHandler {
  self = super.init;
  if (!self) {
    return nil;
  }
  if (completionHandler) {
    NSOperationQueue *homeQueue = NSOperationQueue.currentQueue;
    [self observeTarget:self keyPath:@"isFinished" options:NSKeyValueObservingOptionNew block:^(MAKVONotification *notification) {
      if (!self.isFinished) {
        return;
      }
      if (NSOperationQueue.currentQueue == homeQueue)
      {
        completionHandler(!self.isCancelled);
      } else {
        [homeQueue addOperationWithBlock:^{
          ASSERT(self.isFinished);
          completionHandler(!self.isCancelled);
        }];
      }
    }];
  }
  return self;
}

@end
