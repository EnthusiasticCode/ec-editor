//
//  ECClangCodeCompletionResultSet.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeCompletionResultSet.h"
#import "ECClangCodeUnit.h"
#import "ECClangCodeCompletionResult.h"

@interface ECClangCodeCompletionResultSet ()
{
    ECClangCodeUnit *_codeUnit;
    CXCodeCompleteResults *_clangResults;
}
@end

@implementation ECClangCodeCompletionResultSet

- (id)initWithCodeUnit:(ECClangCodeUnit *)codeUnit atOffset:(NSUInteger)offset
{
    ECASSERT(codeUnit);
    self = [super init];
    if (!self)
        return nil;
    _codeUnit = codeUnit;
    CXTranslationUnit clangTranslationUnit = [codeUnit clangTranslationUnit];
    const char *fileName = [[[codeUnit fileURL] path] fileSystemRepresentation];
    CXFile clangFile = clang_getFile(clangTranslationUnit, fileName);
    CXSourceLocation completeLocation = clang_getLocationForOffset(clangTranslationUnit, clangFile, offset);
    unsigned int completeLine;
    unsigned int completeColumn;
    clang_getInstantiationLocation(completeLocation, NULL, &completeLine, &completeColumn, NULL);
    _clangResults = clang_codeCompleteAt(clangTranslationUnit, fileName, completeLine, completeColumn, NULL, 0, clang_defaultCodeCompleteOptions());
    clang_sortCodeCompletionResults(_clangResults->Results, _clangResults->NumResults);
    return self;
}

- (void)dealloc
{
    clang_disposeCodeCompleteResults(_clangResults);
}

- (NSUInteger)count
{
    return _clangResults->NumResults;
}

- (id<ECCodeCompletionResult>)completionResultAtIndex:(NSUInteger)resultIndex
{
    return [[ECClangCodeCompletionResult alloc] initWithClangCompletionResult:_clangResults->Results[resultIndex]];
}

- (NSUInteger)indexOfHighestRatedCompletionResult
{
    NSUInteger index = NSNotFound;
    // priority in clang is the inverse of rating, lowest priority means highest rating
    NSUInteger priority = NSUIntegerMax;
    for (unsigned int resultIndex = 0; resultIndex < _clangResults->NumResults; ++resultIndex)
    {
        NSUInteger currentPriority = clang_getCompletionPriority(_clangResults->Results[resultIndex].CompletionString);
        if (currentPriority >= priority)
            continue;
        index = resultIndex;
        priority = currentPriority;
    }
    return index;
}

@end
