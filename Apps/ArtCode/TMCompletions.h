//
//  TMCompletions.h
//  ArtCode
//
//  Created by Uri Baghin on 4/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TMCompletionResult, TMCompletionString, TMCompletionChunk;

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
