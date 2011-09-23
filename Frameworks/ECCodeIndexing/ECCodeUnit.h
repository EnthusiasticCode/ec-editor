//
//  ECCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECCodeIndex;
@class ECCodeCursor;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface ECCodeUnit : NSObject

/// The code index that generated the code unit.
@property (nonatomic, readonly, strong) ECCodeIndex *index;

/// The main source file the unit is interpreting.
@property (nonatomic, readonly, strong) NSURL *fileURL;

/// The language the unit is using to interpret the main source file's contents.
@property (nonatomic, readonly, strong) NSString *language;

/// Returns the possible completions at a given insertion point in the unit's main source file.
- (NSArray *)completionsAtOffset:(NSUInteger)offset;

/// Returns warnings and errors in the unit's main source file.
- (NSArray *)diagnostics;

/// Returns fixits in the unit's main source file.
- (NSArray *)fixIts;

/// Returns tokens in the given range in the unit's main source file, attaching cursors if possible.
- (NSArray *)tokensInRange:(NSRange)range withCursors:(BOOL)attachCursors;

/// Return the cursor for the unit.
- (ECCodeCursor *)cursor;

/// Return the cursor for an offset in the unit's main source file.
- (ECCodeCursor *)cursorForOffset:(NSUInteger)offset;

@end
