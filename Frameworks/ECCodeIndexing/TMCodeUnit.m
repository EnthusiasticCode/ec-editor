//
//  TMCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMCodeUnit.h"
#import "ECCodeIndex+Subclass.h"
#import "TMBundle.h"
#import "TMSyntax.h"
#import "TMPattern.h"
#import "TMScope.h"
#import "TMToken.h"
#import "TMCodeIndex.h"
#import "OnigRegexp.h"

static NSString * const _patternCaptureName = @"name";
static NSString * const _tokenAttributeName = @"TMTokenAttributeName";

@interface TMCodeUnit ()
{
    TMSyntax *__syntax;
    NSMutableDictionary *_firstMatches;
    NSMutableArray *_tokens;
    NSArray *__topLevelScopes;
}
- (TMSyntax *)_syntax;
- (NSArray *)_topLevelScopes;
- (TMScope *)_scopeContainingRange:(NSRange)range;
- (NSArray *)_createScopesInRange:(NSRange)range withMatchPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange;
- (NSArray *)_createScopesInRange:(NSRange)range withSpanPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange;
- (NSArray *)_createScopesInRange:(NSRange)range withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp withName:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange;
- (NSArray *)_createScopesInRange:(NSRange)range withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange;
- (NSArray *)_createScopesForCaptures:(NSDictionary *)captures inResult:(OnigResult *)result;
- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
@end

@implementation TMCodeUnit

- (id)initWithIndex:(ECCodeIndex *)index file:(NSURL *)fileURL scope:(NSString *)scope
{
    ECASSERT(index);
    ECASSERT([fileURL isFileURL]);
    ECASSERT([scope length]);
    self = [super initWithIndex:index file:fileURL scope:scope];
    if (!self)
        return nil;
    __syntax = [TMSyntax syntaxWithScope:scope];
    ECASSERT(__syntax);
    [__syntax beginContentAccess];
    return self;
}

- (void)dealloc
{
    [__syntax endContentAccess];
}

- (TMSyntax *)_syntax
{
    return __syntax;
}

- (NSArray *)tokensInRange:(NSRange)range
{
    return [self annotatedTokensInRange:range];
}

- (NSArray *)annotatedTokensInRange:(NSRange)range
{
    _tokens = [NSMutableArray array];
    [[[self index] contentsForFile:self.fileURL] enumerateLinguisticTagsInRange:range scheme:NSLinguisticTagSchemeTokenType options:NSLinguisticTaggerOmitWhitespace orthography:[NSOrthography orthographyWithDominantScript:@"Zyyy" languageMap:nil] usingBlock:^(NSString *tag, NSRange tokenRange, NSRange sentenceRange, BOOL *stop) {
        [_tokens addObject:[[TMToken alloc] initWithContainingString:[[self index] contentsForFile:self.fileURL] range:tokenRange scope:[self _scopeContainingRange:tokenRange]]];
    }];
    return _tokens;
}

#pragma mark - Private methods

- (NSArray *)_topLevelScopes
{
    if (!__topLevelScopes)
    {
        __topLevelScopes = [self _createScopesInRange:NSMakeRange(0, [[[self index] contentsForFile:self.fileURL] length]) withPatterns:[[self _syntax] patterns] stopOnRegexp:nil withName:nil captures:nil remainingRange:NULL];
    }
    return __topLevelScopes;
}

- (TMScope *)_scopeContainingRange:(NSRange)range
{
    ECASSERT(NSMaxRange(range) <= [[[self index] contentsForFile:self.fileURL] length]);
    NSArray *currentScopes = [self _topLevelScopes];
    TMScope *containingScope = nil;
    BOOL childScopeContainsRange = NO;
    do
    {
        childScopeContainsRange = NO;
        for (TMScope *currentScope in currentScopes)
        {
            if ([currentScope range].location > range.location || NSMaxRange([currentScope range]) < NSMaxRange(range))
                continue;
            containingScope = currentScope;
            currentScopes = [currentScope children];
            childScopeContainsRange = YES;
            break;
        }
    }
    while (childScopeContainsRange);
    return containingScope;
}

- (NSArray *)_createScopesInRange:(NSRange)range withMatchPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange
{
    return [self _createScopesInRange:range withRegexp:[pattern match] name:[pattern name] captures:[pattern captures] remainingRange:remainingRange];
}

- (NSArray *)_createScopesInRange:(NSRange)range withSpanPattern:(TMPattern *)pattern remainingRange:(NSRange *)remainingRange
{
    NSRange localRemainingRange;
    if (remainingRange)
        *remainingRange = range;
    NSMutableArray *childScopes = [NSMutableArray array];
    if ([pattern beginCaptures])
    {
        NSArray *beginScopes = [self _createScopesInRange:range withRegexp:[pattern begin] name:[[[pattern beginCaptures] objectForKey:[NSString stringWithFormat:@"%d", 0]] objectForKey:_patternCaptureName] captures:[pattern beginCaptures] remainingRange:&localRemainingRange];
        if (![beginScopes count])
            return nil;
        [childScopes addObjectsFromArray:beginScopes];
    }
    else
    {
        OnigResult *beginResult = [self _firstMatchInRange:range forRegexp:[pattern begin]];
        if (!beginResult)
            return nil;
        localRemainingRange.location = NSMaxRange([beginResult bodyRange]);
        localRemainingRange.length = NSMaxRange(range) - localRemainingRange.location;
    }
    [childScopes addObjectsFromArray:[self _createScopesInRange:localRemainingRange withPatterns:[pattern patterns] stopOnRegexp:[pattern end] withName:[[[pattern endCaptures] objectForKey:[NSString stringWithFormat:@"%d", 0]] objectForKey:_patternCaptureName] captures:[pattern endCaptures] remainingRange:&localRemainingRange]];
    if (remainingRange)
        *remainingRange = localRemainingRange;
    if (![pattern name])
        return childScopes;
    TMScope *scope = [[TMScope alloc] init];
    scope.containingString = [[self index] contentsForFile:self.fileURL];
    ECASSERT([[pattern name] isKindOfClass:[NSString class]]);
    scope.identifier = [pattern name];
    scope.range = NSMakeRange(range.location, localRemainingRange.location - range.location);
    if ([childScopes count])
    {
        for (TMScope *childScope in childScopes)
            childScope.parent = scope;
        scope.children = childScopes;
    }
    ECASSERT([scope range].length);
    return [NSArray arrayWithObject:scope];
}

- (NSArray *)_createScopesInRange:(NSRange)range withPatterns:(NSArray *)patterns stopOnRegexp:(OnigRegexp *)regexp withName:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange
{
    NSRange currentRange = range;
    NSMutableArray *scopes = [NSMutableArray array];
    while (currentRange.length)
    {
        NSRange firstMatchRange = NSMakeRange(NSNotFound, 0);
        TMPattern *firstMatchPattern = nil;
        for (TMPattern *childPattern in patterns)
        {
            ECASSERT([childPattern match] || [childPattern begin]);
            OnigRegexp *patternRegexp = [childPattern match] ? [childPattern match] : [childPattern begin];
            OnigResult *result = [self _firstMatchInRange:currentRange forRegexp:patternRegexp];
            if (!result)
                continue;
            NSRange resultRange = [result bodyRange];
            if (resultRange.location > firstMatchRange.location || (resultRange.location == firstMatchRange.location && resultRange.length < firstMatchRange.length))
                continue;
            firstMatchRange = resultRange;
            firstMatchPattern = childPattern;
        }
        OnigResult *stopResult = regexp ? [self _firstMatchInRange:range forRegexp:regexp] : nil;
        if (stopResult && [stopResult bodyRange].location < firstMatchRange.location)
        {
            NSArray *endCaptures = [self _createScopesInRange:currentRange withRegexp:regexp name:name captures:captures remainingRange:remainingRange];
            if ([endCaptures count])
                [scopes addObjectsFromArray:endCaptures];
            return scopes;
        }
        if (!firstMatchPattern)
            break;
        if ([firstMatchPattern match])
            [scopes addObjectsFromArray:[self _createScopesInRange:currentRange withMatchPattern:firstMatchPattern remainingRange:&currentRange]];
        else
            [scopes addObjectsFromArray:[self _createScopesInRange:currentRange withSpanPattern:firstMatchPattern remainingRange:&currentRange]];
    }
    if (remainingRange)
        *remainingRange = currentRange;
    return scopes;
}

- (NSArray *)_createScopesInRange:(NSRange)range withRegexp:(OnigRegexp *)regexp name:(NSString *)name captures:(NSDictionary *)captures remainingRange:(NSRange *)remainingRange
{
    OnigResult *result = [self _firstMatchInRange:range forRegexp:regexp];
    if (!result)
        return nil;
    NSArray *captureScopes = nil;
    if (captures)
        captureScopes = [self _createScopesForCaptures:captures inResult:result];
    if (remainingRange)
    {
        remainingRange->location = NSMaxRange([result bodyRange]);
        remainingRange->length = NSMaxRange(range) - remainingRange->location;
    }
    if (!name)
        return captureScopes;
    TMScope *scope = [[TMScope alloc] init];
    scope.containingString = [[self index] contentsForFile:self.fileURL];
    ECASSERT([name isKindOfClass:[NSString class]]);
    scope.identifier = name;
    scope.range = [result bodyRange];
    if ([captureScopes count])
    {
        for (TMScope *captureScope in captureScopes)
            captureScope.parent = scope;
        scope.children = captureScopes;
    }
    return [NSArray arrayWithObject:scope];
}

- (NSArray *)_createScopesForCaptures:(NSDictionary *)captures inResult:(OnigResult *)result
{
    NSMutableArray *captureScopes = [NSMutableArray array];
    NSUInteger numMatchRanges = [result count];
    for (NSUInteger currentMatchRangeIndex = 1; currentMatchRangeIndex < numMatchRanges; ++currentMatchRangeIndex)
    {
        NSRange currentMatchRange = [result rangeAt:currentMatchRangeIndex];
        if (!currentMatchRange.length)
            continue;
        NSString *currentCaptureName = [[captures objectForKey:[NSString stringWithFormat:@"%d", currentMatchRangeIndex]] objectForKey:_patternCaptureName];
        if (!currentCaptureName)
            continue;
        TMScope *scope = [[TMScope alloc] init];
        scope.containingString = [[self index] contentsForFile:self.fileURL];
        ECASSERT([currentCaptureName isKindOfClass:[NSString class]]);
        scope.identifier = currentCaptureName;
        scope.range = currentMatchRange;
        [captureScopes addObject:scope];
    }
    return captureScopes;
}

- (OnigResult *)_firstMatchInRange:(NSRange)range forRegexp:(OnigRegexp *)regexp;
{
    OnigResult *result = [_firstMatches objectForKey:regexp];
    if (result && (id)result != [NSNull null] && [result rangeAt:0].location >= range.location && NSMaxRange([result rangeAt:0]) <= NSMaxRange(range))
        return result;
    if ((id)result == [NSNull null])
        return nil;
    result = [regexp search:[[self index] contentsForFile:self.fileURL] range:range];
    if (result)
        [_firstMatches setObject:result forKey:regexp];
    else
        [_firstMatches setObject:[NSNull null] forKey:regexp];
    return result;
}

@end
