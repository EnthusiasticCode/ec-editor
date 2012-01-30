//
//  TMUnit.h
//  CodeIndexing
//
//  Created by Uri Baghin on 1/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileBuffer.h"
#import <clang-c/Index.h>
@class TMIndex;
@protocol TMCompletionResultSet, TMCompletionResult, TMCompletionString, TMCompletionChunk;

typedef enum
{
    TMUnitVisitOptionsAbsoluteRange = 0 << 0,
    TMUnitVisitOptionsRelativeRange = 1 << 0,
} TMUnitVisitOptions;

typedef enum
{
    TMUnitVisitResultBreak,
    TMUnitVisitResultContinue,
    TMUnitVisitResultRecurse,
} TMUnitVisitResult;

/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface TMUnit : NSObject <FileBufferConsumer>

/// The code index that generated the code unit.
- (TMIndex *)index;

/// The main source file the unit is interpreting.
- (FileBuffer *)fileBuffer;

- (NSString *)rootScopeIdentifier;

/// Visit the scopes in the unit.
/// All the parameters passed to the block are only valid until the block returns, and should not be modified

- (void)visitScopesWithBlock:(TMUnitVisitResult(^)(NSString *scopeIdentifier, NSRange range, NSMutableArray *scopeIdentifiersStack))block;

- (void)visitScopesInRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult(^)(NSString *scopeIdentifier, NSRange range, NSMutableArray *scopeIdentifiersStack))block;

/// Returns the possible completions at a given insertion point in the unit's main source file.
/// If filterRange is not NULL, in output it will contain the file buffer string range that contains 
/// the substring used for filtering.
- (id<TMCompletionResultSet>)completionsAtOffset:(NSUInteger)offset;

/// Returns warnings and errors in the unit.
- (NSArray *)diagnostics;

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

@protocol TMCursor <NSObject>

@end
