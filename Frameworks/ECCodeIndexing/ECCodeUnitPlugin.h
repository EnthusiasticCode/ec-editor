//
//  ECCodeUnitPlugin.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol ECCodeUnitPlugin <NSObject>
/// Returns whether the unit depends on the file at the given URL or not.
- (BOOL)isDependentOnFile:(NSURL *)fileURL;
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
- (NSArray *)tokensInRange:(NSRange)range;
/// Returns all tokens in the file.
- (NSArray *)tokens;
@end
