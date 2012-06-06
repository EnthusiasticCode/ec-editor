//
//  DocumentWrapper.m
//  ArtCode
//
//  Created by Uri Baghin on 24/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DocumentWrapper.h"
#import <objc/runtime.h>

@implementation DocumentWrapper {
  UIDocument *(^_block)(void);
  UIDocument *_document;
  NSUInteger _openCount;
  NSMutableArray *_pendingOpenCompletionHandlers;
  NSMutableArray *_pendingCloseCompletionHandlers;
}

#pragma mark - Forwarding

+ (BOOL)resolveClassMethod:(SEL)sel
{
  Method method = class_getClassMethod([UIDocument class], sel);
  if (!method)
    return NO;
  Class metaClass = objc_getMetaClass("DocumentWrapper");
  class_addMethod(metaClass, sel, method_getImplementation(method), method_getTypeEncoding(method));
  return YES;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
  ASSERT(_block);
  if (!_document) {
    _document = _block();
  }
  return _document;
}

#pragma mark - UIDocument

- (UIDocumentState)documentState {
  return _openCount ? UIDocumentStateNormal : UIDocumentStateClosed;
}

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(_block);
  
  if (!_openCount) {
    [self willChangeValueForKey:@"documentState"];
  }
  
  // Increase the open counter
  ++_openCount;
  
  // If there are pending open, append the completionHandler
  if (_pendingOpenCompletionHandlers) {
    if (completionHandler) {
      [_pendingOpenCompletionHandlers addObject:[completionHandler copy]];
    }
    return;
  }
  
  // If there are pending close, queue the open after the close completes
  if (_pendingCloseCompletionHandlers) {
    __weak id weakSelf = self;
    void (^completionHandlerCopy)(BOOL) = [completionHandler copy];
    [_pendingCloseCompletionHandlers addObject:[^{
      id strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      [strongSelf openWithCompletionHandler:completionHandlerCopy];
    } copy]];
    return;
  }
  
  // If there is a document, and there were no pending open, the document is already opened
  if (_document) {
    if (completionHandler) {
      completionHandler(YES);
    }
    return;
  }
  
  // Create the document and open it, enquing the completionHandler
  _document = _block();
  _pendingOpenCompletionHandlers = NSMutableArray.alloc.init;
  if (completionHandler) {
    [_pendingOpenCompletionHandlers addObject:[completionHandler copy]];
  }
  [_document openWithCompletionHandler:^(BOOL success) {
    for (void(^pendingOpenCompletionHandler)(BOOL) in _pendingOpenCompletionHandlers) {
      pendingOpenCompletionHandler(success);
    }
    _pendingOpenCompletionHandlers = nil;
    [self didChangeValueForKey:@"documentState"];
  }];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(_openCount); // Must be called after -open...
  
  if (_openCount == 1) {
    [self willChangeValueForKey:@"documentState"];
  }
  
  // Decrease the open counter
  --_openCount;
  
  // If the open counter is still not zero, someone else is using the project
  if (_openCount) {
    if (completionHandler) {
      completionHandler(YES);
    }
    return;
  }
  
  // If there are pending close, append the completionHandler
  if (_pendingCloseCompletionHandlers) {
    if (completionHandler) {
      [_pendingCloseCompletionHandlers addObject:[completionHandler copy]];
    }
    return;
  }
  
  // If there are pending open, queue the close after the open completes
  if (_pendingOpenCompletionHandlers) {
    __weak id weakSelf = self;
    void (^completionHandlerCopy)(BOOL) = [completionHandler copy];
    [_pendingOpenCompletionHandlers addObject:^{
      id strongSelf = weakSelf;
      if (!strongSelf) {
        return;
      }
      [strongSelf closeWithCompletionHandler:completionHandlerCopy];
    }];
    return;
  }
  
  // Close the document, enquing the completionHandler
  _pendingCloseCompletionHandlers = NSMutableArray.alloc.init;
  if (completionHandler) {
    [_pendingCloseCompletionHandlers addObject:[completionHandler copy]];
  }
  [_document closeWithCompletionHandler:^(BOOL success) {
    for (void(^pendingCloseCompletionHandler)(BOOL) in _pendingCloseCompletionHandlers) {
      pendingCloseCompletionHandler(success);
    }
    _pendingCloseCompletionHandlers = nil;
    if (!_openCount) {
      _document = nil;
      [self didChangeValueForKey:@"documentState"];
    }
  }];
}

- (void)saveToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation completionHandler:(void (^)(BOOL))completionHandler {
  ASSERT(NSOperationQueue.currentQueue == NSOperationQueue.mainQueue);
  ASSERT(_block);
  NSUInteger openCountIncrease = 0;
  if (!_document) {
    _document = _block();
    ++openCountIncrease;
    [self willChangeValueForKey:@"documentState"];
  }
  [_document saveToURL:url forSaveOperation:saveOperation completionHandler:^(BOOL success) {
    if (success) {
      _openCount += openCountIncrease;
    }
    completionHandler(success);
    if (openCountIncrease) {
      [self didChangeValueForKey:@"documentState"];
    }
  }];
}

#pragma mark - Public Methods

+ (id)wrapperWithBlock:(UIDocument *(^)(void))block {
  ASSERT(block);
  DocumentWrapper *wrapper = [self.alloc init];
  wrapper->_block = [block copy];
  return wrapper;
}

@end
