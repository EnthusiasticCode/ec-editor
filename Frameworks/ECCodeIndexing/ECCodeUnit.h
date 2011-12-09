//
//  ECCodeUnit.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <clang-c/Index.h>
@class ECCodeIndex, ECFileBuffer;
@protocol ECCodeCursor, ECCodeCompletionString, ECCodeCompletionChunk, ECCodeCompletionResult;

@protocol ECCodeCompletionResultSet <NSObject>
- (NSUInteger)count;
- (id<ECCodeCompletionResult>)completionResultAtIndex:(NSUInteger)resultIndex;
- (NSUInteger)indexOfHighestRatedCompletionResult;

/// The range of the string in the code unit file buffer used to filter the results.
/// This range is constructed from the offset provided in initialization.
- (NSRange)filterStringRange;

@end

@protocol ECCodeCompletionResult <NSObject>

- (id<ECCodeCompletionString>)completionString;
- (enum CXCursorKind)cursorKind;

@end

@protocol ECCodeCompletionString <NSObject>

- (NSArray *)completionChunks;
- (id<ECCodeCompletionChunk>)typedTextChunk;
- (NSArray *)annotations;
- (unsigned)priority;
- (enum CXAvailabilityKind)availability;

@end

@protocol ECCodeCompletionChunk <NSObject>

- (enum CXCompletionChunkKind)kind;
- (NSString *)text;
- (id<ECCodeCompletionString>)completionString;

@end

@protocol ECCodeDiagnostic <NSObject>

- (enum CXDiagnosticSeverity)severity;
- (NSString *)spelling;
- (NSUInteger)line;
- (NSRange)range;

@end

@protocol ECCodeToken <NSObject>

- (NSRange)range;
- (NSString *)spelling;
- (CXTokenKind)kind;
- (NSString *)scopeIdentifier;
- (NSArray *)scopeIdentifiersStack;
- (id<ECCodeCursor>)cursor;

@end

@protocol ECCodeCursor <NSObject>

@end

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface ECCodeUnit : NSObject

/// The code index that generated the code unit.
- (ECCodeIndex *)index;

/// The main source file the unit is interpreting.
- (ECFileBuffer *)fileBuffer;

- (NSString *)scope;

/// Returns the possible completions at a given insertion point in the unit's main source file.
/// If filterRange is not NULL, in output it will contain the file buffer string range that contains 
/// the substring used for filtering.
- (id<ECCodeCompletionResultSet>)completionsAtOffset:(NSUInteger)offset;

/// Returns warnings and errors in the unit.
- (NSArray *)diagnostics;

/// Returns tokens in the unit's main source file.
- (NSArray *)tokens;
- (NSArray *)annotatedTokens;
- (NSArray *)tokensInRange:(NSRange)range;
- (NSArray *)annotatedTokensInRange:(NSRange)range;

@end
