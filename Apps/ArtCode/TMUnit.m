//
//  TMUnit.m
//  CodeIndexing
//
//  Created by Uri Baghin on 11/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMUnit+Internal.h"
#import "TMIndex+Internal.h"
#import "FileBuffer.h"
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
    FileBuffer *_fileBuffer;
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
- (TMUnitVisitResult)_visitDescendantScopesOfScope:(TMScope *)scope withOffset:(NSUInteger)offset inRange:(NSRange)range options:(TMUnitVisitOptions)options scopeIdentifiersStack:(NSMutableArray *)scopeIdentifiersStack withBlock:(TMUnitVisitResult(^)(NSString *scopeIdentifier, NSRange range, NSMutableArray *))block;
- (TMScope *)_scope;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withMatchPattern:(TMPattern *)pattern;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withSpanPattern:(TMPattern *)pattern;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withPatterns:(NSArray *)patterns;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope relativeToOffset:(NSUInteger)offset withResult:(OnigResult *)result name:(NSString *)name captures:(NSDictionary *)captures capturesOffset:(NSUInteger)capturesOffset;
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

- (id)initWithIndex:(TMIndex *)index fileBuffer:(FileBuffer *)fileBuffer rootScopeIdentifier:(NSString *)rootScopeIdentifier
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

- (FileBuffer *)fileBuffer
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

- (void)visitScopesWithBlock:(TMUnitVisitResult (^)(NSString *, NSRange, NSMutableArray *))block
{
    [self visitScopesInRange:NSMakeRange(0, [self _scope].length) options:TMUnitVisitOptionsAbsoluteRange withBlock:block];
}

- (void)visitScopesInRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult (^)(NSString *, NSRange, NSMutableArray *))block
{
    [self _visitDescendantScopesOfScope:[self _scope] withOffset:0 inRange:range options:options scopeIdentifiersStack:[NSMutableArray array] withBlock:block];
}

- (id<TMCompletionResultSet>)completionsAtOffset:(NSUInteger)offset
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

#pragma mark - FileBufferConsumer

- (NSOperationQueue *)consumerOperationQueue
{
    return _consumerOperationQueue;
}

#pragma mark - Private Methods

- (TMSyntax *)_syntax
{
    return __syntax;
}

- (TMUnitVisitResult)_visitDescendantScopesOfScope:(TMScope *)scope withOffset:(NSUInteger)offset inRange:(NSRange)range options:(TMUnitVisitOptions)options scopeIdentifiersStack:(NSMutableArray *)scopeIdentifiersStack withBlock:(TMUnitVisitResult (^)(NSString *, NSRange, NSMutableArray *))block
{
    static NSRange (^intersectionOfRangeRelativeToRange)(NSRange range, NSRange inRange) = ^(NSRange range, NSRange inRange){
        NSRange intersectionRange = NSIntersectionRange(range, inRange);
        intersectionRange.location -= inRange.location;
        return intersectionRange;
    };
    NSRange scopeRange = NSMakeRange(scope.location + offset, scope.length);
    offset = scopeRange.location;
    if (scopeRange.location > NSMaxRange(range))
        return TMUnitVisitResultBreak;
    if (NSMaxRange(scopeRange) < range.location)
        return TMUnitVisitResultContinue;
    if (options & TMUnitVisitOptionsRelativeRange)
        scopeRange = intersectionOfRangeRelativeToRange(scopeRange, range);
    [scopeIdentifiersStack addObject:scope.identifier];
    TMUnitVisitResult result = block(scope.identifier, scopeRange, scopeIdentifiersStack);
    NSLog(@"%@ : %@", NSStringFromRange(scopeRange), scopeIdentifiersStack);
    if (result != TMUnitVisitResultRecurse)
        return result;
    for (TMScope *childScope in [scope children])
    {
        if (result == TMUnitVisitResultContinue)
        {
            scopeRange = NSMakeRange(scope.location + offset, scope.length);
            if (scopeRange.location > NSMaxRange(range))
                return TMUnitVisitResultBreak;
            if (NSMaxRange(scopeRange) < range.location)
                continue;
            if (options & TMUnitVisitOptionsRelativeRange)
                scopeRange = intersectionOfRangeRelativeToRange(scopeRange, range);
            [scopeIdentifiersStack addObject:childScope.identifier];
            result = block(childScope.identifier, scopeRange, scopeIdentifiersStack);
            NSLog(@"%@ : %@", NSStringFromRange(scopeRange), scopeIdentifiersStack);
            [scopeIdentifiersStack removeLastObject];
            continue;
        }
        if (result == TMUnitVisitResultRecurse)
        {
            if ([self _visitDescendantScopesOfScope:childScope withOffset:offset inRange:range options:options scopeIdentifiersStack:scopeIdentifiersStack withBlock:block] == TMUnitVisitResultContinue)
                continue;
        }
        return TMUnitVisitResultBreak;
    }
    [scopeIdentifiersStack removeLastObject];
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
        [self _addChildScopesToScope:__scope inRange:NSMakeRange(0, [_contents length]) relativeToOffset:0 withPatterns:[[self _syntax] patterns]];
        _firstMatches = nil;
    }
    return __scope;
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withMatchPattern:(TMPattern *)pattern
{
    OnigResult *matchResult = [self _firstMatchInRange:range forRegexp:[pattern match]];
    return [self _addChildScopesToScope:scope relativeToOffset:offset withResult:matchResult name:[pattern name] captures:[pattern captures] capturesOffset:0];
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withSpanPattern:(TMPattern *)pattern
{
    TMScope *currentScope = scope;
    OnigResult *beginResult = [self _firstMatchInRange:range forRegexp:[pattern begin]];
    if (!beginResult)
        return NSMaxRange(range);
    NSRange spanRange;
    NSRange childPatternsRange;
    OnigResult *beginAndEndResult = [self _firstMatchInRange:range forRegexp:[pattern beginAndEnd]];
    NSString *beginBodyCapture = [[[pattern beginCaptures] objectForKey:@"0"] objectForKey:_patternCaptureName];
    NSString *endBodyCapture = [[[pattern endCaptures] objectForKey:@"0"] objectForKey:_patternCaptureName];
    NSUInteger offsetForBeginCaptures = 0;
    NSUInteger offsetForEndCaptures = [beginResult count] + offsetForBeginCaptures;
    if (beginAndEndResult)
    {
        spanRange = [beginAndEndResult bodyRange];
        childPatternsRange = NSMakeRange(NSMaxRange([beginResult bodyRange]), [beginAndEndResult rangeAt:offsetForEndCaptures].location - NSMaxRange([beginResult bodyRange]));
    }
    else
    {
        spanRange = NSMakeRange([beginResult bodyRange].location, NSMaxRange(range) - [beginResult bodyRange].location);
        childPatternsRange = NSMakeRange(NSMaxRange([beginResult bodyRange]), NSMaxRange(range) - NSMaxRange([beginResult bodyRange]));
    }
    NSString *patternName = [pattern name];
    TMScope *spanScope = nil;
    NSUInteger spanScopeOffset = offset;
    if (patternName)
    {
        ECASSERT([[pattern name] isKindOfClass:[NSString class]]);
        spanScope = [currentScope newChildScopeWithIdentifier:patternName];
        spanScope.location = spanRange.location - offset;
        spanScope.length = spanRange.length;
        currentScope = spanScope;
        spanScopeOffset = [beginResult bodyRange].location;
    }
    if ([pattern beginCaptures])
        [self _addChildScopesToScope:currentScope relativeToOffset:spanScopeOffset withResult:beginResult name:beginBodyCapture captures:[pattern beginCaptures] capturesOffset:0];
    NSString *patternContentName = [pattern contentName];
    TMScope *spanContentScope = nil;
    NSUInteger spanContentScopeOffset = spanScopeOffset;
    if (patternContentName)
    {
        ECASSERT([[pattern contentName] isKindOfClass:[NSString class]]);
        spanContentScope = [currentScope newChildScopeWithIdentifier:patternContentName];
        spanContentScope.location = childPatternsRange.location - spanScopeOffset;
        spanContentScope.length = childPatternsRange.length;
        currentScope = spanContentScope;
        spanContentScopeOffset = childPatternsRange.location;
    }
    [self _addChildScopesToScope:currentScope inRange:childPatternsRange relativeToOffset:spanContentScopeOffset withPatterns:[pattern patterns]];
    if (spanContentScope)
        currentScope = spanScope ? spanScope : scope;
    if (beginAndEndResult && [pattern endCaptures])
        [self _addChildScopesToScope:currentScope relativeToOffset:spanScopeOffset withResult:beginAndEndResult name:endBodyCapture captures:[pattern endCaptures] capturesOffset:offsetForEndCaptures];
    ECASSERT(NSMaxRange(spanRange) <= NSMaxRange(range));
    return NSMaxRange(spanRange);
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withPatterns:(NSArray *)patterns
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

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope relativeToOffset:(NSUInteger)offset withResult:(OnigResult *)result name:(NSString *)name captures:(NSDictionary *)captures capturesOffset:(NSUInteger)capturesOffset
{
    ECASSERT(result);
    ECASSERT(name || [captures count]);
    TMScope *capturesScope = scope;
    NSUInteger endOfLastScope = 0;
    if (name)
    {
        ECASSERT([name isKindOfClass:[NSString class]]);
        capturesScope = [scope newChildScopeWithIdentifier:name];
        capturesScope.location = [result rangeAt:capturesOffset].location - offset;
        capturesScope.length = [result rangeAt:capturesOffset].length;
        offset = [result rangeAt:capturesOffset].location;
        endOfLastScope = NSMaxRange([result rangeAt:capturesOffset]);
    }
    if (captures)
    {
        NSUInteger numMatchRanges = [result count] - capturesOffset;
        for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
        {
            NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex + capturesOffset];
            if (!currentMatchRange.length)
                continue;
            NSString *currentCaptureName = [[captures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_patternCaptureName];
            if (!currentCaptureName)
                continue;
            ECASSERT([currentCaptureName isKindOfClass:[NSString class]]);
            TMScope *currentCaptureScope = [capturesScope newChildScopeWithIdentifier:currentCaptureName];
            ECASSERT(currentMatchRange.location >= [result rangeAt:capturesOffset].location && NSMaxRange(currentMatchRange) <= NSMaxRange([result rangeAt:capturesOffset]));
            currentCaptureScope.location = currentMatchRange.location - offset;
            currentCaptureScope.length = currentMatchRange.length;
            endOfLastScope = MAX(endOfLastScope, NSMaxRange(currentMatchRange));
        }
        [[(capturesScope ? capturesScope : scope) children] sortUsingComparator:^NSComparisonResult(TMScope *obj1, TMScope *obj2) {
            if (obj1.location < obj2.location)
                return NSOrderedAscending;
            if (obj1.location > obj2.location)
                return NSOrderedDescending;
            return NSOrderedSame;
        }];
    }
    return endOfLastScope;
}

- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
{
    OnigResult *result = [_firstMatches objectForKey:regexp];
    if (result && [result rangeAt:0].location >= range.location && NSMaxRange([result rangeAt:0]) <= NSMaxRange(range))
        return result;
    result = [regexp search:_contents range:range];
    if (result)
        [_firstMatches setObject:result forKey:regexp];
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
