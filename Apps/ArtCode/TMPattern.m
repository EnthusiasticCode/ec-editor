//
//  TMPattern.m
//  CodeIndexing
//
//  Created by Uri Baghin on 11/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMPattern.h"
#import "TMSyntax.h"
#import "OnigRegexp.h"
#import "WeakDictionary.h"

static NSString * const _patternScopeKey = @"name";
static NSString * const _patternNameKey = @"name";
static NSString * const _patternContentNameKey = @"contentName";
static NSString * const _patternMatchKey = @"match";
static NSString * const _patternBeginKey = @"begin";
static NSString * const _patternEndKey = @"end";
static NSString * const _patternBeginCapturesKey = @"beginCaptures";
static NSString * const _patternEndCapturesKey = @"endCaptures";
static NSString * const _patternCapturesKey = @"captures";
static NSString * const _patternPatternsKey = @"patterns";
static NSString * const _patternIncludeKey = @"include";

static WeakDictionary *_allPatterns;

@interface TMPattern ()
{
    NSString *_syntaxScope;
    OnigRegexp *_match;
    NSDictionary *_captures;
    OnigRegexp *_begin;
    OnigRegexp *_beginAndEnd;
    NSDictionary *_beginCaptures;
    NSDictionary *_endCaptures;
    NSArray *_patterns;
    NSDictionary *_dictionary;
}
- (id)_initWithDictionary:(NSDictionary *)dictionary inSyntax:(TMSyntax *)syntax;
@end

@implementation TMPattern

+ (void)initialize
{
    if (self != [TMPattern class])
        return;
    _allPatterns = [[WeakDictionary alloc] init];
}

+ (TMPattern *)patternWithDictionary:(NSDictionary *)dictionary inSyntax:(TMSyntax *)syntax
{
    TMPattern *pattern = [_allPatterns objectForKey:dictionary];
    if (!pattern)
    {
        pattern = [[self alloc] _initWithDictionary:dictionary inSyntax:syntax];
        [_allPatterns setObject:pattern forKey:dictionary];
    }
    return pattern;
}

- (id)_initWithDictionary:(NSDictionary *)dictionary inSyntax:(TMSyntax *)syntax
{
    ECASSERT(syntax && dictionary);
    self = [super init];
    if (!self)
        return nil;
    _syntaxScope = [syntax scopeIdentifier];
    ECASSERT(_syntaxScope);
    _dictionary = dictionary;
    NSError *error = nil;
    NSString *matchRegex = [dictionary objectForKey:_patternMatchKey];
    if (matchRegex)
        _match = [OnigRegexp compile:matchRegex options:0 error:&error];
    if (error)
        NSLog(@"%@", [error localizedDescription]);
    NSString *beginRegex = [dictionary objectForKey:_patternBeginKey];
    if (beginRegex)
        _begin = [OnigRegexp compile:beginRegex options:0 error:&error];
    if (error)
        NSLog(@"%@", [error localizedDescription]);
    NSString *endRegex = [dictionary objectForKey:_patternEndKey];
    if (endRegex)
        // concatenate the begin and end regex, setting all the regex flags back to defaults and putting a non-greedy match all in the middle
        _beginAndEnd = [OnigRegexp compile:[NSString stringWithFormat:@"%@(?-mix)(?:.|\n)*?(%@)", beginRegex, endRegex] options:0 error:&error];
    if (error)
        NSLog(@"%@", [error localizedDescription]);
    ECASSERT(!_match || (![self patterns] && !_begin && ![self include] && ![_captures objectForKey:[NSNumber numberWithUnsignedInteger:0]] && ![dictionary objectForKey:_patternBeginCapturesKey] && ![dictionary objectForKey:_patternEndCapturesKey]));
    ECASSERT(!_begin || _beginAndEnd && ![self include]);
    ECASSERT(!_beginAndEnd || _begin);
    ECASSERT(![self contentName] || _begin);
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

- (TMSyntax *)syntax
{
    ECASSERT([TMSyntax syntaxWithScope:_syntaxScope]);
    return [TMSyntax syntaxWithScope:_syntaxScope];
}

- (NSString *)name
{
    return [_dictionary objectForKey:_patternNameKey];
}

- (NSString *)contentName
{
    return [_dictionary objectForKey:_patternContentNameKey];
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

- (OnigRegexp *)beginAndEnd
{
    return _beginAndEnd;
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
        if (![_dictionary objectForKey:_patternPatternsKey])
            return nil;
        NSMutableArray *patterns = [NSMutableArray array];
        for (NSDictionary *dictionary in [_dictionary objectForKey:_patternPatternsKey])
            [patterns addObject:[[self class] patternWithDictionary:dictionary inSyntax:[self syntax]]];
        _patterns = [patterns copy];
    }
    return _patterns;
}

- (NSString *)include
{
    return [_dictionary objectForKey:_patternIncludeKey];
}

@end
