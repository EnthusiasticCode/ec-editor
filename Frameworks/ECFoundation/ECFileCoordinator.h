//
//  ECFileCoordinator.h
//  ECFoundation
//
//  Created by Uri Baghin on 12/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

/// ECFileCoordinator is an NSFileCoordinator replacement until NSFileCoordinator is fixed.
/// It's interface parallels that of NSFileCoordinator so that code can be transitioned once NSFileCoordinator is fixed, however it does not monitor file system events, so it only works with code that supports file coordination explicitly.
/// It also does not support file versioning.

@interface ECFileCoordinator : NSFileCoordinator



@end
