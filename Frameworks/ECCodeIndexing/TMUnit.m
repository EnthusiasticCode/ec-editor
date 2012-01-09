//
//  TMUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit+Internal.h"
#import "TMIndex+Internal.h"
#import <ECFoundation/ECFileBuffer.h>
#import "TMScope.h"
#import "TMBundle.h"
#import "TMSyntax.h"
#import "TMPattern.h"
#import "OnigRegexp.h"

static NSMutableDictionary *_extensionClasses;

static NSString * const _patternCaptureName = @"name";

@interface TMUnit ()
{
    NSOperationQueue *_consumerOperationQueue;
    TMIndex *_index;
    ECFileBuffer *_fileBuffer;
    NSString *_rootScopeIdentifier;
    NSMutableDictionary *_extensions;
    TMSyntax *__syntax;
    NSMutableDictionary *_firstMatches;
    NSString *_contents;
    TMScope *__scope;
    NSDictionary *_patternsIncludedByPattern;
    NSUInteger _generation;
}
- (TMSyntax *)_syntax;
- (TMUnitVisitResult)_visitDescendantScopesOfScope:(TMScope *)scope withOffset:(NSUInteger)offset inRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult(^)(NSString *scopeIdentifier, NSRange range))block;
- (TMScope *)_scope;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withMatchPattern:(TMPattern *)pattern;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withSpanPattern:(TMPattern *)pattern;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp stopMatch:(OnigResult **)stopMatch;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures;
- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
- (NSArray *)_patternsIncludedByPatterns:(NSArray *)patterns;
- (NSArray *)_patternsIncludedByPattern:(TMPattern *)pattern;
@end

@implementation TMUnit

+ (void)registerExtension:(Class)extensionClass forLanguageIdentifier:(NSString *)languageIdentifier forKey:(id)key
{
    if (!_extensionClasses)
        _extensionClasses = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *extensionClassesForLanguage = [_extensionClasses objectForKey:languageIdentifier];
    if (!extensionClassesForLanguage)
    {
        extensionClassesForLanguage = [[NSMutableDictionary alloc] init];
        [_extensionClasses setObject:extensionClassesForLanguage forKey:languageIdentifier];
    }
    [extensionClassesForLanguage setObject:extensionClass forKey:key];
}

- (id)initWithIndex:(TMIndex *)index fileBuffer:(ECFileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier
{
    ECASSERT(index && fileBuffer);
    self = [super init];
    if (!self)
        return nil;
    _consumerOperationQueue = [NSOperationQueue currentQueue];
    _index = index;
    _fileBuffer = fileBuffer;
    [_fileBuffer addConsumer:self];
    if (rootScopeIdentifier)
    {
        _rootScopeIdentifier = rootScopeIdentifier;
        __syntax = [TMSyntax syntaxWithScope:rootScopeIdentifier];
    }
    else
    {
        __syntax = [TMSyntax syntaxForFileBuffer:fileBuffer];
        _rootScopeIdentifier = __syntax.scopeIdentifier;
    }
    ECASSERT(__syntax && _rootScopeIdentifier);
    [__syntax beginContentAccess];
    _patternsIncludedByPattern = [NSMutableDictionary dictionary];
    _generation = 1;
    _extensions = [[NSMutableDictionary alloc] init];
    [_extensionClasses enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![rootScopeIdentifier isEqualToString:key])
            return;
        [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            id extension = [[obj alloc] initWithCodeUnit:self];
            if (!extension)
                return;
            [_extensions setObject:extension forKey:key];
        }];
    }];
    return self;
}

- (void)dealloc
{
    [__syntax endContentAccess];
    [_fileBuffer removeConsumer:self];
}

- (TMIndex *)index
{
    return _index;
}

- (ECFileBuffer *)fileBuffer
{
    return _fileBuffer;
}

- (NSString *)rootScopeIdentifier
{
    return _rootScopeIdentifier;
}

- (id)extensionForKey:(id)key
{
    return [_extensions objectForKey:key];
}

- (void)visitScopesWithBlock:(TMUnitVisitResult (^)(NSString *, NSRange))block
{
    [self visitScopesInRange:NSMakeRange(0, [self _scope].length) options:TMUnitVisitOptionsAbsoluteRange withBlock:block];
}

- (void)visitScopesInRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult (^)(NSString *, NSRange))block
{
    [self _visitDescendantScopesOfScope:[self _scope] withOffset:0 inRange:range options:options withBlock:block];
}

- (id<TMCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

#pragma mark - ECFileBufferConsumer

- (NSOperationQueue *)consumerOperationQueue
{
    return _consumerOperationQueue;
}

#pragma mark - Private Methods

- (TMSyntax *)_syntax
{
    return __syntax;
}

- (TMUnitVisitResult)_visitDescendantScopesOfScope:(TMScope *)scope withOffset:(NSUInteger)offset inRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult (^)(NSString *, NSRange))block
{
    static NSRange (^intersectionOfRangeRelativeToRange)(NSRange range, NSRange inRange) = ^(NSRange range, NSRange inRange){
        NSRange intersectionRange = NSIntersectionRange(range, inRange);
        intersectionRange.location -= inRange.location;
        return intersectionRange;
    };
    NSRange scopeRange = NSMakeRange(scope.location + offset, scope.length);
    offset = scopeRange.location;
    if (scopeRange.location > NSMaxRange(range) || NSMaxRange(scopeRange) < range.location)
        return TMUnitVisitResultContinue;
    if (options & TMUnitVisitOptionsRelativeRange)
        scopeRange = intersectionOfRangeRelativeToRange(scopeRange, range);
    TMUnitVisitResult result = block(scope.identifier, scopeRange);
    if (result != TMUnitVisitResultRecurse)
        return result;
    for (TMScope *childScope in [scope children])
    {
        if (result == TMUnitVisitResultContinue)
        {
            scopeRange = NSMakeRange(scope.location + offset, scope.length);
            if (scopeRange.location > NSMaxRange(range) || NSMaxRange(scopeRange) < range.location)
                continue;
            if (options & TMUnitVisitOptionsRelativeRange)
                scopeRange = intersectionOfRangeRelativeToRange(scopeRange, range);
            result = block(childScope.identifier, scopeRange);
            continue;
        }
        if (result == TMUnitVisitResultRecurse)
        {
            if ([self _visitDescendantScopesOfScope:childScope withOffset:offset inRange:range options:options withBlock:block] == TMUnitVisitResultContinue)
                continue;
        }
        return TMUnitVisitResultBreak;
    }
    return TMUnitVisitResultContinue;
}

- (TMScope *)_scope
{
    if (!__scope)
    {
        _firstMatches = [NSMutableDictionary dictionary];
        _contents = [self.fileBuffer string];
        __scope = [[TMScope alloc] init];
        __scope.identifier = [self rootScopeIdentifier];
        __scope.length = [_contents length];
        [self _addChildScopesToScope:__scope inRange:NSMakeRange(0, [_contents length]) relativeToOffset:0 withPatterns:[[self _syntax] patterns] stopOnRegexp:nil stopMatch:NULL];
        _firstMatches = nil;
    }
    return __scope;
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withMatchPattern:(TMPattern *)pattern
{
    return [self _addChildScopesToScope:scope inRange:range relativeToOffset:offset withRegexp:[pattern match] name:[pattern name] captures:[pattern captures]];
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withSpanPattern:(TMPattern *)pattern
{
    TMScope *currentScope = scope;
    NSUInteger endOfLastScope = range.location;
    OnigResult *beginResult = [self _firstMatchInRange:range forRegexp:[pattern begin]];
    if (!beginResult)
        return NSMaxRange(range);
    NSString *patternName = [pattern name];
    TMScope *spanScope = nil;
    NSUInteger spanScopeOffset = offset;
    if (patternName)
    {
        ECASSERT([[pattern name] isKindOfClass:[NSString class]]);
        spanScope = [currentScope newChildScopeWithIdentifier:patternName];
        spanScope.location = [beginResult bodyRange].location - offset;
        currentScope = spanScope;
        spanScopeOffset = [beginResult bodyRange].location;
        endOfLastScope = NSMaxRange([beginResult bodyRange]);
    }
    if ([pattern beginCaptures])
        endOfLastScope = MAX(endOfLastScope, [self _addChildScopesToScope:currentScope inRange:range relativeToOffset:spanScopeOffset withRegexp:[pattern begin] name:[[[pattern beginCaptures] objectForKey:@"0"] objectForKey:_patternCaptureName] captures:[pattern beginCaptures]]);
    NSRange childPatternsRange = NSMakeRange(NSMaxRange([beginResult bodyRange]), NSMaxRange(range) - NSMaxRange([beginResult bodyRange]));
    NSString *patternContentName = [pattern contentName];
    TMScope *spanContentScope = nil;
    NSUInteger spanContentScopeOffset = spanScopeOffset;
    if (patternContentName)
    {
        ECASSERT([[pattern contentName] isKindOfClass:[NSString class]]);
        spanContentScope = [currentScope newChildScopeWithIdentifier:patternContentName];
        spanContentScope.location = childPatternsRange.location - spanScopeOffset;
        currentScope = spanContentScope;
        spanContentScopeOffset = childPatternsRange.location;
    }
    OnigResult *stopMatch = nil;
    endOfLastScope = [self _addChildScopesToScope:currentScope inRange:childPatternsRange relativeToOffset:spanContentScopeOffset withPatterns:[pattern patterns] stopOnRegexp:[pattern end] stopMatch:&stopMatch];
    if (spanContentScope)
    {
        spanContentScope.length = stopMatch ? ([stopMatch bodyRange].location - childPatternsRange.location) : childPatternsRange.length;
        currentScope = spanScope ? spanScope : scope;
    }
    if (stopMatch)
        endOfLastScope = MAX(endOfLastScope, [self _addChildScopesToScope:currentScope inRange:childPatternsRange relativeToOffset:[beginResult bodyRange].location withRegexp:[pattern end] name:[[[pattern endCaptures] objectForKey:@"0"] objectForKey:_patternCaptureName] captures:[pattern endCaptures]]);
    if (spanScope)
    {
        endOfLastScope = stopMatch ? NSMaxRange([stopMatch bodyRange]) : NSMaxRange(range);
        [spanScope setLength:endOfLastScope - [beginResult bodyRange].location];
    }
    ECASSERT(endOfLastScope <= NSMaxRange(range));
    return endOfLastScope;
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp stopMatch:(OnigResult *__autoreleasing *)stopMatch
{
    patterns = [self _patternsIncludedByPatterns:patterns];
    BOOL matchFound;
    NSUInteger rangeEnd = NSMaxRange(range);
    do
    {
        matchFound = NO;
        NSRange firstMatchRange = NSMakeRange(NSNotFound, 0);
        TMPattern *firstMatchPattern = nil;
        for (TMPattern *childPattern in patterns)
        {
            ECASSERT([childPattern match] || [childPattern begin]);
            OnigRegexp *patternRegexp = [childPattern match] ? [childPattern match] : [childPattern begin];
            OnigResult *result = [self _firstMatchInRange:range forRegexp:patternRegexp];
            if (!result)
                continue;
            NSRange resultRange = [result bodyRange];
            if (resultRange.location > firstMatchRange.location)
                continue;
            if (resultRange.location == firstMatchRange.location)
                if (firstMatchRange.length == 0)
                    continue;
                else if (resultRange.length < firstMatchRange.length && resultRange.length != 0)
                    continue;
            firstMatchRange = resultRange;
            firstMatchPattern = childPattern;
            matchFound = YES;
            if (firstMatchRange.location == range.location && firstMatchRange.length == 0)
                break;
        }
        OnigResult *stopResult = regexp ? [self _firstMatchInRange:range forRegexp:regexp] : nil;
        if (stopResult && [stopResult bodyRange].location <= firstMatchRange.location)
        {
            if (stopMatch)
                *stopMatch = stopResult;
            return NSMaxRange([stopResult bodyRange]);
        }
        if (!firstMatchPattern)
            break;
        if ([firstMatchPattern match])
            range.location = [self _addChildScopesToScope:scope inRange:range relativeToOffset:offset withMatchPattern:firstMatchPattern];
        else
            range.location = [self _addChildScopesToScope:scope inRange:range relativeToOffset:offset withSpanPattern:firstMatchPattern];
        ECASSERT(range.location <= rangeEnd);
        range.length = rangeEnd - range.location;
    }
    while (matchFound);
    return NSMaxRange(range);
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures
{
    TMScope *capturesScope = nil;
    NSUInteger endOfLastScope = range.location;
    OnigResult *result = [self _firstMatchInRange:range forRegexp:regexp];
    if (!result)
        return NSMaxRange(range);
    if (name)
    {
        ECASSERT([name isKindOfClass:[NSString class]]);
        capturesScope = [scope newChildScopeWithIdentifier:name];
        capturesScope.location = [result bodyRange].location - offset;
        capturesScope.length = [result bodyRange].length;
        offset = [result bodyRange].location;
        endOfLastScope = NSMaxRange([result bodyRange]);
    }
    if (captures)
    {
        NSUInteger numMatchRanges = [result count];
        for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
        {
            NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
            if (!currentMatchRange.length)
                continue;
            NSString *currentCaptureName = [[captures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_patternCaptureName];
            if (!currentCaptureName)
                continue;
            ECASSERT([currentCaptureName isKindOfClass:[NSString class]]);
            TMScope *currentCaptureScope = [capturesScope ? capturesScope : scope newChildScopeWithIdentifier:currentCaptureName];
            ECASSERT(currentMatchRange.location >= [result bodyRange].location && NSMaxRange(currentMatchRange) <= NSMaxRange([result bodyRange]));
            currentCaptureScope.location = currentMatchRange.location - offset;
            currentCaptureScope.length = currentMatchRange.length;
            endOfLastScope = MAX(endOfLastScope, NSMaxRange(currentMatchRange));
        }
    }
    ECASSERT(endOfLastScope <= NSMaxRange(range));
    return endOfLastScope;
}

- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
{
    OnigResult *result = [_firstMatches objectForKey:regexp];
    if (result && (id)result != [NSNull null] && [result rangeAt:0].location >= range.location && NSMaxRange([result rangeAt:0]) <= NSMaxRange(range))
        return result;
    if ((id)result == [NSNull null])
        return nil;
    result = [regexp search:_contents range:range];
    if (result)
        [_firstMatches setObject:result forKey:regexp];
    else
        [_firstMatches setObject:[NSNull null] forKey:regexp];
    return result;
}

- (NSArray *)_patternsIncludedByPatterns:(NSArray *)patterns
{
    NSMutableArray *includedPatterns = [NSMutableArray array];
    for (TMPattern *pattern in patterns)
        [includedPatterns addObjectsFromArray:[self _patternsIncludedByPattern:pattern]];
    return includedPatterns;
}

- (NSArray *)_patternsIncludedByPattern:(TMPattern *)pattern
{
    NSMutableArray *includedPatterns = [_patternsIncludedByPattern objectForKey:pattern];
    if (includedPatterns)
        return includedPatterns;
    includedPatterns = [NSMutableArray arrayWithObject:pattern];
    NSMutableSet *dereferencedPatterns = [NSMutableSet set];
    NSMutableIndexSet *containerPatternIndexes = [NSMutableIndexSet indexSet];
    do
    {
        [containerPatternIndexes removeAllIndexes];
        [includedPatterns enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj match] || [obj begin])
                return;
            [containerPatternIndexes addIndex:idx];
        }];
        [containerPatternIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
            TMPattern *containerPattern = [includedPatterns objectAtIndex:idx];
            [includedPatterns removeObjectAtIndex:idx];
            if ([dereferencedPatterns containsObject:containerPattern])
                return;
            ECASSERT([containerPattern include] || [containerPattern patterns]);
            ECASSERT(![containerPattern include] || ![containerPattern patterns]);
            if ([containerPattern include])
            {
                unichar firstCharacter = [[containerPattern include] characterAtIndex:0];
                if (firstCharacter == '#')
                {
                    TMSyntax *patternSyntax = [containerPattern syntax];
                    [patternSyntax beginContentAccess];
                    [includedPatterns addObject:[TMPattern patternWithDictionary:[[patternSyntax repository] objectForKey:[[containerPattern include] substringFromIndex:1]] inSyntax:patternSyntax]];
                    [patternSyntax endContentAccess];
                }
                else
                {
                    ECASSERT(firstCharacter != '$' || [[containerPattern include] isEqualToString:@"$base"] || [[containerPattern include] isEqualToString:@"$self"]);
                    TMSyntax *includedSyntax = nil;
                    if ([[containerPattern include] isEqualToString:@"$base"])
                        includedSyntax = [self _syntax];
                    else if ([[containerPattern include] isEqualToString:@"$self"])
                        includedSyntax = [containerPattern syntax];
                    else
                        includedSyntax = [TMSyntax syntaxWithScope:[containerPattern include]];
                    [includedSyntax beginContentAccess];
                    for (TMPattern *pattern in [includedSyntax patterns])
                        [includedPatterns addObject:pattern];
                    [includedSyntax endContentAccess];
                }
            }
            else
                [includedPatterns addObjectsFromArray:[containerPattern patterns]];
            [dereferencedPatterns addObject:containerPattern];
        }];
    }
    while ([containerPatternIndexes count]);
    return includedPatterns;
}

@end
