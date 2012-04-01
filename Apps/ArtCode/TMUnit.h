//
//  TMUnit.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TMScope, UIImage, TMIndex, FileBuffer, TMSyntaxNode;
@protocol TMCompletionResultSet, TMCompletionResult, TMCompletionString, TMCompletionChunk;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface TMUnit : NSObject

@property (nonatomic, weak, readonly) TMIndex *index;

@property (nonatomic, strong) TMSyntaxNode *syntax;

- (id)initWithFileBuffer:(FileBuffer *)fileBuffer fileURL:(NSURL *)fileURL index:(TMIndex *)index;

/// Returns an array of TMSymbol objects representing all the symbols in the file.
- (void)symbolListWithCompletionHandler:(void(^)(NSArray *symbolList))completionHandler;

/// Visit the scopes in the unit.

- (void)rootScopeWithCompletionHandler:(void(^)(TMScope *rootScope))completionHandler;

- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void(^)(TMScope *scope))completionHandler;

/// Returns the possible completions at a given insertion point in the unit's main source file.
/// If filterRange is not NULL, in output it will contain the file buffer string range that contains 
/// the substring used for filtering.
- (id<TMCompletionResultSet>)completionsAtOffset:(NSUInteger)offset;

/// Returns warnings and errors in the unit.
- (NSArray *)diagnostics;

@end
