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
/// The file of the file the unit is attached to.
@property (nonatomic, readonly, strong) NSString *file;
/// The language the unit is using to interpret the file's contents.
@property (nonatomic, readonly, strong) NSString *language;
/// Whether or not the files the units is depending on have unsaved content.
@property (nonatomic, readonly) BOOL filesHaveUnsavedContent;
/// Returns whether the unit depends on the file at the given file or not.
- (BOOL)isDependentOnFile:(NSString *)file;
/// Force the code unit to reparse all files.
- (void)setNeedsReparse;
/// Returns the possible completions at a given insertion range.
- (NSArray *)completionsWithSelection:(NSRange)selection;
/// Returns warnings and errors.
- (NSArray *)diagnostics;
/// Returns fixits.
- (NSArray *)fixIts;
/// Returns tokens in the given range.
- (NSArray *)tokensInRange:(NSRange)range withCursors:(BOOL)attachCursors;
/// Returns all tokens in the file.
- (NSArray *)tokensWithCursors:(BOOL)attachCursors;
/// Return the cursor for the unit.
- (ECCodeCursor *)cursor;
/// Return the cursor for an offset in the unit's main source file.
- (ECCodeCursor *)cursorForOffset:(NSUInteger)offset;
@end
