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
#import "ClangHelperFunctions.h"
#import <ECFoundation/ECFileBuffer.h>

@interface ECClangCodeCompletionResultSet ()
{
    ECCodeUnit *_codeUnit;
    CXCodeCompleteResults *_clangResults;
    NSRange _filteredResultRange;
    NSRange _filterStringRange;
}
@end

@implementation ECClangCodeCompletionResultSet

- (id)initWithCodeUnit:(ECCodeUnit *)codeUnit atOffset:(NSUInteger)offset
{
    ECASSERT(codeUnit);
    self = [super init];
    if (!self)
        return nil;

    NSInteger firstCharacterIndex;
    NSString *content = [[codeUnit fileBuffer] stringInRange:NSMakeRange(0, [[codeUnit fileBuffer] length])];
    for (firstCharacterIndex = offset - 1; firstCharacterIndex >= 0; --firstCharacterIndex)
    {
        if ([Clang_ValidCompletionTypedTextCharacterSet() characterIsMember:[content characterAtIndex:firstCharacterIndex]])
            continue;
        break;
    }
    ++firstCharacterIndex;

    _codeUnit = codeUnit;
    CXTranslationUnit clangTranslationUnit = 0;// [codeUnit clangTranslationUnit];
    const char *fileName = [[[[codeUnit fileBuffer] fileURL] path] fileSystemRepresentation];
    CXFile clangFile = clang_getFile(clangTranslationUnit, fileName);
    CXSourceLocation completeLocation = clang_getLocationForOffset(clangTranslationUnit, clangFile, firstCharacterIndex);
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
    
    _filterStringRange = NSMakeRange(firstCharacterIndex, offset - firstCharacterIndex);
    if (_filterStringRange.length)
    {
        NSString *filterString = [content substringWithRange:_filterStringRange];
        NSRange comparisonRange = NSMakeRange(0, [filterString length]);
        NSUInteger currentPosition = 0;
        NSUInteger lastLesserIndex = 0;
        NSUInteger firstEqualIndex = NSNotFound;
        NSUInteger lastEqualIndex = NSNotFound;
        NSUInteger firstGreaterIndex = _clangResults->NumResults - 1;
        while (firstGreaterIndex > lastLesserIndex + 1)
        {
            currentPosition = lastLesserIndex + ((firstGreaterIndex - lastLesserIndex) / 2);
            ECClangCodeCompletionResult *currentResult = [[ECClangCodeCompletionResult alloc] initWithClangCompletionResult:_clangResults->Results[currentPosition]];
            NSComparisonResult currentComparisonResult = [[[[currentResult completionString] typedTextChunk] text] compare:filterString options:NSCaseInsensitiveSearch | NSLiteralSearch range:comparisonRange];
            if (currentComparisonResult == NSOrderedAscending)
                lastLesserIndex = currentPosition;
            else if (currentComparisonResult == NSOrderedDescending)
                firstGreaterIndex = currentPosition;
            else
            {
                firstEqualIndex = currentPosition;
                lastEqualIndex = currentPosition;
                break;
            }
        }
        if (firstEqualIndex != NSNotFound)
        {
            while (firstEqualIndex > lastLesserIndex + 1)
            {
                currentPosition = lastLesserIndex + ((firstEqualIndex - lastLesserIndex) / 2);
                ECClangCodeCompletionResult *currentResult = [[ECClangCodeCompletionResult alloc] initWithClangCompletionResult:_clangResults->Results[currentPosition]];
                NSComparisonResult currentComparisonResult = [[[[currentResult completionString] typedTextChunk] text] compare:filterString options:NSCaseInsensitiveSearch | NSLiteralSearch range:comparisonRange];
                if (currentComparisonResult == NSOrderedAscending)
                    lastLesserIndex = currentPosition;
                else
                    firstEqualIndex = currentPosition;
            }
            while (firstGreaterIndex > lastEqualIndex + 1)
            {
                currentPosition = lastEqualIndex + ((firstGreaterIndex - lastEqualIndex) / 2);
                ECClangCodeCompletionResult *currentResult = [[ECClangCodeCompletionResult alloc] initWithClangCompletionResult:_clangResults->Results[currentPosition]];
                NSComparisonResult currentComparisonResult = [[[[currentResult completionString] typedTextChunk] text] compare:filterString options:NSCaseInsensitiveSearch | NSLiteralSearch range:comparisonRange];
                if (currentComparisonResult == NSOrderedDescending)
                    firstGreaterIndex = currentPosition;
                else
                    lastEqualIndex = currentPosition;
            }
            _filteredResultRange = NSMakeRange(firstEqualIndex, lastEqualIndex - firstEqualIndex + 1);
        }
        else
            _filteredResultRange = NSMakeRange(lastLesserIndex, 0);
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
    NSInteger resultRangeEnd = NSMaxRange(_filteredResultRange);
    for (NSInteger resultIndex = _filteredResultRange.location; resultIndex < resultRangeEnd; ++resultIndex)
    {
        NSUInteger currentPriority = clang_getCompletionPriority(_clangResults->Results[resultIndex].CompletionString);
        if (currentPriority >= priority)
            continue;
        index = resultIndex;
        priority = currentPriority;
    }
    return index - _filteredResultRange.location;
}

- (NSRange)filterStringRange
{
    return _filterStringRange;
}

@end
