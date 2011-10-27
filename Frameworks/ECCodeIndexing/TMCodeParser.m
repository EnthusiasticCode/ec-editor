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

static NSRange _rangeFromEndOfRangeToEndOfRange(NSRange firstRange, NSRange secondRange)
{
    return NSMakeRange(NSMaxRange(firstRange), NSMaxRange(secondRange) - NSMaxRange(firstRange));
}

@interface TMCodeParser ()
{
    NSURL *_presentedItemURL;
    NSOperationQueue *_presentedItemOperationQueue;
    NSInteger _contentAccessCount;
    TMSyntax *_syntax;
    TMCodeIndex *_index;
}
// presentedItemURL needs to be declared as assign because it's declared as assign in the protocol, it is however backed by a strong ivar
@property (assign) NSURL *presentedItemURL;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withIncludePattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withMatchPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withSpanPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withChildPatternsOfPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock;
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
    _contentAccessCount = 1;
    _index = index;
    _presentedItemURL = fileURL;
    _syntax = syntax;
    return self;
}

- (void)visitScopesInRange:(NSRange)range usingVisitor:(ECCodeVisitor)visitorBlock
{
    ECASSERT(_contentAccessCount > 0);
    if (!visitorBlock)
        return;
    __block NSString *string = nil;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
    [fileCoordinator coordinateReadingItemAtURL:self.fileURL options:NSFileCoordinatorReadingResolvesSymbolicLink error:NULL byAccessor:^(NSURL *newURL) {
        string = [NSString stringWithContentsOfURL:newURL encoding:NSUTF8StringEncoding error:NULL];
        ECASSERT(NSMaxRange(range) <= [string length]);
        NSMutableArray *scopesStack = [NSMutableArray arrayWithObject:_syntax.scope];
        [self _visitScopesInString:string range:range withPattern:_syntax.pattern previousScopeStack:scopesStack usingVisitor:visitorBlock];
    }];
}

#pragma mark - NSDiscardableContent

- (BOOL)beginContentAccess
{
    ++_contentAccessCount;
    return YES;
}

- (void)endContentAccess
{
    ECASSERT(_contentAccessCount > 0);
    --_contentAccessCount;
}

- (void)discardContentIfPossible
{
    ECASSERT(_contentAccessCount >= 0);
}

- (BOOL)isContentDiscarded
{
    ECASSERT(_contentAccessCount > 0);
    return !_contentAccessCount;
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

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    ECASSERT([string length] && NSMaxRange(range) <= [string length] && pattern && previousScopeStack && visitorBlock);
    ECASSERT(pattern.include || pattern.match || pattern.begin || pattern.patterns);
    if (pattern.include)
        [self _visitScopesInString:string range:range withIncludePattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else if (pattern.match)
        [self _visitScopesInString:string range:range withMatchPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else if (pattern.begin)
        [self _visitScopesInString:string range:range withSpanPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    else
        [self _visitScopesInString:string range:range withChildPatternsOfPattern:pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
}

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withIncludePattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    unichar firstCharacter = [pattern.include characterAtIndex:0];
    if (firstCharacter == '$')
    {
        [self _visitScopesInString:string range:range withPattern:_syntax.pattern previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    }
    else if (firstCharacter == '#')
    {
        [self _visitScopesInString:string range:range withPattern:[_syntax.repository objectForKey:[pattern.include substringFromIndex:1]] previousScopeStack:previousScopeStack usingVisitor:visitorBlock];
    }
    else
    {
        [previousScopeStack addObject:pattern.include];
        [[self.index codeUnitImplementingProtocol:@protocol(ECCodeParser) withFile:self.fileURL language:nil scope:pattern.include] visitScopesInRange:range usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isExitingScope, BOOL isLeafScope, NSArray *scopesStack) {
            return visitorBlock(scope, scopeRange, isExitingScope, isLeafScope, [previousScopeStack arrayByAddingObjectsFromArray:scopesStack]);
        }];
        [previousScopeStack removeObject:pattern.include];
    }
}

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withMatchPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (pattern.name)
        [previousScopeStack addObject:pattern.name];
    if (pattern.captures)
    {
        OnigResult *result = [pattern.match search:string range:range];
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
                    NSString *currentCapture = [pattern.captures objectForKey:[NSNumber numberWithUnsignedInteger:currentMatchRangeIndex]];
                    if (!currentCapture)
                        continue;
                    [previousScopeStack addObject:currentCapture];
                    visitorResult = visitorBlock(currentCapture, currentMatchRange, YES, NO, [previousScopeStack copy]);
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
            result = [pattern.match search:string range:_rangeFromEndOfRangeToEndOfRange([result rangeAt:0], range)];
        }
    }
    else
    {
        OnigResult *result = [pattern.match search:string range:range];
        while (result)
        {
            ECASSERT(pattern.name);
            ECCodeVisitorResult visitorResult = visitorBlock(pattern.name, [result rangeAt:0], YES, NO, [previousScopeStack copy]);
            if (visitorResult == ECCodeVisitorResultBreak)
                break;
            result = [pattern.match search:string range:_rangeFromEndOfRangeToEndOfRange([result rangeAt:0], range)];
        }
    }
    if (pattern.name)
        [previousScopeStack removeLastObject];
}

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withSpanPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    if (pattern.name)
        [previousScopeStack addObject:pattern.name];
    OnigResult *result = [pattern.begin search:string range:range];
    while (result)
    {
        OnigResult *endMatch = [pattern.end search:string range:_rangeFromEndOfRangeToEndOfRange([result rangeAt:0], range)];
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
                NSString *mainCapture = [pattern.beginCaptures objectForKey:[NSNumber numberWithUnsignedInteger:0]];
                if (mainCapture)
                {
                    [previousScopeStack addObject:mainCapture];
                    visitorResult = visitorBlock(mainCapture, [result rangeAt:0], NO, NO, [previousScopeStack copy]);
                    if (visitorResult == ECCodeVisitorResultBreak)
                    {
                        [previousScopeStack removeLastObject];
                        break;
                    }
                }
                if (visitorResult == ECCodeVisitorResultRecurse)
                {
                    NSUInteger numMatchRanges = [result count];
                    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
                    {
                        NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
                        NSString *currentCapture = [pattern.beginCaptures objectForKey:[NSNumber numberWithUnsignedInteger:currentMatchRangeIndex]];
                        if (!currentCapture)
                            continue;
                        [previousScopeStack addObject:currentCapture];
                        visitorResult = visitorBlock(currentCapture, currentMatchRange, YES, NO, [previousScopeStack copy]);
                        [previousScopeStack removeLastObject];
                        if (visitorResult == ECCodeVisitorResultBreak)
                            break;
                    }
                }
                if (mainCapture)
                {
                    if (visitorResult != ECCodeVisitorResultBreak)
                        visitorResult = visitorBlock(mainCapture, [result rangeAt:0], NO, YES, [previousScopeStack copy]);
                    [previousScopeStack removeLastObject];
                }
                if (visitorResult == ECCodeVisitorResultBreak)
                    break;
            }
            [self _visitScopesInString:string range:childScopesRange withChildPatternsOfPattern:pattern previousScopeStack:previousScopeStack usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
                visitorResult = visitorBlock(scope, scopeRange, isLeafScope, isExitingScope, scopesStack);
                return visitorResult;
            }];
            if (visitorResult == ECCodeVisitorResultBreak)
                break;
            if (pattern.endCaptures && endMatch)
            {
                NSString *mainCapture = [pattern.endCaptures objectForKey:[NSNumber numberWithUnsignedInteger:0]];
                if (mainCapture)
                {
                    [previousScopeStack addObject:mainCapture];
                    visitorResult = visitorBlock(mainCapture, [endMatch rangeAt:0], NO, NO, [previousScopeStack copy]);
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
                        NSString *currentCapture = [pattern.beginCaptures objectForKey:[NSNumber numberWithUnsignedInteger:currentMatchRangeIndex]];
                        if (!currentCapture)
                            continue;
                        [previousScopeStack addObject:currentCapture];
                        visitorResult = visitorBlock(currentCapture, currentMatchRange, YES, NO, [previousScopeStack copy]);
                        [previousScopeStack removeLastObject];
                        if (visitorResult == ECCodeVisitorResultBreak)
                            break;
                    }
                }
                if (mainCapture)
                {
                    if (visitorResult != ECCodeVisitorResultBreak)
                        visitorResult = visitorBlock(mainCapture, [endMatch rangeAt:0], NO, YES, [previousScopeStack copy]);
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
            result = [pattern.match search:string range:_rangeFromEndOfRangeToEndOfRange([endMatch rangeAt:0], range)];
        else
            break;
    }
    if (pattern.name)
        [previousScopeStack removeLastObject];
}

- (void)_visitScopesInString:(NSString *)string range:(NSRange)range withChildPatternsOfPattern:(TMPattern *)pattern previousScopeStack:(NSMutableArray *)previousScopeStack usingVisitor:(ECCodeVisitor)visitorBlock
{
    NSRange currentRange = range;
    for (;;)
    {
        __block NSRange firstMatchRange = NSMakeRange(NSNotFound, 0);
        __block TMPattern *firstMatchPattern = nil;
        for (TMPattern *childPattern in pattern.patterns)
            [self _visitScopesInString:string range:currentRange withPattern:childPattern previousScopeStack:previousScopeStack usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
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
        [self _visitScopesInString:string range:currentRange withPattern:firstMatchPattern previousScopeStack:previousScopeStack usingVisitor:^ECCodeVisitorResult(NSString *scope, NSRange scopeRange, BOOL isLeafScope, BOOL isExitingScope, NSArray *scopesStack) {
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
        currentRange.location += offset;
        currentRange.length -= offset;
    }
}

@end
