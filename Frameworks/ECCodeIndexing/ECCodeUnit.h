//
//  ECCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ECCodeIndex;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface ECCodeUnit : NSObject

/// The code index that generated the code unit.
- (ECCodeIndex *)index;

/// The main source file the unit is interpreting.
- (NSURL *)fileURL;

/// The language the unit is using to interpret the main source file's contents.
- (NSString *)language;

- (NSString *)scope;

/// Returns the possible completions at a given insertion point in the unit's main source file.
- (NSArray *)completionsAtOffset:(NSUInteger)offset;

/// Returns warnings and errors in the unit.
- (NSArray *)diagnostics;

/// Returns tokens in the unit's main source file.
- (NSArray *)tokens;
- (NSArray *)annotatedTokens;
- (NSArray *)tokensInRange:(NSRange)range;
- (NSArray *)annotatedTokensInRange:(NSRange)range;

@end
