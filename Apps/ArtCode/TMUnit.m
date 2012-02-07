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
#import "OnigRegexp.h"

static NSMutableDictionary *_extensionClasses;

static NSString * const _captureName = @"name";
static OnigRegexp *_numberedCapturesRegexp;
static OnigRegexp *_namedCapturesRegexp;

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
- (TMUnitVisitResult)_visitDescendantScopesOfScope:(TMScope *)scope withOffset:(NSUInteger)offset inRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult(^)(TMScope *scope, NSRange range))block;
- (TMScope *)_scope;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withMatchPattern:(TMSyntax *)pattern;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withSpanPattern:(TMSyntax *)pattern;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp stopMatch:(OnigResult **)stopMatch;
- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures;
- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
- (NSArray *)_patternsIncludedByPatterns:(NSArray *)patterns;
- (NSArray *)_patternsIncludedByPattern:(TMSyntax *)pattern;
@end

@implementation TMUnit

+ (void)initialize
{
    if (self != [TMUnit class])
        return;
    _numberedCapturesRegexp = [OnigRegexp compile:@"\\([1-9])"];
    _namedCapturesRegexp = [OnigRegexp compile:@"\\k<(.*?)>"];
}

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
        __syntax = [TMSyntax syntaxWithScopeIdentifier:rootScopeIdentifier];
    }
    else
    {
        __syntax = [TMSyntax syntaxForFileBuffer:fileBuffer];
        _rootScopeIdentifier = [[__syntax attributes] objectForKey:TMSyntaxScopeIdentifierKey];
    }
    ECASSERT(__syntax && _rootScopeIdentifier);
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

- (void)visitScopesWithBlock:(TMUnitVisitResult (^)(TMScope *, NSRange))block
{
    [self visitScopesInRange:NSMakeRange(0, [self _scope].length) options:TMUnitVisitOptionsAbsoluteRange withBlock:block];
}

- (void)visitScopesInRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult (^)(TMScope *, NSRange))block
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

- (TMUnitVisitResult)_visitDescendantScopesOfScope:(TMScope *)scope withOffset:(NSUInteger)offset inRange:(NSRange)range options:(TMUnitVisitOptions)options withBlock:(TMUnitVisitResult (^)(TMScope *, NSRange))block
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
    TMUnitVisitResult result = block(scope, scopeRange);
//    NSLog(@"%@ : %@", NSStringFromRange(scopeRange), [scope qualifiedIdentifier]);
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
            result = block(childScope, scopeRange);
//            NSLog(@"%@ : %@", NSStringFromRange(scopeRange), [scope qualifiedIdentifier]);
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
        __scope = [[TMScope alloc] initWithParent:nil identifier:[self rootScopeIdentifier]];
        __scope.length = [_contents length];
        [self _addChildScopesToScope:__scope inRange:NSMakeRange(0, [_contents length]) relativeToOffset:0 withPatterns:[[[self _syntax] attributes] objectForKey:TMSyntaxPatternsKey] stopOnRegexp:nil stopMatch:NULL];
        _firstMatches = nil;
    }
    return __scope;
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withMatchPattern:(TMSyntax *)pattern
{
    return [self _addChildScopesToScope:scope inRange:range relativeToOffset:offset withRegexp:[[pattern attributes] objectForKey:TMSyntaxMatchKey] name:[[pattern attributes] objectForKey:TMSyntaxNameKey] captures:[[pattern attributes] objectForKey:TMSyntaxCapturesKey]];
}

- (NSUInteger)_addChildScopesToScope:(TMScope *)scope inRange:(NSRange)range relativeToOffset:(NSUInteger)offset withSpanPattern:(TMSyntax *)pattern
{
    TMScope *currentScope = scope;
    OnigRegexp *beginRegexp = [[pattern attributes] objectForKey:TMSyntaxBeginKey];
    NSDictionary *captures = [[pattern attributes] objectForKey:TMSyntaxCapturesKey];
    NSDictionary *beginCaptures = [[pattern attributes] objectForKey:TMSyntaxBeginCapturesKey];
    if (!beginCaptures)
        beginCaptures = captures;
    OnigResult *beginResult = [self _firstMatchInRange:range forRegexp:beginRegexp];
    if (!beginResult)
        return NSMaxRange(range);
    NSString *patternName = [[pattern attributes] objectForKey:TMSyntaxNameKey];
    TMScope *spanScope = nil;
    NSUInteger spanScopeOffset = offset;
    if (patternName)
    {
        ECASSERT([patternName isKindOfClass:[NSString class]]);
        spanScope = [currentScope newChildScopeWithIdentifier:patternName];
        spanScope.location = [beginResult bodyRange].location - offset;
        currentScope = spanScope;
        spanScopeOffset = [beginResult bodyRange].location;
    }
    if (beginCaptures)
        [self _addChildScopesToScope:currentScope inRange:range relativeToOffset:spanScopeOffset withRegexp:beginRegexp name:[[beginCaptures objectForKey:@"0"] objectForKey:_captureName] captures:beginCaptures];
    NSRange childPatternsRange = NSMakeRange(NSMaxRange([beginResult bodyRange]), NSMaxRange(range) - NSMaxRange([beginResult bodyRange]));
    NSString *patternContentName = [[pattern attributes] objectForKey:TMSyntaxContentNameKey];
    TMScope *spanContentScope = nil;
    NSUInteger spanContentScopeOffset = spanScopeOffset;
    if (patternContentName)
    {
        ECASSERT([patternContentName isKindOfClass:[NSString class]]);
        spanContentScope = [currentScope newChildScopeWithIdentifier:patternContentName];
        spanContentScope.location = childPatternsRange.location - spanScopeOffset;
        currentScope = spanContentScope;
        spanContentScopeOffset = childPatternsRange.location;
    }
    NSMutableString *end = [[[pattern attributes] objectForKey:TMSyntaxEndKey] mutableCopy];
    NSDictionary *endCaptures = [[pattern attributes] objectForKey:TMSyntaxEndCapturesKey];
    if (!endCaptures)
        endCaptures = captures;
    for (;;)
    {
        OnigResult *result = [_numberedCapturesRegexp search:end];
        if (!result)
            break;
        int captureNumber = [[result body] intValue];
        if (captureNumber >= 0 && [beginResult count] > captureNumber)
            [end replaceCharactersInRange:[result bodyRange] withString:[beginResult stringAt:captureNumber]];
        else
            [end deleteCharactersInRange:[result bodyRange]];
    }
    for (;;)
    {
        OnigResult *result = [_namedCapturesRegexp search:end];
        if (!result)
            break;
        NSString *captureName = [result body];
        int captureNumber = [beginResult indexForName:captureName];
        if (captureNumber >= 0 && [beginResult count] > captureNumber)
            [end replaceCharactersInRange:[result bodyRange] withString:[beginResult stringAt:captureNumber]];
        else
            [end deleteCharactersInRange:[result bodyRange]];
    }
    OnigRegexp *stopRegexp = [OnigRegexp compile:end options:OnigOptionCaptureGroup | OnigOptionNotbol | OnigOptionNoteol];
    OnigResult *stopMatch = nil;
    NSUInteger endOfLastScope = [self _addChildScopesToScope:currentScope inRange:childPatternsRange relativeToOffset:spanContentScopeOffset withPatterns:[[pattern attributes] objectForKey:TMSyntaxPatternsKey] stopOnRegexp:stopRegexp stopMatch:&stopMatch];
    if (spanContentScope)
    {
        spanContentScope.length = stopMatch ? ([stopMatch bodyRange].location - childPatternsRange.location) : childPatternsRange.length;
        currentScope = spanScope ? spanScope : scope;
    }
    if (stopMatch && endCaptures)
        endOfLastScope = MAX(endOfLastScope, [self _addChildScopesToScope:currentScope inRange:childPatternsRange relativeToOffset:[beginResult bodyRange].location withRegexp:stopRegexp name:[[endCaptures objectForKey:@"0"] objectForKey:_captureName] captures:endCaptures]);
    if (spanScope)
    {
        endOfLastScope = stopMatch ? NSMaxRange([stopMatch bodyRange]) : NSMaxRange(range);
        [spanScope setLength:endOfLastScope - [beginResult bodyRange].location];
    }
    if (endOfLastScope == range.location)
        ++endOfLastScope;
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
        TMSyntax *firstMatchPattern = nil;
        for (TMSyntax *childPattern in patterns)
        {
            ECASSERT([[childPattern attributes] objectForKey:TMSyntaxMatchKey] || [[childPattern attributes] objectForKey:TMSyntaxBeginKey]);
            OnigRegexp *patternRegexp = [[childPattern attributes] objectForKey:TMSyntaxMatchKey] ? [[childPattern attributes] objectForKey:TMSyntaxMatchKey] : [[childPattern attributes] objectForKey:TMSyntaxBeginKey];
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
        if ([[firstMatchPattern attributes] objectForKey:TMSyntaxMatchKey])
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
            NSString *currentCaptureName = [[captures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_captureName];
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
    for (TMSyntax *pattern in patterns)
        [includedPatterns addObjectsFromArray:[self _patternsIncludedByPattern:pattern]];
    return includedPatterns;
}

- (NSArray *)_patternsIncludedByPattern:(TMSyntax *)pattern
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
        [includedPatterns enumerateObjectsUsingBlock:^(TMSyntax *obj, NSUInteger idx, BOOL *stop) {
            if ([[obj attributes] objectForKey:TMSyntaxMatchKey] || [[obj attributes] objectForKey:TMSyntaxBeginKey])
                return;
            [containerPatternIndexes addIndex:idx];
        }];
        [containerPatternIndexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
            TMSyntax *containerPattern = [includedPatterns objectAtIndex:idx];
            [includedPatterns removeObjectAtIndex:idx];
            if ([dereferencedPatterns containsObject:containerPattern])
                return;
            ECASSERT([[containerPattern attributes] objectForKey:TMSyntaxIncludeKey] || [[containerPattern attributes] objectForKey:TMSyntaxPatternsKey]);
            ECASSERT(![[containerPattern attributes] objectForKey:TMSyntaxIncludeKey] || ![[containerPattern attributes] objectForKey:TMSyntaxPatternsKey]);
            if ([[containerPattern attributes] objectForKey:TMSyntaxIncludeKey])
            {
                unichar firstCharacter = [[[containerPattern attributes] objectForKey:TMSyntaxIncludeKey] characterAtIndex:0];
                if (firstCharacter == '#')
                {
                    TMSyntax *patternSyntax = [containerPattern rootSyntax];
                    [includedPatterns addObject:[[[patternSyntax attributes] objectForKey:TMSyntaxRepositoryKey] objectForKey:[[[containerPattern attributes] objectForKey:TMSyntaxIncludeKey] substringFromIndex:1]]];
                }
                else
                {
                    ECASSERT(firstCharacter != '$' || [[[containerPattern attributes] objectForKey:TMSyntaxIncludeKey] isEqualToString:@"$base"] || [[[containerPattern attributes] objectForKey:TMSyntaxIncludeKey] isEqualToString:@"$self"]);
                    TMSyntax *includedSyntax = nil;
                    if ([[[containerPattern attributes] objectForKey:TMSyntaxIncludeKey] isEqualToString:@"$base"])
                        includedSyntax = [self _syntax];
                    else if ([[[containerPattern attributes] objectForKey:TMSyntaxIncludeKey] isEqualToString:@"$self"])
                        includedSyntax = [containerPattern rootSyntax];
                    else
                        includedSyntax = [TMSyntax syntaxWithScopeIdentifier:[[containerPattern attributes] objectForKey:TMSyntaxIncludeKey]];
                    for (TMSyntax *pattern in [[includedSyntax attributes] objectForKey:TMSyntaxPatternsKey])
                        [includedPatterns addObject:pattern];
                }
            }
            else
                [includedPatterns addObjectsFromArray:[[containerPattern attributes] objectForKey:TMSyntaxPatternsKey]];
            [dereferencedPatterns addObject:containerPattern];
        }];
    }
    while ([containerPatternIndexes count]);
    return includedPatterns;
}

@end
