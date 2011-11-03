//
//  TMCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMCodeParser.h"
#import "TMBundle.h"
#import "TMSyntax.h"
#import "TMPattern.h"
#import "OnigRegexp.h"

static NSString * const _patternCaptureName = @"name";

static NSRange _rangeFromEndOfRangeToEndOfRange(NSRange firstRange, NSRange secondRange)
{
    return NSMakeRange(NSMaxRange(firstRange), NSMaxRange(secondRange) - NSMaxRange(firstRange));
}

@interface TMCodeParser ()
{
    NSURL *_presentedItemURL;
    NSOperationQueue *_presentedItemOperationQueue;
    TMSyntax *_syntax;
    TMCodeIndex *_index;
    NSMutableDictionary *_firstBeginMatches;
    NSMutableDictionary *_firstEndMatches;
}
// presentedItemURL needs to be declared as assign because it's declared as assign in the protocol, it is however backed by a strong ivar
@property (assign) NSURL *presentedItemURL;
- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withIncludePattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withMatchPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withSpanPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withChildPatternsOfPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (OnigResult *)_firstBeginMatchInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range forRegexp:(OnigRegexp *)regexp;
- (OnigResult *)_firstEndMatchInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range forRegexp:(OnigRegexp *)regexp;
- (OnigResult *)_firstMatchInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range forRegexp:(OnigRegexp *)regexp cache:(NSMutableDictionary *)matchesCache;
@end

@implementation TMCodeParser

- (NSURL *)fileURL
{
    return self.presentedItemURL;
}

+ (NSSet *)keyPathsForValuesAffectingFileURL
{
    return [NSSet setWithObject:@"presentedItemURL"];
}

- (ECCodeIndex *)index
{
    return _index;
}

- (NSString *)language
{
    return _syntax.name;
}

- (id)initWithIndex:(TMCodeIndex *)index fileURL:(NSURL *)fileURL syntax:(TMSyntax *)syntax
{
    ECASSERT(index);
    ECASSERT([fileURL isFileURL]);
    ECASSERT(syntax);
    self = [super init];
    if (!self)
        return nil;
    _index = index;
    _presentedItemURL = fileURL;
    _syntax = syntax;
    return self;
}

- (void)visitScopesInRange:(NSRange)range usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (!visitorBlock)
        return;
    _firstBeginMatches = [NSMutableDictionary dictionary];
    _firstEndMatches = [NSMutableDictionary dictionary];
    [_syntax beginContentAccess];
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateReadingItemAtURL:self.fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:NULL]];
        ECASSERT(NSMaxRange(range) <= [attributedString length]);
        NSMutableArray *scopesStack = [NSMutableArray arrayWithObject:_syntax.scope];
        [self _visitScopesInAttributedString:attributedString range:range withPattern:_syntax.pattern previousScopeStack:scopesStack usingVisitor:visitorBlock];
    }];
    [_syntax endContentAccess];
    _firstBeginMatches = nil;
    _firstEndMatches = nil;
}

- (void)visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (!visitorBlock)
        return;
    _firstBeginMatches = [NSMutableDictionary dictionary];
    _firstEndMatches = [NSMutableDictionary dictionary];
    [_syntax beginContentAccess];
    ECASSERT(NSMaxRange(range) <= [attributedString length]);
    NSMutableArray *scopesStack = [NSMutableArray arrayWithObject:_syntax.scope];
    [self _visitScopesInAttributedString:attributedString range:range withPattern:_syntax.pattern previousScopeStack:scopesStack usingVisitor:visitorBlock];
    [_syntax endContentAccess];
    _firstBeginMatches = nil;
    _firstEndMatches = nil;
}

#pragma mark - NSFileCoordination

- (NSURL *)presentedItemURL
{
    return _presentedItemURL;
}

- (void)setPresentedItemURL:(NSURL *)presentedItemURL
{
    if (presentedItemURL == _presentedItemURL)
        return;
    [self willChangeValueForKey:@"presentedItemURL"];
    @synchronized(self)
    {
        _presentedItemURL = presentedItemURL;
    }
    [self didChangeValueForKey:@"presentedItemURL"];
}

- (NSOperationQueue *)presentedItemOperationQueue
{
    if (!_presentedItemOperationQueue)
    {
        _presentedItemOperationQueue = [[NSOperationQueue alloc] init];
        _presentedItemOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _presentedItemOperationQueue;
}

- (void)presentedItemDidMoveToURL:(NSURL *)newURL
{
    self.presentedItemURL = newURL;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler
{
    self.presentedItemURL = nil;
}

#pragma mark - Private methods

- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    ECASSERT([attributedString length] && NSMaxRange(range) <= [attributedString length] && pattern && previousScopeStack && visitorBlock);
    ECASSERT(pattern.include || pattern.match || pattern.begin || pattern.patterns);
    if (pattern.include)
        [self _visitScopesInAttributedString:attributedString range:range withIncludePattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else if (pattern.match)
        [self _visitScopesInAttributedString:attributedString range:range withMatchPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else if (pattern.begin)
        [self _visitScopesInAttributedString:attributedString range:range withSpanPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else
        [self _visitScopesInAttributedString:attributedString range:range withChildPatternsOfPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
}

- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withIncludePattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    unichar firstCharacter = [pattern.include characterAtIndex:0];
    if (firstCharacter == '$')
    {
        [self _visitScopesInAttributedString:attributedString range:range withPattern:_syntax.pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    }
    else if (firstCharacter == '#')
    {
        [self _visitScopesInAttributedString:attributedString range:range withPattern:[_syntax.repository objectForKey:[pattern.include substringFromIndex:1]] previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    }
    else
    {
        [previousScopeStack addObject:pattern.include];
        id<ECCodeParser> codeParser = (id<ECCodeParser>)[self.index codeUnitImplementingProtocol:@protocol(ECCodeParser) withFile:self.fileURL language:nil scope:pattern.include];
        [codeParser visitScopesInAttributedString:attributedString range:range usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isExitingScope, BOOL isLeafScope, NSArray *scopesStack) {
            return visitorBlock(scope, scopeRange, isExitingScope, isLeafScope, [previousScopeStack arrayByAddingObjectsFromArray:scopesStack]);
        }];
        [previousScopeStack removeObject:pattern.include];
    }
}

- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withMatchPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (pattern.name)
        [previousScopeStack addObject:pattern.name];
    OnigResult *result = [self _firstBeginMatchInAttributedString:attributedString range:range forRegexp:pattern.match];
    if (pattern.captures)
        while (result)
        {
            ECASSERT([result count] > 1);
            ECCodeVisitorResult visitorResult = visitorBlock(pattern.name, [result rangeAt:0], NO, NO, [previousScopeStack copy]);
            if (visitorResult == ECCodeVisitorResultBreak)
                break;
            else if (visitorResult == ECCodeVisitorResultRecurse)
            {
                NSUInteger numMatchRanges = [result count];
                for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
                {
                    NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
                    NSString *currentCaptureName = [[pattern.captures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_patternCaptureName];
                    if (!currentCaptureName)
                        continue;
                    [previousScopeStack addObject:currentCaptureName];
                    visitorResult = visitorBlock(currentCaptureName, currentMatchRange, YES, NO, [previousScopeStack copy]);
                    [previousScopeStack removeLastObject];
                    if (visitorResult == ECCodeVisitorResultBreak)
                        break;
                }
            }
            if (visitorResult == ECCodeVisitorResultBreak)
                break;
            visitorResult = visitorBlock(pattern.name, [result rangeAt:0], NO, YES, [previousScopeStack copy]);
            if (visitorResult == ECCodeVisitorResultBreak)
                break;
            result = [self _firstBeginMatchInAttributedString:attributedString range:_rangeFromEndOfRangeToEndOfRange([result rangeAt:0], range) forRegexp:pattern.match];
        }
    else
        while (result)
        {
            ECASSERT(pattern.name);
            ECCodeVisitorResult visitorResult = visitorBlock(pattern.name, [result rangeAt:0], YES, NO, [previousScopeStack copy]);
            if (visitorResult == ECCodeVisitorResultBreak)
                break;
            result = [self _firstBeginMatchInAttributedString:attributedString range:_rangeFromEndOfRangeToEndOfRange([result rangeAt:0], range) forRegexp:pattern.match];
        }
    if (pattern.name)
        [previousScopeStack removeLastObject];
}

- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withSpanPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (pattern.name)
        [previousScopeStack addObject:pattern.name];
    OnigResult *result = [self _firstBeginMatchInAttributedString:attributedString range:range forRegexp:pattern.begin];
    while (result)
    {
        OnigResult *endMatch = [self _firstEndMatchInAttributedString:attributedString range:_rangeFromEndOfRangeToEndOfRange([result rangeAt:0], range) forRegexp:pattern.end];
        ECASSERT(!endMatch || [endMatch rangeAt:0].location >= NSMaxRange([result rangeAt:0]));
        NSUInteger spanStart = [result rangeAt:0].location;
        NSUInteger spanEnd = endMatch ? NSMaxRange([endMatch rangeAt:0]) : NSMaxRange(range);
        NSUInteger childScopesStart = NSMaxRange([result rangeAt:0]);
        NSUInteger childScopesEnd = endMatch ? [endMatch rangeAt:0].location : NSMaxRange(range);
        NSRange spanRange = NSMakeRange(spanStart, spanEnd - spanStart);
        NSRange childScopesRange = NSMakeRange(childScopesStart, childScopesEnd - childScopesStart);
        __block ECCodeVisitorResult visitorResult = ECCodeVisitorResultRecurse;
        if (pattern.name)
            visitorResult = visitorBlock(pattern.name, spanRange, NO, NO, [previousScopeStack copy]);
        if (visitorResult == ECCodeVisitorResultBreak)
            break;
        else if (visitorResult == ECCodeVisitorResultRecurse)
        {
            if (pattern.beginCaptures)
            {
                NSString *mainCaptureName = [[pattern.beginCaptures objectForKey:[NSString stringWithFormat:@"%d", 0]] objectForKey:_patternCaptureName];
                NSUInteger numMatchRanges = [result count];
                if (mainCaptureName)
                {
                    [previousScopeStack addObject:mainCaptureName];
                    visitorResult = visitorBlock(mainCaptureName, [result rangeAt:0], numMatchRanges > 1 ? NO : YES, NO, [previousScopeStack copy]);
                    if (visitorResult == ECCodeVisitorResultBreak)
                    {
                        [previousScopeStack removeLastObject];
                        break;
                    }
                }
                if (visitorResult == ECCodeVisitorResultRecurse)
                {
                    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
                    {
                        NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
                        NSString *currentCaptureName = [[pattern.beginCaptures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_patternCaptureName];
                        if (!currentCaptureName)
                            continue;
                        [previousScopeStack addObject:currentCaptureName];
                        visitorResult = visitorBlock(currentCaptureName, currentMatchRange, YES, NO, [previousScopeStack copy]);
                        [previousScopeStack removeLastObject];
                        if (visitorResult == ECCodeVisitorResultBreak)
                            break;
                    }
                }
                if (mainCaptureName && numMatchRanges > 1)
                {
                    if (visitorResult != ECCodeVisitorResultBreak)
                        visitorResult = visitorBlock(mainCaptureName, [result rangeAt:0], NO, YES, [previousScopeStack copy]);
                    [previousScopeStack removeLastObject];
                }
                if (visitorResult == ECCodeVisitorResultBreak)
                    break;
            }
            if (childScopesRange.length)
                [self _visitScopesInAttributedString:attributedString range:childScopesRange withChildPatternsOfPattern:pattern previousScopeStack:previousScopeStack usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
                    visitorResult = visitorBlock(scope, scopeRange, isLeafScope, isExitingScope, scopesStack);
                    return visitorResult;
                }];
            if (visitorResult == ECCodeVisitorResultBreak)
                break;
            if (pattern.endCaptures && endMatch)
            {
                NSString *mainCaptureName = [[pattern.endCaptures objectForKey:[NSString stringWithFormat:@"%d", 0]] objectForKey:_patternCaptureName];
                NSUInteger numMatchRanges = [endMatch count];
                if (mainCaptureName)
                {
                    [previousScopeStack addObject:mainCaptureName];
                    visitorResult = visitorBlock(mainCaptureName, [endMatch rangeAt:0], numMatchRanges > 1 ? NO : YES, NO, [previousScopeStack copy]);
                    if (visitorResult == ECCodeVisitorResultBreak)
                    {
                        [previousScopeStack removeLastObject];
                        break;
                    }
                }
                if (visitorResult == ECCodeVisitorResultRecurse)
                {
                    NSUInteger numMatchRanges = [endMatch count];
                    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
                    {
                        NSRange currentMatchRange = [endMatch rangeAt:currentMatchRangeIndex];
                        NSString *currentCaptureName = [[pattern.beginCaptures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_patternCaptureName];
                        if (!currentCaptureName)
                            continue;
                        [previousScopeStack addObject:currentCaptureName];
                        visitorResult = visitorBlock(currentCaptureName, currentMatchRange, YES, NO, [previousScopeStack copy]);
                        [previousScopeStack removeLastObject];
                        if (visitorResult == ECCodeVisitorResultBreak)
                            break;
                    }
                }
                if (mainCaptureName && numMatchRanges > 1)
                {
                    if (visitorResult != ECCodeVisitorResultBreak)
                        visitorResult = visitorBlock(mainCaptureName, [endMatch rangeAt:0], NO, YES, [previousScopeStack copy]);
                    [previousScopeStack removeLastObject];
                }
                if (visitorResult == ECCodeVisitorResultBreak)
                    break;
            }
        }
        if (pattern.name)
            visitorResult = visitorBlock(pattern.name, spanRange, NO, YES, [previousScopeStack copy]);
        if (visitorResult == ECCodeVisitorResultBreak)
            break;
        if (endMatch)
            [self _firstBeginMatchInAttributedString:attributedString range:_rangeFromEndOfRangeToEndOfRange([endMatch rangeAt:0], range) forRegexp:pattern.begin];
        else
            break;
    }
    if (pattern.name)
        [previousScopeStack removeLastObject];
}

- (void)_visitScopesInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range withChildPatternsOfPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    NSRange currentRange = range;
    for (;;)
    {
        __block NSRange firstMatchRange = NSMakeRange(NSNotFound, 0);
        __block TMPattern *firstMatchPattern = nil;
        for (TMPattern *childPattern in pattern.patterns)
            [self _visitScopesInAttributedString:attributedString range:currentRange withPattern:childPattern previousScopeStack:previousScopeStack usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
                if (scopeRange.location < firstMatchRange.location || (scopeRange.location == firstMatchRange.location && scopeRange.length > firstMatchRange.length))
                {
                    firstMatchRange = scopeRange;
                    firstMatchPattern = childPattern;
                }
                return ECCodeVisitorResultBreak;
            }];
        if (!firstMatchPattern)
            break;
        __block NSUInteger stackDepth = 0;
        __block ECCodeVisitorResult visitorResult = ECCodeVisitorResultRecurse;
        [self _visitScopesInAttributedString:attributedString range:currentRange withPattern:firstMatchPattern previousScopeStack:previousScopeStack usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
            visitorResult = visitorBlock(scope, scopeRange, isLeafScope, isExitingScope, scopesStack);
            if (!isLeafScope)
                if (isExitingScope)
                    --stackDepth;
                else
                    ++stackDepth;
            if (!stackDepth)
                return ECCodeVisitorResultBreak;
            return visitorResult;
        }];
        if (visitorResult == ECCodeVisitorResultBreak)
            break;
        NSUInteger offset = NSMaxRange(firstMatchRange) - currentRange.location;
        ECASSERT(currentRange.length >= offset);
        currentRange.location += offset;
        currentRange.length -= offset;
        if (!currentRange.length)
            break;
    }
}

- (OnigResult *)_firstBeginMatchInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range forRegexp:(OnigRegexp *)regexp
{
    return [self _firstMatchInAttributedString:attributedString range:range forRegexp:regexp cache:_firstBeginMatches];
}

- (OnigResult *)_firstEndMatchInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range forRegexp:(OnigRegexp *)regexp
{
    return [self _firstMatchInAttributedString:attributedString range:range forRegexp:regexp cache:_firstEndMatches];
}

- (OnigResult *)_firstMatchInAttributedString:(NSMutableAttributedString *)attributedString range:(NSRange)range forRegexp:(OnigRegexp *)regexp cache:(NSMutableDictionary *)matchesCache
{
    OnigResult *result = [matchesCache objectForKey:regexp];
    if (result && (id)result != [NSNull null] && [result rangeAt:0].location >= range.location && NSMaxRange([result rangeAt:0]) <= NSMaxRange(range))
        return result;
    if ((id)result == [NSNull null])
        return nil;
    result = [regexp search:[attributedString string] range:range];
    if (result)
        [matchesCache setObject:result forKey:regexp];
    else
        [matchesCache setObject:[NSNull null] forKey:regexp];
    return result;
}

@end
