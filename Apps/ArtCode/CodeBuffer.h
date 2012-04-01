//
//  CodeBuffer.h
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileBuffer.h"
@class TMIndex, TMSyntaxNode, TMScope;
@protocol TMCompletionResultSet;

@interface CodeBuffer : FileBuffer

@property (nonatomic, strong) TMSyntaxNode *syntax;

- (id)initWithFileURL:(NSURL *)fileURL index:(TMIndex *)index;

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
