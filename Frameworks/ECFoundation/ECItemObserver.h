//
//  ECFileObserver.h
//  ECFoundation
//
//  Created by Uri Baghin on 9/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECItemObserver;

@protocol ECItemObserverDelegate <NSObject>
@optional

/// Called when presentedItemDidChange is called, but only if the observed item's last modification date is more recent than what it was the last time the method was called
- (void)contentsOfObservedItemDidChangeForItemObserver:(ECItemObserver *)itemObserver;
/// Called when presentedItemDidMoveToURL: is called
- (void)itemObserver:(ECItemObserver *)itemObserver observedItemDidMoveFromURL:(NSURL *)oldItemURL;
/// Called when accommodateObservedItemDeletionWithCompletionHandler: is called
- (void)itemObserver:(ECItemObserver *)itemObserver accommodateObservedItemDeletionWithCompletionHandler:(void (^)(NSError *errorOrNil))completionHandler;

@end

/// A file observer implements the NSFilePresenter protocol and forwards the messages to it's delegate.
/// It has to be initialized with a valid item (file or directory) URL and a queue. The calls to the delegate methods are dispatched to the queue.
/// Because of how NSFilePresenter works, it is strongly advised not to pass a shared queue such as the main queue, as to avoid deadlocks.
@interface ECItemObserver : NSObject <NSFilePresenter>

@property (nonatomic, weak) id<ECItemObserverDelegate>delegate;

- (id)initWithItemURL:(NSURL *)itemURL queue:(NSOperationQueue *)queue;

@end
