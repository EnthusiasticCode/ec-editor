//
//  TMPattern.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 10/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TMPattern.h"

static NSString * const _patternNameKey = @"name";
static NSString * const _patternMatchKey = @"match";
static NSString * const _patternBeginKey = @"begin";
static NSString * const _patternEndKey = @"end";
static NSString * const _patternCapturesKey = @"captures";
static NSString * const _patternPatternsKey = @"patterns";

@interface TMPattern ()
{
    __weak NSString *_cachedMatchString;
    NSMatchingOptions _cachedMatchOptions;
    NSRange _cachedMatchRange;
    NSTextCheckingResult *_cachedMatchResult;
}
@property (nonatomic, strong) NSDictionary *dictionary;
@property (nonatomic, strong) NSRegularExpression *match;
@property (nonatomic, strong) NSRegularExpression *begin;
@property (nonatomic, strong) NSRegularExpression *end;
- (NSTextCheckingResult *)_cachedResultInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;
@end

@implementation TMPattern

@synthesize dictionary = _dictionary;
@synthesize match = _match;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize patterns = _patterns;

- (NSString *)name
{
    return [self.dictionary objectForKey:_patternNameKey];
}

- (NSDictionary *)captures
{
    return [self.dictionary objectForKey:_patternCapturesKey];
}

- (NSArray *)patterns
{
    if (!_patterns)
    {
        NSMutableArray *patterns = [NSMutableArray array];
        for (NSDictionary *dictionary in [self.dictionary objectForKey:_patternPatternsKey])
            [patterns addObject:[[[self class] alloc] initWithDictionary:dictionary]];
        _patterns = [patterns copy];
    }
    return _patterns;
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (!self)
        return nil;
    self.dictionary = dictionary;
    NSString *matchRegex = [dictionary objectForKey:_patternMatchKey];
    if (matchRegex)
        self.match = [NSRegularExpression regularExpressionWithPattern:matchRegex options:0 error:NULL];
    NSString *beginRegex = [dictionary objectForKey:_patternBeginKey];
    if (beginRegex)
        self.begin = [NSRegularExpression regularExpressionWithPattern:beginRegex options:0 error:NULL];
    NSString *endRegex = [dictionary objectForKey:_patternEndKey];
    if (endRegex)
        self.end = [NSRegularExpression regularExpressionWithPattern:endRegex options:0 error:NULL];
    ECASSERT(!self.match || (!self.patterns && [self.captures objectForKey:[NSNumber numberWithUnsignedInteger:0]]));
    return self;
}

- (NSTextCheckingResult *)firstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range
{
    NSTextCheckingResult *result = [self _cachedResultInString:string options:options range:range];
    if (result)
        return result;
    if (self.match)
    {
        result = [self.match firstMatchInString:string options:options range:range];
    }
    
    _cachedMatchString = string;
    _cachedMatchOptions = options;
    _cachedMatchRange = range;
    _cachedMatchResult = result;
    return result;
}

- (NSTextCheckingResult *)_cachedResultInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range
{
    return nil;
}

@end
