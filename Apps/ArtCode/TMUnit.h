//
//  TMUnit.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TMIndex, TMSyntaxNode;
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

/// Designated initializer.
- (id)initWithFileURL:(NSURL *)fileURL index:(TMIndex *)index;

/// Enumerates the qualified identifiers of the scopes in the given range
- (void)enumerateQualifiedScopeIdentifiersInRange:(NSRange)range withBlock:(void(^)(NSString *qualifiedScopeIdentifier, NSRange range, BOOL *stop))block;

/// Returns the qualified identifier of the deepest scope at the specified offset
- (NSString *)qualifiedScopeIdentifierAtOffset:(NSUInteger)offset;

/// Returns the possible completions at a given insertion point in the unit's main source file.
- (id<TMCompletionResultSet>)completionsAtOffset:(NSUInteger)offset;

/// Reparses the source file and recreates the scope tree asynchronously.
/// If the content string is non-nil, it will be used instead of the file's contents.
- (void)reparseWithUnsavedContent:(NSString *)content;

@end
