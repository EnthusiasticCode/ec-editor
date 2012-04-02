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

/// The syntax used to interpret the buffer's contents. Can be set explicitly or left nil to be autodetected.
@property (nonatomic, strong) TMSyntaxNode *syntax;

/// Returns an array of TMSymbol objects representing all the symbols in the file.
@property (nonatomic, strong, readonly) NSArray *symbolList;

/// Returns warnings and errors in the unit.
@property (nonatomic, strong, readonly) NSArray *diagnostics;

/// Designated initializer. Both parameters are optional.
- (id)initWithFileURL:(NSURL *)fileURL index:(TMIndex *)index;

/// Returns a copy of the deepest scope at the specified offset
- (void)scopeAtOffset:(NSUInteger)offset withCompletionHandler:(void(^)(TMScope *scope))completionHandler;

/// Returns the possible completions at a given insertion point in the unit's main source file.
- (void)completionsAtOffset:(NSUInteger)offset withCompletionHandler:(void(^)(id<TMCompletionResultSet>completions))completionHandler;

@end
