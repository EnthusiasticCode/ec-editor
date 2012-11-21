//
//  TMUnit.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TMIndex, TMSyntaxNode;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface TMUnit : NSObject

/// The index to coordinate with
@property (nonatomic, weak, readonly) TMIndex *index;

/// The syntax used to interpret the contents of the file
@property (nonatomic, strong, readonly) TMSyntaxNode *syntax;

/// Returns an array of TMScope objects representing all the symbols in the file.
@property (nonatomic, copy, readonly) NSArray *symbolList;

/// Returns a signal that sends a signal for each reparse operation that send tokens as they are parsed
@property (nonatomic, strong, readonly) id<RACSignal> tokens;

/// Designated initializer. Creates a new TMUnit for the file at the given URL and syntax, coordinating with other TMUnits via the given index.
/// It will not attempt to access the file itself, the fileURL is only used internally for parsing
- (id)initWithFileURL:(NSURL *)fileURL syntax:(TMSyntaxNode *)syntax index:(TMIndex *)index;

/// Enumerates the qualified identifiers of the scopes in the given range
- (void)enumerateQualifiedScopeIdentifiersInRange:(NSRange)range withBlock:(void(^)(NSString *qualifiedScopeIdentifier, NSRange range, BOOL *stop))block;

/// Returns the qualified identifier of the deepest scope at the specified offset
- (NSString *)qualifiedScopeIdentifierAtOffset:(NSUInteger)offset;

/// Reparses the source file using the given content
- (void)reparseWithUnsavedContent:(NSString *)content;

@end

@interface TMToken : NSObject

@property (nonatomic, strong, readonly) NSString *qualifiedIdentifier;
@property (nonatomic, readonly) NSRange range;

@end