//
//  ECCodeIndex.h
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ECFoundation/ECFileBuffer.h>
#import <clang-c/Index.h>
@class ECCodeUnit, ECFileBuffer, ECCodeScope;
@protocol ECCodeCursor, ECCodeCompletionString, ECCodeCompletionChunk, ECCodeCompletionResult, ECCodeCompletionResultSet;


/// Class that encapsulates interaction with parsing and indexing libraries to provide language related non file specific functionality such as symbol resolution and refactoring.
@interface ECCodeIndex : NSObject

/// Code unit creation
/// If the scope is not specified, it will be detected automatically
- (ECCodeUnit *)codeUnitForFileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier;

@end


/// Class that encapsulates interaction with parsing and indexing libraries to provide language related file-specific functionality such as syntax aware highlighting, diagnostics and completions.
@interface ECCodeUnit : NSObject <ECFileBufferConsumer>

/// The code index that generated the code unit.
- (ECCodeIndex *)index;

/// The main source file the unit is interpreting.
- (ECFileBuffer *)fileBuffer;

- (NSString *)rootScopeIdentifier;

/// Returns the possible completions at a given insertion point in the unit's main source file.
/// If filterRange is not NULL, in output it will contain the file buffer string range that contains 
/// the substring used for filtering.
- (id<ECCodeCompletionResultSet>)completionsAtOffset:(NSUInteger)offset;

/// Returns warnings and errors in the unit.
- (NSArray *)diagnostics;

@end


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

@protocol ECCodeCursor <NSObject>

@end
