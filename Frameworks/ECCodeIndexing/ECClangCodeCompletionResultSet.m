//
//  ECClangCodeCompletionResultSet.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/9/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECClangCodeCompletionResultSet.h"
#import "ECClangCodeUnit.h"
#import "ECCodeIndex+Subclass.h"
#import "ECClangCodeCompletionResult.h"
#import "ClangHelperFunctions.h"

@interface ECClangCodeCompletionResultSet ()
{
    ECClangCodeUnit *_codeUnit;
    CXCodeCompleteResults *_clangResults;
    NSRange _filteredResultRange;
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
    if (!_clangResults->NumResults)
    {
        _filteredResultRange = NSMakeRange(0, 0);
        return self;
    }
    clang_sortCodeCompletionResults(_clangResults->Results, _clangResults->NumResults);
    NSInteger firstCharacterIndex;
    NSString *content = [[codeUnit index] contentsForFile:[codeUnit fileURL]];
    for (firstCharacterIndex = offset - 1; firstCharacterIndex >= 0; --firstCharacterIndex)
    {
        if ([Clang_ValidCompletionTypedTextCharacterSet() characterIsMember:[content characterAtIndex:firstCharacterIndex]])
            continue;
        break;
    }
    ++firstCharacterIndex;
    NSRange filterStringRange = NSMakeRange(firstCharacterIndex, offset - firstCharacterIndex);
    if (filterStringRange.length)
    {
        NSString *filterString = [content substringWithRange:filterStringRange];
        NSUInteger rangeStart = 0;
        NSUInteger lastLesserIndex = 0;
        NSUInteger firstEqualIndex = _clangResults->NumResults - 1;
        while (firstEqualIndex != lastLesserIndex + 1)
       {
            rangeStart = lastLesserIndex + ((firstEqualIndex - lastLesserIndex) / 2);
            ECClangCodeCompletionResult *startResult = [[ECClangCodeCompletionResult alloc] initWithClangCompletionResult:_clangResults->Results[rangeStart]];
            NSComparisonResult startComparisonResult = [[[[startResult completionString] typedTextChunk] text] compare:filterString];
            if (startComparisonResult == NSOrderedAscending)
                lastLesserIndex = rangeStart;
            else
                firstEqualIndex = rangeStart;
        }
        NSUInteger rangeEnd = _clangResults->NumResults - 1;
        NSUInteger lastEqualIndex = 0;
        NSUInteger firstGreaterIndex = _clangResults->NumResults - 1;
        while (firstGreaterIndex != lastEqualIndex + 1)
        {
            rangeEnd = lastEqualIndex + ((firstGreaterIndex - lastEqualIndex) / 2);
            ECClangCodeCompletionResult *endResult = [[ECClangCodeCompletionResult alloc] initWithClangCompletionResult:_clangResults->Results[rangeEnd]];
            NSComparisonResult endComparisonResult = [[[[endResult completionString] typedTextChunk] text] compare:filterString];
            if (endComparisonResult == NSOrderedDescending)
                firstGreaterIndex = rangeEnd;
            else
                lastEqualIndex = rangeEnd;
        }
        _filteredResultRange = NSMakeRange(rangeStart, rangeEnd - rangeStart);
    }
    else
        _filteredResultRange = NSMakeRange(0, _clangResults->NumResults);
    return self;
}

- (void)dealloc
{
    clang_disposeCodeCompleteResults(_clangResults);
}

- (NSUInteger)count
{
    return _filteredResultRange.length;
}

- (id<ECCodeCompletionResult>)completionResultAtIndex:(NSUInteger)resultIndex
{
    return [[ECClangCodeCompletionResult alloc] initWithClangCompletionResult:_clangResults->Results[resultIndex + _filteredResultRange.location]];
}

- (NSUInteger)indexOfHighestRatedCompletionResult
{
    NSUInteger index = NSNotFound;
    // priority in clang is the inverse of rating, lowest priority means highest rating
    NSUInteger priority = NSUIntegerMax;
    NSInteger lastResultIndex = NSMaxRange(_filteredResultRange) - 1;
    for (unsigned int resultIndex = _filteredResultRange.location; resultIndex < lastResultIndex; ++resultIndex)
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
