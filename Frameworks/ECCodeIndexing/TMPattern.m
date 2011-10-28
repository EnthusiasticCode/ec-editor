//
//  TMPattern.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMPattern.h"

#import "OnigRegexp.h"

static NSString * const _patternNameKey = @"name";
static NSString * const _patternMatchKey = @"match";
static NSString * const _patternBeginKey = @"begin";
static NSString * const _patternEndKey = @"end";
static NSString * const _patternBeginCapturesKey = @"beginCaptures";
static NSString * const _patternEndCapturesKey = @"endCaptures";
static NSString * const _patternCapturesKey = @"captures";
static NSString * const _patternPatternsKey = @"patterns";
static NSString * const _patternIncludeKey = @"include";

@interface TMPattern ()
{
    __weak NSString *_cachedMatchString;
    NSMatchingOptions _cachedMatchOptions;
    NSRange _cachedMatchRange;
    NSTextCheckingResult *_cachedMatchResult;
    
    OnigRegexp *_match;
    NSDictionary *_captures;
    OnigRegexp *_begin;
    OnigRegexp *_end;
    NSDictionary *_beginCaptures;
    NSDictionary *_endCaptures;
    NSArray *_patterns;
    
    NSDictionary *_dictionary;
}
@end

@implementation TMPattern

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
            [patterns addObject:[[[self class] alloc] initWithDictionary:dictionary]];
        if ([patterns count])
            _patterns = [patterns copy];
        ECASSERT(!_patterns || [_patterns count]);
    }
    return _patterns;
}

- (NSString *)include
{
    return [_dictionary objectForKey:_patternIncludeKey];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self)
        return nil;
    _dictionary = dictionary;
    NSString *matchRegex = [dictionary objectForKey:_patternMatchKey];
    if (matchRegex)
        _match = [OnigRegexp compile:matchRegex ignorecase:NO multiline:YES];
    NSString *beginRegex = [dictionary objectForKey:_patternBeginKey];
    if (beginRegex)
        _begin = [OnigRegexp compile:beginRegex ignorecase:NO multiline:YES];
    NSString *endRegex = [dictionary objectForKey:_patternEndKey];
    if (endRegex)
        _end = [OnigRegexp compile:endRegex ignorecase:NO multiline:YES];
    ECASSERT(!_match || (![_patterns count] && !_begin && ![self include] && ![_captures objectForKey:[NSNumber numberWithUnsignedInteger:0]] && ![dictionary objectForKey:_patternBeginCapturesKey] && ![dictionary objectForKey:_patternEndCapturesKey]));
    ECASSERT(!_begin || _end && ![self include]);
    ECASSERT(!_end || _begin);
    ECASSERT(![self include] || (![_patterns count] && !_captures && !_beginCaptures && !_endCaptures));
    return self;
}

@end
