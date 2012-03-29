//
//  TMUnit.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TMScope, UIImage, ACProjectFile;
@protocol TMCompletionResultSet, TMCompletionResult, TMCompletionString, TMCompletionChunk;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface TMUnit : NSObject

@property (nonatomic, readonly, getter = isLoading) BOOL loading;

- (id)initWithProjectFile:(ACProjectFile *)projectFile;

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

/// Represent a symbol returned by the symbolList method in TMUnit.
@interface TMSymbol : NSObject

@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) UIImage *icon;
@property (nonatomic, readonly) NSRange range;
@property (nonatomic, readonly) NSUInteger indentation;
@property (nonatomic, readonly, getter = isSeparator) BOOL separator;

@end

@protocol TMCompletionResultSet <NSObject>
- (NSUInteger)count;
- (id<TMCompletionResult>)completionResultAtIndex:(NSUInteger)resultIndex;
- (NSUInteger)indexOfHighestRatedCompletionResult;

/// The range of the string in the code unit file buffer used to filter the results.
/// This range is constructed from the offset provided in initialization.
- (NSRange)filterStringRange;

@end

@protocol TMCompletionResult <NSObject>

- (id<TMCompletionString>)completionString;
- (enum CXCursorKind)cursorKind;

@end

@protocol TMCompletionString <NSObject>

- (NSArray *)completionChunks;
- (id<TMCompletionChunk>)typedTextChunk;
- (NSArray *)annotations;
- (unsigned)priority;
- (enum CXAvailabilityKind)availability;

@end

@protocol TMCompletionChunk <NSObject>

- (enum CXCompletionChunkKind)kind;
- (NSString *)text;
- (id<TMCompletionString>)completionString;

@end

@protocol CodeDiagnostic <NSObject>

- (enum CXDiagnosticSeverity)severity;
- (NSString *)spelling;
- (NSUInteger)line;
- (NSRange)range;

@end
