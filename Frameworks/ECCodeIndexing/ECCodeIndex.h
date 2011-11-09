//
//  ECCodeIndex.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <clang-c/Index.h>

@class ECCodeUnit;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related non file specific functionality such as symbol resolution and refactoring.
@interface ECCodeIndex : NSObject

/// Sets a file's unsaved contents to be available for all the code index's units.
/// Set to nil to have the index read the file contents from disk again
- (void)setUnsavedContent:(NSString *)content forFile:(NSURL *)fileURL;

/// Code unit creation
/// If the scope is not specified, it will be detected automatically
- (ECCodeUnit *)codeUnitForFile:(NSURL *)fileURL scope:(NSString *)scope;

@end
