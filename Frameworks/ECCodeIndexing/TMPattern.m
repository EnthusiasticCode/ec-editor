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
}
@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, strong) OnigRegexp *match;
@property (nonatomic, strong) OnigRegexp *begin;
@property (nonatomic, strong) OnigRegexp *end;
@end

@implementation TMPattern

@synthesize dictionary = _dictionary;
@synthesize match = _match;
@synthesize captures = _captures;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize beginCaptures = _beginCaptures;
@synthesize endCaptures = _endCaptures;
@synthesize patterns = _patterns;

- (NSString *)name
{
    return [self.dictionary objectForKey:_patternNameKey];
}

- (NSDictionary *)captures
{
    if (!_captures)
    {
        ECASSERT(![self.dictionary objectForKey:_patternCapturesKey] || (![self.dictionary objectForKey:_patternBeginCapturesKey] && ![self.dictionary objectForKey:_patternEndCapturesKey]));
        _captures = [self.dictionary objectForKey:_patternCapturesKey];
        ECASSERT(!_captures || [_captures count]);
    }
    return _captures;
}

- (NSDictionary *)beginCaptures
{
    if (!_beginCaptures)
    {
        ECASSERT(![self.dictionary objectForKey:_patternBeginCapturesKey] || ![self.dictionary objectForKey:_patternCapturesKey]);
        _beginCaptures = [self.dictionary objectForKey:_patternBeginCapturesKey];
        if (!_beginCaptures)
            _beginCaptures = [self.dictionary objectForKey:_patternCapturesKey];
        ECASSERT(!_beginCaptures || [_beginCaptures count]);
    }
    return _beginCaptures;
}

- (NSDictionary *)endCaptures
{
    if (!_endCaptures)
    {
        ECASSERT(![self.dictionary objectForKey:_patternEndCapturesKey] || ![self.dictionary objectForKey:_patternCapturesKey]);
        _endCaptures = [self.dictionary objectForKey:_patternEndCapturesKey];
        if (!_endCaptures)
            _endCaptures = [self.dictionary objectForKey:_patternCapturesKey];
        ECASSERT(!_endCaptures || [_endCaptures count]);
    }
    return _endCaptures;
}

- (NSArray *)patterns
{
    if (!_patterns)
    {
        NSMutableArray *patterns = [NSMutableArray array];
        for (NSDictionary *dictionary in [self.dictionary objectForKey:_patternPatternsKey])
            [patterns addObject:[[[self class] alloc] initWithDictionary:dictionary]];
        if ([patterns count])
            _patterns = [patterns copy];
        ECASSERT(!_patterns || [_patterns count]);
    }
    return _patterns;
}

- (NSString *)include
{
    return [self.dictionary objectForKey:_patternIncludeKey];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self)
        return nil;
    self.dictionary = dictionary;
    NSString *matchRegex = [dictionary objectForKey:_patternMatchKey];
    if (matchRegex)
        self.match = [OnigRegexp compile:matchRegex ignorecase:NO multiline:YES];
    NSString *beginRegex = [dictionary objectForKey:_patternBeginKey];
    if (beginRegex)
        self.begin = [OnigRegexp compile:beginRegex ignorecase:NO multiline:YES];
    NSString *endRegex = [dictionary objectForKey:_patternEndKey];
    if (endRegex)
        self.end = [OnigRegexp compile:endRegex ignorecase:NO multiline:YES];
    ECASSERT(!self.match || (![self.patterns count] && !self.begin && !self.include && ![self.captures objectForKey:[NSNumber numberWithUnsignedInteger:0]] && ![dictionary objectForKey:_patternBeginCapturesKey] && ![dictionary objectForKey:_patternEndCapturesKey]));
    ECASSERT(!self.begin || self.end && !self.include);
    ECASSERT(!self.end || self.begin);
    ECASSERT(!self.include || (![self.patterns count] && !self.captures && !self.beginCaptures && !self.endCaptures));
    return self;
}

@end
