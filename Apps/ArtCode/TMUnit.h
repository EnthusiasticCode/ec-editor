//
//  TMUnit.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TMScope, TMIndex, FileBuffer, TMSyntaxNode;
@protocol TMCompletionResultSet;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface TMUnit : NSObject

/// The index to coordinate with
@property (nonatomic, weak, readonly) TMIndex *index;

/// The syntax used to interpret the contents of the file
@property (nonatomic, strong) TMSyntaxNode *syntax;

/// Returns an array of TMSymbol objects representing all the symbols in the file.
@property (nonatomic, strong, readonly) NSArray *symbolList;

/// Returns warnings and errors in the unit.
@property (nonatomic, strong, readonly) NSArray *diagnostics;

/// Designated initializer. At least a fileBuffer or a fileURL must be specified.
- (id)initWithFileBuffer:(FileBuffer *)fileBuffer fileURL:(NSURL *)fileURL index:(TMIndex *)index;

/// Returns a copy of the deepest scope at the specified offset
- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void(^)(TMScope *scope))completionHandler;

/// Returns the possible completions at a given insertion point in the unit's main source file.
- (void)completionsAtOffset:(NSUInteger)offset withCompletionHandler:(void(^)(id<TMCompletionResultSet>completions))completionHandler;

@end
