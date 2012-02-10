//
//  CodeScope.m
//  CodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMScope+Internal.h"

/// Caches a scope identifier to a dictionary of scope selector references to scores.
NSMutableDictionary *systemScopesScoreCache;

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

@synthesize syntaxNode = _syntaxNode, location = _location, length = _length, completelyParsed = _completelyParsed, parent = _parent, children = _children, qualifiedIdentifier = _qualifiedIdentifier, identifiersStack = _identifiersStack;

- (NSString *)identifier
{
    if (!_identifierRange.length)
        return nil;
    return [_qualifiedIdentifier substringWithRange:_identifierRange];
}

- (void)setIdentifier:(NSString *)identifier
{
    [self willChangeValueForKey:@"identifier"];
    NSString *parentQualifiedIdentifier = self.parent.qualifiedIdentifier;    
    _identifierRange.location = [parentQualifiedIdentifier length];
    if (_identifierRange.location > 0)
    {
        if ([identifier length])
        {
            _qualifiedIdentifier = [NSString stringWithFormat:@"%@ %@", parentQualifiedIdentifier, identifier];
            _identifierRange.location++;
            _identifiersStack = [self.parent.identifiersStack arrayByAddingObject:identifier];
        }
        else
        {
            _qualifiedIdentifier = parentQualifiedIdentifier;
            _identifiersStack = self.parent.identifiersStack;
        }
    }
    else
    {
        _qualifiedIdentifier = identifier;
        _identifiersStack = identifier ? [NSArray arrayWithObject:identifier] : nil;
    }
    _identifierRange.length = [identifier length];
    [self didChangeValueForKey:@"identifier"];
}

#pragma mark - Initializers

- (TMScope *)newChildScope
{
    TMScope *childScope = [[[self class] alloc] init];
    childScope.parent = self;
    if (!_children)
        _children = [NSMutableArray new];
    [_children addObject:childScope];
    return childScope;
}

#pragma mark - Scoring
// Reference implementation: https://github.com/cehoffman/textpow/blob/master/lib/textpow/score_manager.rb

- (float)scoreForScopeSelector:(NSString *)scopeSelector
{
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
            ECASSERT([searchScopeComponents count] == 2 && "Only one '-' is allowed in a scope selector");
            if ([self _scoreForSearchScope:[searchScopeComponents objectAtIndex:1]] > 0)
                continue;
            score = MAX(score, [self _scoreForSearchScope:[searchScopeComponents objectAtIndex:0]]);
        }
    }
    return score;
}

- (float)_scoreForSearchScope:(NSString *)search
{
    if(!systemScopesScoreCache)
        systemScopesScoreCache = [NSMutableDictionary new];
    NSMutableDictionary *scopeReferenceToScore = [systemScopesScoreCache objectForKey:self.qualifiedIdentifier];
    NSNumber *score = [scopeReferenceToScore objectForKey:search];
    if (score)
        return [score floatValue];
    score = [NSNumber numberWithFloat:[self _scoreQueryScopeArray:self.identifiersStack forSearchScopeArray:[search componentsSeparatedByString:@" "]]];
    if (!scopeReferenceToScore)
    {
        scopeReferenceToScore = [NSMutableDictionary new];
        [systemScopesScoreCache setObject:scopeReferenceToScore forKey:self.qualifiedIdentifier];
    }
    [scopeReferenceToScore setObject:score forKey:search];
    return [score floatValue];
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
