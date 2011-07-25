//
//  ACStateProject.h
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateNode.h"

/// AC Project controller
/// This object should not be instantiated
@interface ACStateProject : ACStateNode

/// The directory where the project's documents are stored
- (NSURL *)documentDirectory;

/// The directory where the project's contents are stored
- (NSURL *)contentDirectory;

/// Open the project
/// Must be called before using any of the following methods
/// The children property is empty before calling this
- (void)openWithCompletionHandler:(void (^)(BOOL success))completionHandler;

/// Close the project
/// Must be called if the project has been opened
- (void)closeWithCompletionHandler:(void (^)(BOOL success))completionHandler;

@end
