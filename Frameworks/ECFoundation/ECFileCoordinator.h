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
/// It does not support symlinks or directories containing symlinks.
/// It does not pass a new URL to accessor blocks, it always passes the same URL, even if the file was moved or deleted in the meantime.
/// It is very slow.

@interface ECFileCoordinator : NSFileCoordinator

@end
