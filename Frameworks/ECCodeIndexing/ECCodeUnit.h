//
//  ECCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ECCodeIndex;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface ECCodeUnit : NSObject
/// The code index that generated the code unit.
@property (nonatomic, readonly, retain) ECCodeIndex *index;
/// The URL of the file the unit is attached to.
@property (nonatomic, readonly, retain) NSURL *url;
/// The language the unit is using to interpret the file's contents.
@property (nonatomic, readonly, retain) NSString *language;
/// Whether or not the files the units is depending on have unsaved content.
@property (nonatomic, readonly) BOOL filesHaveUnsavedContent;
/// Returns whether the unit depends on the file at the given URL or not.
- (BOOL)isDependentOnFile:(NSURL *)fileURL;
/// Force the code unit to reparse all files.
- (void)setNeedsReparse;
/// Returns the possible completions at a given insertion range.
- (NSArray *)completionsWithSelection:(NSRange)selection;
/// Returns warnings and errors.
- (NSArray *)diagnostics;
/// Returns fixits.
- (NSArray *)fixIts;
/// Returns tokens in the given range.
- (NSArray *)tokensInRange:(NSRange)range;
/// Returns all tokens in the file.
- (NSArray *)tokens;
@end
