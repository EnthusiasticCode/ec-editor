//
//  CodeScope.m
//  CodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMScope.h"

/// Caches a scope identifier to a dictionary of scope selector references to scores.
NSMutableDictionary *systemScopesScoreCache;

@interface TMScope ()

/// Return a number indicating how much a scope selector array matches the search.
/// A scope selector array is an array of strings defining a context of scopes where
/// a scope must be child of the previous scope in the array.
- (float)_scoreQueryScopeArray:(NSArray *)query forSearchScopeArray:(NSArray *)search;

/// Returns a number indicating how much the receiver matches the search scope selector.
/// A scope selector reference is a string containing a single scope context (ie: scopes divided by spaces).
- (float)_scoreForSearchScope:(NSString *)search;

@end

// Reference implementation: https://github.com/cehoffman/textpow/blob/master/lib/textpow/score_manager.rb
@implementation TMScope {
    /// The string range of the scope's identifier in it's qualified identifier.
    NSRange _identifierRange;
    NSMutableArray *_children;
}

#pragma mark - Class methods

+ (void)prepareForBackground
{
    [systemScopesScoreCache removeAllObjects];
}

#pragma mark - Properties

@synthesize location, length, parent, children = _children, qualifiedIdentifier, identifiersStack;

- (NSString *)identifier
{
    return [qualifiedIdentifier substringWithRange:_identifierRange];
}

#pragma mark - Initializers

- (id)initWithParent:(TMScope *)aParentScope identifier:(NSString *)anIdentifier
{
    self = [super init];
    if (!self)
        return nil;
    parent = aParentScope;
    NSString *parentQualifiedIdentifier = parent.qualifiedIdentifier;
    _identifierRange.location = [parentQualifiedIdentifier length];
    if (_identifierRange.location > 0)
    {
        qualifiedIdentifier = [NSString stringWithFormat:@"%@ %@", parentQualifiedIdentifier, anIdentifier];
        _identifierRange.location++;
    }
    else
    {
        qualifiedIdentifier = anIdentifier;
    }
    _identifierRange.length = [anIdentifier length];
    identifiersStack = parent ? [parent.identifiersStack arrayByAddingObject:anIdentifier] : [NSArray arrayWithObject:anIdentifier];

    return self;
}

- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier
{
    ECASSERT(identifier);
    TMScope *childScope = [[[self class] alloc] initWithParent:self identifier:identifier];
    if (!_children)
        _children = [NSMutableArray new];
    [_children addObject:childScope];
    return childScope;
}

#pragma mark - Scoring

- (float)scoreForScopeSelector:(NSString *)scopeSelector
{
    // Check for cached value
    if(!systemScopesScoreCache)
        systemScopesScoreCache = [NSMutableDictionary new];
    NSMutableDictionary *scopeToScore = [systemScopesScoreCache objectForKey:scopeSelector];
    NSNumber *cachedScore = [scopeToScore objectForKey:self.qualifiedIdentifier];
    if (cachedScore)
        return [cachedScore floatValue];
    
    // Compute value
    static NSCharacterSet *spaceCharacterSet = nil; if (!spaceCharacterSet) spaceCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
    
    float score = 0;
    for (NSString *searchScope in [scopeSelector componentsSeparatedByString:@","])
    {
        NSArray *searchScopeComponents = [[searchScope stringByTrimmingCharactersInSet:spaceCharacterSet] componentsSeparatedByString:@" - "];
        if ([searchScopeComponents count] == 1)
        {
            score = MAX(score, [self _scoreForSearchScope:[searchScopeComponents objectAtIndex:0]]);
        }
        else
        {
            __block BOOL exclude = NO;
            [searchScopeComponents enumerateObjectsUsingBlock:^(NSString *excludeScope, NSUInteger idx, BOOL *stop) {
                if (idx && [self _scoreForSearchScope:excludeScope] > 0)
                {
                    exclude = YES;
                    *stop = YES;
                }
            }];
            if (exclude)
                continue;
            score = MAX(score, [self _scoreForSearchScope:[searchScopeComponents objectAtIndex:0]]);
        }
    }
    
    // Store in cache
    if (!scopeToScore)
    {
        scopeToScore = [NSMutableDictionary new];
        [systemScopesScoreCache setObject:scopeToScore forKey:scopeSelector];
    }
    [scopeToScore setObject:[NSNumber numberWithFloat:score] forKey:self.qualifiedIdentifier];
    
    return score;
}

- (float)_scoreForSearchScope:(NSString *)search
{
    return [self _scoreQueryScopeArray:self.identifiersStack forSearchScopeArray:[search componentsSeparatedByString:@" "]];
}

#define POINT_DEPTH    4.0f
#define NESTING_DEPTH  30.0f
#define BASE           16.0f

- (float)_scoreQueryScopeArray:(NSArray *)query forSearchScopeArray:(NSArray *)search
{
    static float start_value = 0; if (!start_value) start_value = powf(2, (POINT_DEPTH * NESTING_DEPTH));
    static NSRegularExpression *dotRegExp = nil; if (!dotRegExp) dotRegExp = [NSRegularExpression regularExpressionWithPattern:@"." options:NSRegularExpressionIgnoreMetacharacters error:NULL];
    
    float multiplier = start_value;
    float result = 0;
    // The scopes will be enumerated from the most specific up.
    NSEnumerator *searchEnumerator = [search reverseObjectEnumerator];
    NSString *currentSearch = [searchEnumerator nextObject];
    for (NSString *currentQuery in [query reverseObjectEnumerator])
    {
        if (!currentSearch)
            break;
        // In case the current query scope starts with the search scope a score can be computed
        if ([currentQuery hasPrefix:currentSearch])
        {
            result += (BASE - [dotRegExp numberOfMatchesInString:currentQuery options:0 range:NSMakeRange(0, [currentQuery length])] + [dotRegExp numberOfMatchesInString:currentSearch options:0 range:NSMakeRange(0, [currentSearch length])]) * multiplier;
            currentSearch = [searchEnumerator nextObject];
        }
        multiplier /= BASE;
    }
    // Return the result only if the whole search array has been evaluated
    ECASSERT(result < INFINITY);
    return currentSearch == nil ? result : 0;
}

@end
