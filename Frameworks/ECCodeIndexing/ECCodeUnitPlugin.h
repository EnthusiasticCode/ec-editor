//
//  ECCodeUnitPlugin.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECCodeCursor;

@protocol ECCodeUnitPlugin <NSObject>
/// Returns whether the unit depends on the file at the given file or not.
- (BOOL)isDependentOnFile:(NSString *)file;
/// Reparses the unit.
- (void)reparseDependentFiles:(NSArray *)files;
@optional
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
