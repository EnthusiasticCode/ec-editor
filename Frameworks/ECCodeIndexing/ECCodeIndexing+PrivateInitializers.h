//
//  ECCodeIndexing+PrivateInitializers.h
//  ECCodeIndexing
//
//  Created by Uri Baghin on 9/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeIndex.h"
#import "ECCodeUnit.h"
#import "ECCodeCompletionResult.h"
#import "ECCodeCompletionString.h"
#import "ECCodeCompletionChunk.h"
#import "ECCodeDiagnostic.h"
#import "ECCodeFixIt.h"
#import "ECCodeToken.h"

@interface ECCodeUnit (PrivateInitializers)
- (id)initWithIndex:(ECCodeIndex *)index fileURL:(NSURL *)fileURL language:(NSString *)language;
@end

@interface ECCodeCompletionChunk (PrivateInitializers)
- (id)initWithKind:(ECCodeCompletionChunkKind)kind string:(NSString *)string;
@end

@interface ECCodeCompletionResult (PrivateInitializers)
- (id)initWithCursorKind:(ECCodeCursorKind)cursorKind completionString:(ECCodeCompletionString *)completionString;
@end

@interface ECCodeCompletionString (PrivateInitializers)
- (id)initWithCompletionChunks:(NSArray *)completionChunks;
@end

@interface ECCodeDiagnostic (PrivateInitializers)
- (id)initWithSeverity:(ECCodeDiagnosticSeverity)severity fileURL:(NSURL *)fileURL offset:(NSUInteger)offset spelling:(NSString *)spelling category:(NSString *)category sourceRanges:(NSArray *)sourceRanges fixIts:(NSArray *)fixIts;
@end

@interface ECCodeFixIt (PrivateInitializers)
- (id)initWithString:(NSString *)string fileURL:(NSURL *)fileURL replacementRange:(NSRange)replacementRange;
@end

@interface ECCodeToken (PrivateInitializers)
- (id)initWithKind:(ECCodeTokenKind)kind spelling:(NSString *)spelling fileURL:(NSURL *)fileURL offset:(NSUInteger )offset extent:(NSRange)extent cursor:(ECCodeCursor *)cursor;
@end
