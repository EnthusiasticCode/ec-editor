//
//  ECFileCoordinator.h
//  ECFoundation
//
//  Created by Uri Baghin on 12/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// ECFileCoordinator is an NSFileCoordinator replacement until NSFileCoordinator is fixed.
/// It's interface parallels that of NSFileCoordinator so that code can be transitioned once NSFileCoordinator is fixed.
/// Bugs and known issues:
/// It does not monitor file system events, so it only works with code that supports file coordination explicitly.
/// It does not support file versioning.
/// It does not support symlinks.
/// It does not pass a new URL to accessor blocks, it always passes the same URL, even if the file was moved or deleted in the meantime.
/// In NSFilePresenter methods with a completion handler, it does not wait for it to be called, it instead waits for the method to return. It also ignores the error passed within the completion handler.
/// All the blocks passed to the coordinate methods are executed in the file coordination dispatch queue instead of the calling queue, unlike NSFileCoordinator.

@interface ECFileCoordinator : NSFileCoordinator

@end
