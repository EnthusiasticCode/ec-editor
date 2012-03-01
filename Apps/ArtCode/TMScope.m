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

@interface TMScope ()
{
    /// The string range of the scope's identifier in it's qualified identifier.
    NSRange _identifierRange;
    NSMutableArray *_children;
    struct
    {
        unsigned didAddScope : 1;
        unsigned willRemoveScope : 1;
        unsigned reserved:6;
    } _delegateFlags;
}

- (id)_initWithParent:(TMScope *)parent identifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode;

/// Return a number indicating how much a scope selector array matches the search.
/// A scope selector array is an array of strings defining a context of scopes where
/// a scope must be child of the previous scope in the array.
- (float)_scoreQueryScopeArray:(NSArray *)query forSearchScopeArray:(NSArray *)search;

/// Returns a number indicating how much the receiver matches the search scope selector.
/// A scope selector reference is a string containing a single scope context (ie: scopes divided by spaces).
- (float)_scoreForSearchScope:(NSString *)search;

@end

@implementation TMScope

#pragma mark - Class methods

+ (void)prepareForBackground
{
    [systemScopesScoreCache removeAllObjects];
}

#pragma mark - Properties

@synthesize syntaxNode = _syntaxNode, delegate = _delegate, endRegexp = _endRegexp, location = _location, length = _length, parent = _parent, qualifiedIdentifier = _qualifiedIdentifier, identifiersStack = _identifiersStack;

- (void)setDelegate:(id<TMScopeDelegate>)delegate
{
    if (delegate == _delegate)
        return;
    _delegate = delegate;
    _delegateFlags.didAddScope = [delegate respondsToSelector:@selector(scope:didAddScope:)];
    _delegateFlags.willRemoveScope = [delegate respondsToSelector:@selector(scope:willRemoveScope:)];
}

- (NSString *)identifier
{
    if (!_identifierRange.length)
        return nil;
    return [_qualifiedIdentifier substringWithRange:_identifierRange];
}

- (NSArray *)children
{
    return [_children copy];
}

+ (NSSet *)keyPathsForValuesAffectingQualifiedIdentifier
{
    return [NSSet setWithObject:@"identifier"];
}

- (id)_initWithParent:(TMScope *)parent identifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode
{
    self = [super init];
    if (!self)
        return nil;
    NSString *parentQualifiedIdentifier = parent.qualifiedIdentifier;    
    _identifierRange.location = [parentQualifiedIdentifier length];
    if (_identifierRange.location > 0)
    {
        if ([identifier length])
        {
            _qualifiedIdentifier = [NSString stringWithFormat:@"%@ %@", parentQualifiedIdentifier, identifier];
            _identifierRange.location++;
            _identifiersStack = [parent.identifiersStack arrayByAddingObject:identifier];
        }
        else
        {
            _qualifiedIdentifier = parentQualifiedIdentifier;
            _identifiersStack = parent.identifiersStack;
        }
    }
    else
    {
        _qualifiedIdentifier = identifier;
        _identifiersStack = identifier ? [NSArray arrayWithObject:identifier] : nil;
    }
    _identifierRange.length = [identifier length];
    _syntaxNode = syntaxNode;
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    TMScope *copy = [[TMScope alloc] init];
    copy->_qualifiedIdentifier = _qualifiedIdentifier;
    copy->_identifierRange = _identifierRange;
    copy->_identifiersStack = _identifiersStack;
    copy->_location = _location;
    copy->_length = _length;
    return copy;
}

- (NSString *)description
{
    return [[super description] stringByAppendingString:self.qualifiedIdentifier];
}

#pragma mark - Initializers

static NSComparisonResult (^childScopeComparator)(TMScope *, TMScope *) = ^NSComparisonResult(TMScope *first, TMScope *second){
    if (first.location < second.location)
        return NSOrderedAscending;
    else if (first.location > second.location)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
};

- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode location:(NSUInteger)location
{
    TMScope *childScope = [[[self class] alloc] _initWithParent:self identifier:identifier syntaxNode:syntaxNode];
    childScope->_location = location;
    if (!_children)
        _children = [NSMutableArray new];
    NSUInteger childInsertionIndex = [_children indexOfObject:childScope inSortedRange:NSMakeRange(0, [_children count]) options:NSBinarySearchingInsertionIndex usingComparator:childScopeComparator];
    if (childInsertionIndex == [_children count])
        [_children addObject:childScope];
    else
        [_children insertObject:childScope atIndex:childInsertionIndex];
    if (_delegateFlags.didAddScope)
        [_delegate scope:self didAddScope:childScope];
    return childScope;
}

+ (TMScope *)newRootScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode
{
    return [[self alloc] _initWithParent:nil identifier:identifier syntaxNode:syntaxNode];
}

#pragma mark - Scope Tree Querying

- (NSMutableArray *)scopeStackAtOffset:(NSUInteger)offset options:(TMScopeQueryOptions)options
{
    ECASSERT(!_parent);
    if (offset >= _length)
        return nil;
    NSMutableArray *scopeStack = [NSMutableArray arrayWithObject:self];
    for (;;)
    {
        BOOL recurse = NO;
        for (TMScope *childScope in ((TMScope *)scopeStack.lastObject)->_children)
        {
            NSRange childScopeRange = NSMakeRange(childScope->_location, childScope->_length);
            NSUInteger childScopeEnd = NSMaxRange(childScopeRange);
            if ((options == TMScopeQueryContainedOnly && childScopeRange.location < offset && childScopeEnd > offset)
                || (options == TMScopeQueryAdjacentStart && childScopeRange.location <= offset && childScopeEnd > offset)
                || (options == TMScopeQueryAdjacentEnd && childScopeRange.location < offset && childScopeEnd > offset))
            {
                [scopeStack addObject:childScope];
                recurse = YES;
                break;
            }
        }
        if (!recurse)
            break;
    }
    return scopeStack;
}

#pragma mark - Scope Tree Changes

- (void)shiftByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange
{
    ECASSERT(oldRange.location == newRange.location);
    ECASSERT(!_parent);
    
    NSMutableArray *scopeEnumeratorStack = [NSMutableArray arrayWithObject:[[NSArray arrayWithObject:self] objectEnumerator]];
    NSUInteger oldRangeEnd = NSMaxRange(oldRange);
    NSInteger offset = newRange.length - oldRange.length;
    // Enumerate all the scopes and adjust them for the change
    while ([scopeEnumeratorStack count])
    {
        TMScope *scope = nil;
        while (scope = [[scopeEnumeratorStack lastObject] nextObject])
        {
            NSRange scopeRange = NSMakeRange(scope->_location, scope->_length);
            if (NSMaxRange(scopeRange) <= oldRange.location)
            {
                // If the scope is before the affected range, continue to the next scope
                continue;
            }
            else if (scopeRange.location >= oldRange.location && scopeRange.location < oldRangeEnd)
            {
                // If the scope's start is within the affected range it's going to get removed during regeneration, just continue to the next scope
                continue;
            }
            else if (scopeRange.location >= oldRangeEnd)
            {
                // If the scope is past the affected range, shift the location
                scope->_location += offset;
            }
            else if (NSMaxRange(scopeRange) < oldRangeEnd)
            {
                // If the affected range overlaps the tail of the scope, cut it off
                scope->_length -= NSIntersectionRange(scopeRange, oldRange).length;
            }
            else
            {
                // If the scope is none of the above, the affected range is completely contained in it, let's stretch it to cover the difference
                ECASSERT(oldRange.length < scopeRange.length && scopeRange.location < oldRange.location && NSMaxRange(scopeRange) >= NSMaxRange(oldRange));
                scope->_length += offset;
            }
            
            // Recurse over the scope's children
            if (scope->_children.count)
                [scopeEnumeratorStack addObject:scope->_children.objectEnumerator];
        }
        [scopeEnumeratorStack removeLastObject];
    }
}

- (void)removeChildScopesInRange:(NSRange)range
{
    ECASSERT(!_parent);
    NSMutableArray *childScopeIndexStack = [[NSMutableArray alloc] init];
    TMScope *scope = self;
    NSUInteger childScopeIndex = 0;
    for (;;)
    {
        if (childScopeIndex + 1 <= scope->_children.count)
        {
            TMScope *childScope = [scope->_children objectAtIndex:childScopeIndex];
            NSRange childScopeRange = NSMakeRange(childScope->_location, childScope->_length);
            if (NSMaxRange(childScopeRange) <= range.location)
            {
                // If the child scope is before the affected range, continue to the next scope
                ++childScopeIndex;
                continue;
            }
            else if (childScopeRange.location >= range.location && childScopeRange.location < NSMaxRange(range))
            {
                // If the child scope's start is within the affected range, delete it
                if (_delegateFlags.willRemoveScope)
                    [_delegate scope:self willRemoveScope:childScope];
                [scope->_children removeObjectAtIndex:childScopeIndex];
                continue;
            }
            else if (childScopeRange.location < NSMaxRange(range))
            {
                // If it's neither of the above two cases, but it doesn't start after the line either, it means it overlaps, recurse over it's children
                [childScopeIndexStack addObject:[NSNumber numberWithUnsignedInteger:childScopeIndex]];
                childScopeIndex = 0;
                scope = childScope;
                continue;
            }
        }
        // If we got here it means we're done enumerating this scope's children, go back to enumerating it's siblings
        if (!childScopeIndexStack.count)
            break;
        childScopeIndex = [[childScopeIndexStack lastObject] unsignedIntegerValue];
        [childScopeIndexStack removeLastObject];
        ++childScopeIndex;
        scope = scope->_parent;
        if (!scope)
            break;
    }
}


#pragma mark - Scoring
// Reference implementation: https://github.com/cehoffman/textpow/blob/master/lib/textpow/score_manager.rb

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
    static NSCharacterSet *trimCharacterSet = nil; if (!trimCharacterSet) trimCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" ()"];
    float score = 0;
    for (NSString *singleSearch in [search componentsSeparatedByString:@"|"])
    {
        score = MAX(score, [self _scoreQueryScopeArray:self.identifiersStack forSearchScopeArray:[[singleSearch stringByTrimmingCharactersInSet:trimCharacterSet] componentsSeparatedByString:@" "]]);
    }
    return score;
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

#pragma mark - Debug Methods

#if DEBUG

- (void)_checkConsistency
{
    if (!self.children.count)
        return;
    
    NSUInteger scopeEnd = self.location + self.length;
    NSUInteger previousChildLocation = 0;
    
    for (TMScope *childScope in self.children)
    {
        ECASSERT(previousChildLocation <= childScope.location);
        ECASSERT(childScope.location + childScope.length <= scopeEnd);
        previousChildLocation = childScope.location;
        [childScope _checkConsistency];
    }
}

#endif

@end
