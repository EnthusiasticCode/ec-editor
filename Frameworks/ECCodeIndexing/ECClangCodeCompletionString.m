//
//  ECClangCodeCompletionString.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeCompletionString.h"
#import "ECClangCodeCompletionChunk.h"
#import "ClangHelperFunctions.h"

@interface ECClangCodeCompletionString ()
{
    NSArray *_completionChunks;
    ECClangCodeCompletionChunk *_typedTextChunk;
    NSArray *_annotations;
    unsigned _priority;
    enum CXAvailabilityKind _availability;
}
@end

@implementation ECClangCodeCompletionString

- (id)initWithClangCompletionString:(CXCompletionString)clangCompletionString
{
    self = [super init];
    if (!self)
        return nil;
    NSMutableArray *completionChunks = [NSMutableArray array];
    unsigned numClangCompletionChunks = clang_getNumCompletionChunks(clangCompletionString);
    for (unsigned chunkIndex = 0; chunkIndex < numClangCompletionChunks; ++chunkIndex)
    {
        CXString clangCompletionText = clang_getCompletionChunkText(clangCompletionString, chunkIndex);
        NSString *completionText = [NSString stringWithUTF8String:clang_getCString(clangCompletionText)];
        clang_disposeString(clangCompletionText);
        enum CXCompletionChunkKind clangCompletionKind = clang_getCompletionChunkKind(clangCompletionString, chunkIndex);
        [completionChunks addObject:[[ECClangCodeCompletionChunk alloc] initWithKind:clangCompletionKind text:completionText completionString:(clangCompletionKind == CXCompletionChunk_Optional) ? [[ECClangCodeCompletionString alloc] initWithClangCompletionString:clang_getCompletionChunkCompletionString(clangCompletionString, chunkIndex)] : nil]];
        if (clangCompletionKind == CXCompletionChunk_TypedText)
            _typedTextChunk = [completionChunks lastObject];
    }
    // check for character in the typed text string
#if DEBUG
    ECASSERT(_typedTextChunk);
    NSUInteger textLength = [[_typedTextChunk text] length];
    for (NSUInteger index = 0; index < textLength; ++index)
    {
        ECASSERT([Clang_ValidCompletionTypedTextCharacterSet() characterIsMember:[[_typedTextChunk text] characterAtIndex:index]]);
    }
#endif
    _completionChunks = [completionChunks copy];
    NSMutableArray *annotations = [NSMutableArray array];
    unsigned numClangCompletionAnnotations = clang_getCompletionNumAnnotations(clangCompletionString);
    for (unsigned annotationIndex = 0; annotationIndex < numClangCompletionAnnotations; ++annotationIndex)
    {
        CXString clangAnnotation = clang_getCompletionAnnotation(clangCompletionString, annotationIndex);
        [annotations addObject:[NSString stringWithUTF8String:clang_getCString(clangAnnotation)]];
        clang_disposeString(clangAnnotation);
    }
    _annotations = [annotations copy];
    _priority = clang_getCompletionPriority(clangCompletionString);
    _availability = clang_getCompletionAvailability(clangCompletionString);
    return self;
}

- (NSArray *)completionChunks
{
    return _completionChunks;
}

- (id<ECCodeCompletionChunk>)typedTextChunk
{
    return _typedTextChunk;
}

- (NSArray *)annotations
{
    return _annotations;
}

- (unsigned)priority
{
    return _priority;
}

- (enum CXAvailabilityKind)availability
{
    return _availability;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString string];
    for (ECClangCodeCompletionChunk *chunk in _completionChunks)
        [description appendString:[chunk text]];
    return description;
}

@end
