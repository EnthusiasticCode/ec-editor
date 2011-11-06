//
//  TMPattern.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMPattern+Internal.h"
#import "TMSyntax+Internal.h"
#import "OnigRegexp.h"

static NSString * const _patternScopeKey = @"name";
static NSString * const _patternNameKey = @"name";
static NSString * const _patternMatchKey = @"match";
static NSString * const _patternBeginKey = @"begin";
static NSString * const _patternEndKey = @"end";
static NSString * const _patternBeginCapturesKey = @"beginCaptures";
static NSString * const _patternEndCapturesKey = @"endCaptures";
static NSString * const _patternCapturesKey = @"captures";
static NSString * const _patternPatternsKey = @"patterns";
static NSString * const _patternIncludeKey = @"include";

static NSArray *_patternsIncludedByPatterns(NSArray *patterns);

@interface TMPattern ()
{
    OnigRegexp *_match;
    NSDictionary *_captures;
    OnigRegexp *_begin;
    OnigRegexp *_end;
    NSDictionary *_beginCaptures;
    NSDictionary *_endCaptures;
    NSArray *_patterns;
    TMSyntax *__syntax;
    NSDictionary *_dictionary;
}
- (id)_initWithSyntax:(TMSyntax *)syntax dictionary:(NSDictionary *)dictionary;
- (TMSyntax *)_syntax;
- (NSString *)_include;
@end

@implementation TMPattern

+ (NSArray *)patternsWithSyntax:(TMSyntax *)syntax inDictionary:(NSDictionary *)dictionary
{
    TMPattern *pattern = [[self alloc] _initWithSyntax:syntax dictionary:dictionary];
    return _patternsIncludedByPatterns([NSArray arrayWithObject:pattern]);
}

- (id)_initWithSyntax:(TMSyntax *)syntax dictionary:(NSDictionary *)dictionary
{
    ECASSERT(syntax && dictionary);
    self = [super init];
    if (!self)
        return nil;
    __syntax = syntax;
    _dictionary = dictionary;
    NSString *matchRegex = [dictionary objectForKey:_patternMatchKey];
    if (matchRegex)
        _match = [OnigRegexp compile:matchRegex options:OnigOptionNotbol | OnigOptionNoteol];
    NSString *beginRegex = [dictionary objectForKey:_patternBeginKey];
    if (beginRegex)
        _begin = [OnigRegexp compile:beginRegex options:OnigOptionNotbol | OnigOptionNoteol];
    NSString *endRegex = [dictionary objectForKey:_patternEndKey];
    if (endRegex)
        _end = [OnigRegexp compile:endRegex  options:OnigOptionNotbol | OnigOptionNoteol];
    ECASSERT(!_match || (![_patterns count] && !_begin && ![self _include] && ![_captures objectForKey:[NSNumber numberWithUnsignedInteger:0]] && ![dictionary objectForKey:_patternBeginCapturesKey] && ![dictionary objectForKey:_patternEndCapturesKey]));
    ECASSERT(!_begin || _end && ![self _include]);
    ECASSERT(!_end || _begin);
    ECASSERT(![self _include] || (![_patterns count] && !_captures && !_beginCaptures && !_endCaptures));
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSUInteger)hash
{
    return [_dictionary hash];
}

- (NSString *)name
{
    return [_dictionary objectForKey:_patternNameKey];
}

- (OnigRegexp *)match
{
    return _match;
}

- (NSDictionary *)captures
{
    if (!_captures)
    {
        ECASSERT(![_dictionary objectForKey:_patternCapturesKey] || (![_dictionary objectForKey:_patternBeginCapturesKey] && ![_dictionary objectForKey:_patternEndCapturesKey]));
        _captures = [_dictionary objectForKey:_patternCapturesKey];
        ECASSERT(!_captures || [_captures count]);
    }
    return _captures;
}

- (OnigRegexp *)begin
{
    return _begin;
}

- (OnigRegexp *)end
{
    return _end;
}

- (NSDictionary *)beginCaptures
{
    if (!_beginCaptures)
    {
        ECASSERT(![_dictionary objectForKey:_patternBeginCapturesKey] || ![_dictionary objectForKey:_patternCapturesKey]);
        _beginCaptures = [_dictionary objectForKey:_patternBeginCapturesKey];
        if (!_beginCaptures)
            _beginCaptures = [_dictionary objectForKey:_patternCapturesKey];
        ECASSERT(!_beginCaptures || [_beginCaptures count]);
    }
    return _beginCaptures;
}

- (NSDictionary *)endCaptures
{
    if (!_endCaptures)
    {
        ECASSERT(![_dictionary objectForKey:_patternEndCapturesKey] || ![_dictionary objectForKey:_patternCapturesKey]);
        _endCaptures = [_dictionary objectForKey:_patternEndCapturesKey];
        if (!_endCaptures)
            _endCaptures = [_dictionary objectForKey:_patternCapturesKey];
        ECASSERT(!_endCaptures || [_endCaptures count]);
    }
    return _endCaptures;
}

- (NSArray *)patterns
{
    if (!_patterns)
    {
        NSMutableArray *patterns = [NSMutableArray array];
        for (NSDictionary *dictionary in [_dictionary objectForKey:_patternPatternsKey])
            [patterns addObjectsFromArray:[[self class] patternsWithSyntax:[self _syntax] inDictionary:dictionary]];
        _patterns = [patterns count] ? [patterns copy] : (NSArray *)[NSNull null];
    }
    return (id)_patterns == [NSNull null] ? nil : _patterns;
}

- (TMSyntax *)_syntax
{
    return __syntax;
}

- (NSString *)_include
{
    return [_dictionary objectForKey:_patternIncludeKey];
}

- (NSDictionary *)_debugDictionary
{
    return _dictionary;
}

@end

static NSArray *_patternsIncludedByPatterns(NSArray *patterns)
{
    NSMutableArray *includedPatterns = [NSMutableArray arrayWithArray:patterns];
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
            if ([dereferencedPatterns containsObject:containerPattern])
                return;
            ECASSERT([containerPattern _include] || [containerPattern patterns]);
            ECASSERT(![containerPattern _include] || ![containerPattern patterns]);
            if ([containerPattern _include])
            {
                unichar firstCharacter = [[containerPattern _include] characterAtIndex:0];
                if (firstCharacter == '#')
                {
                    TMSyntax *patternSyntax = [containerPattern _syntax];
                    [patternSyntax beginContentAccess];
                    [includedPatterns addObject:[[TMPattern alloc] _initWithSyntax:patternSyntax dictionary:[[patternSyntax repository] objectForKey:[[containerPattern _include] substringFromIndex:1]]]];
                    [patternSyntax endContentAccess];
                }
                else
                {
                    TMSyntax *includedSyntax = (firstCharacter == '$') ? [containerPattern _syntax] : [TMSyntax syntaxWithScope:[containerPattern _include]];
                    [includedSyntax beginContentAccess];
                    for (NSDictionary *dictionary in [includedSyntax patternsDictionaries])
                        [includedPatterns addObject:[[TMPattern alloc] _initWithSyntax:includedSyntax dictionary:dictionary]];
                    [includedSyntax endContentAccess];
                }
            }
            else
            {
                [includedPatterns addObjectsFromArray:[containerPattern patterns]];
            }
            [dereferencedPatterns addObject:containerPattern];
            [includedPatterns removeObjectAtIndex:idx];
        }];
    }
    while ([containerPatternIndexes count]);
    return includedPatterns;
}
