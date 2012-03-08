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

- (id)_initWithParent:(TMScope *)parent identifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode type:(TMScopeType)type;

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

@synthesize syntaxNode = _syntaxNode, delegate = _delegate, endRegexp = _endRegexp, location = _location, length = _length, flags = _flags, parent = _parent, qualifiedIdentifier = _qualifiedIdentifier, identifiersStack = _identifiersStack, type = _type;

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

- (id)_initWithParent:(TMScope *)parent identifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode type:(TMScopeType)type
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
    _type = type;
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

- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode location:(NSUInteger)location type:(TMScopeType)type
{
    ECASSERT(!identifier || [identifier isKindOfClass:[NSString class]]);
    TMScope *childScope = [[[self class] alloc] _initWithParent:self identifier:identifier syntaxNode:syntaxNode type:type];
    childScope->_location = location;
    childScope->_parent = self;
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
    return [[self alloc] _initWithParent:nil identifier:identifier syntaxNode:syntaxNode type:TMScopeTypeRoot];
}

- (void)removeFromParent
{
    ECASSERT(_parent && _parent->_children && [_parent->_children containsObject:self]);
    // We're only using it on span and content type scopes at the moment
    ECASSERT(_type == TMScopeTypeContent || _type == TMScopeTypeSpan);
    if (_type == TMScopeTypeContent)
        _parent->_flags &= ~TMScopeHasContentScope;
    [_parent->_children removeObject:self];
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
            if (childScopeRange.location > offset)
                break;
            NSUInteger childScopeEnd = NSMaxRange(childScopeRange);
            if ((options == TMScopeQueryContainedOnly && childScopeRange.location < offset && childScopeEnd > offset)
                || (options == TMScopeQueryAdjacentStart && childScopeRange.location <= offset && childScopeEnd > offset)
                || (options == TMScopeQueryAdjacentEnd && childScopeRange.location < offset && childScopeEnd >= offset))
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

#define CHECK_IF_WITHIN_PARENT_BOUNDS(scope) ECASSERT(scope->_parent ? scope->_location >= scope->_parent->_location && scope->_location + scope->_length <= scope->_parent->_location + scope->_parent->_length : YES);

- (void)shiftByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange
{
    ECASSERT(oldRange.location == newRange.location);
    ECASSERT(!_parent);
        
    // First of all remove all the child scopes in the old range.
    [self removeChildScopesInRange:oldRange];
    
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
                CHECK_IF_WITHIN_PARENT_BOUNDS(scope);
                continue;
            }
            else if (scopeRange.location >= oldRangeEnd)
            {
                // If the scope is past the affected range, shift the location
                scope->_location += offset;
                CHECK_IF_WITHIN_PARENT_BOUNDS(scope);
            }
            else
            {
                // The scope overlaps the affected range, adjust the length
                scope->_length += offset;
                CHECK_IF_WITHIN_PARENT_BOUNDS(scope);
            }
            
            // Recurse over the scope's children
            if (scope->_children.count)
            {
                [scopeEnumeratorStack addObject:scope->_children.objectEnumerator];
            }
        }
        [scopeEnumeratorStack removeLastObject];
    }    
}

- (void)removeChildScopesInRange:(NSRange)range
{
    ECASSERT(!_parent);
        
    NSMutableArray *childScopeIndexStack = [[NSMutableArray alloc] init];
    TMScope *scope = self;
    NSUInteger rangeEnd = NSMaxRange(range);
    NSUInteger childScopeIndex = 0;
    for (;;)
    {
        if (childScopeIndex + 1 <= scope->_children.count)
        {
            BOOL recurse = NO;
            TMScope *childScope = [scope->_children objectAtIndex:childScopeIndex];
            ECASSERT(childScope->_type == TMScopeTypeMatch || childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent || childScope->_type == TMScopeTypeBegin || childScope->_type == TMScopeTypeEnd);
            NSRange childScopeRange = NSMakeRange(childScope->_location, childScope->_length);
            NSUInteger childScopeEnd = NSMaxRange(childScopeRange);
            if (childScopeRange.location < range.location && childScopeEnd <= range.location)
            {
                // If the child scope is before the affected range, continue to the next scope
                ++childScopeIndex;
                CHECK_IF_WITHIN_PARENT_BOUNDS(childScope);
                continue;
            }
            else if (childScopeRange.location >= rangeEnd)
            {
                // The child scope and all the others that follow start after the end of the range, we can break out
                // Nothing to do here, we'll break out after the if chain finishes
                CHECK_IF_WITHIN_PARENT_BOUNDS(childScope);
            }
            else if ((range.location <= childScopeRange.location && rangeEnd >= childScopeEnd) || childScope->_type == TMScopeTypeMatch || childScope->_type == TMScopeTypeBegin || childScope->_type == TMScopeTypeEnd)
            {
                // If the child scope is completely contained in the range, or it's a match scope and it overlaps since it didn't match the previous two cases
                if (_delegateFlags.willRemoveScope)
                    [_delegate scope:self willRemoveScope:childScope];
                [scope->_children removeObjectAtIndex:childScopeIndex];
                if (childScope->_type == TMScopeTypeContent)
                    scope->_flags &= ~TMScopeHasContentScope;
                continue;
            }
            else if (childScopeRange.location >= range.location)
            {
                // If the span child scope isn't contained in the range, but it's start is, clip off it's head, then recurse
                ECASSERT(childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent);
                ECASSERT(rangeEnd > childScopeRange.location && childScopeRange.length >= rangeEnd - childScopeRange.location);
                if (childScope->_type & TMScopeTypeSpan)
                {
                    if (childScope->_flags & TMScopeHasBeginScope)
                    {
                        if (_delegateFlags.willRemoveScope)
                            [_delegate scope:self willRemoveScope:[childScope->_children objectAtIndex:0]];
                        [childScope->_children removeObjectAtIndex:0];
                        childScope->_flags &= ~TMScopeHasBeginScope;
                    }
                    childScope->_flags &= ~TMScopeHasBegin;
                }
                childScope->_length -= rangeEnd - childScopeRange.location;
                childScope->_location = rangeEnd;
                recurse = YES;
                CHECK_IF_WITHIN_PARENT_BOUNDS(childScope);
            }
            else if (childScopeEnd <= rangeEnd)
            {
                // If the span child scope isn't contained in the range, but it's end is, clip off it's tail, then recurse
                ECASSERT(childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent);
                ECASSERT(childScopeEnd >= range.location && childScopeRange.length >= childScopeEnd - range.location);
                if (childScope->_type & TMScopeTypeSpan)
                {
                    if (childScope->_flags & TMScopeHasEndScope)
                    {
                        if (_delegateFlags.willRemoveScope)
                            [_delegate scope:self willRemoveScope:[childScope->_children lastObject]];
                        [childScope->_children removeLastObject];
                        childScope->_flags &= ~TMScopeHasEndScope;
                    }
                    childScope->_flags &= ~TMScopeHasEnd;
                }
                childScope->_length -= childScopeEnd - range.location;
                recurse = YES;
                CHECK_IF_WITHIN_PARENT_BOUNDS(childScope);
            }
            else
            {
                // If we got here, it should mean the range is strictly contained by the span child scope, just recurse
                ECASSERT(childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent);
                ECASSERT(childScopeRange.location < range.location && childScopeEnd > rangeEnd);
                if (childScope->_type & TMScopeTypeSpan)
                {
                    if (childScope->_flags & TMScopeHasBeginScope)
                    {
                        TMScope *beginScope = [childScope->_children objectAtIndex:0];
                        if (range.location < beginScope->_location + beginScope->_length)
                        {
                            if (_delegateFlags.willRemoveScope)
                                [_delegate scope:self willRemoveScope:beginScope];
                            [childScope->_children removeObjectAtIndex:0];
                            childScope->_flags &= ~TMScopeHasBeginScope;
                            childScope->_flags &= ~TMScopeHasBegin;
                        }
                    }
                    if (childScope->_flags & TMScopeHasEndScope)
                    {
                        TMScope *endScope = [childScope->_children lastObject];
                        if (NSMaxRange(range) > endScope->_location)
                        {
                            if (_delegateFlags.willRemoveScope)
                                [_delegate scope:self willRemoveScope:endScope];
                            [childScope->_children removeLastObject];
                            childScope->_flags &= ~TMScopeHasEndScope;
                            childScope->_flags &= ~TMScopeHasEnd;
                        }
                    }
                }
                recurse = YES;
                CHECK_IF_WITHIN_PARENT_BOUNDS(childScope);
            }
            
            // Recurse on the child scope's children if needed
            if (recurse)
            {
                ECASSERT(childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent);
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
        ECASSERT(scope);
    }
}

- (BOOL)attemptMergeAtOffset:(NSUInteger)offset
{
    ECASSERT(!_parent);
    if (offset >= _length)
        return NO;
    // We're looking for two scopes to merge, one ending at offset, one starting at offset
    TMScope *head = nil;
    TMScope *tail = nil;
    NSMutableArray *scopeStack = [NSMutableArray arrayWithObject:self];
    for (;;)
    {
        BOOL recurse = NO;
        for (TMScope *childScope in ((TMScope *)scopeStack.lastObject)->_children)
        {
            NSRange childScopeRange = NSMakeRange(childScope->_location, childScope->_length);
            if (childScopeRange.location > offset)
            {
                // We're past the offset, break out
                break;
            }
            NSUInteger childScopeEnd = NSMaxRange(childScopeRange);
            if (childScopeEnd < offset)
            {
                // We're before the offset, continue to the next scope
            }
            else if (childScopeRange.location < offset && childScopeEnd > offset)
            {
                // We're containing the offset, recurse
                [scopeStack addObject:childScope];
                recurse = YES;
                break;
            }
            else if (childScopeEnd == offset)
            {
                // We're a possible head scope
                head = childScope;                
            }
            else if (childScopeRange.location == offset)
            {
                // We're a possible tail scope
                tail = childScope;
                if (head && head->_type == TMScopeTypeSpan && head->_type == tail->_type && [head.identifier isEqualToString:tail.identifier] && !head->_flags & TMScopeHasEnd && !tail->_flags & TMScopeHasBegin)
                {
                    // Confirmed the scopes match
                    break;
                }
                else
                {
                    head = nil;
                    tail = nil;
                }
            }
        }
        // If head and tail aren't both set, reset them both so we don't match up head and tail in different scopes
        if ((head && !tail) || (!head && tail))
        {
            head = nil;
            tail = nil;
        }
        if (!recurse)
            break;
    }
    
    if (!head)
        return NO;
    
    ECASSERT(head && tail && head->_type == TMScopeTypeSpan && tail->_type == TMScopeTypeSpan && head->_parent && head->_parent == tail->_parent && [head.identifier isEqualToString:tail.identifier]);
    ECASSERT(head->_location + head->_length == tail->_location);
    
    [head->_children addObjectsFromArray:tail->_children];
    [head->_parent->_children removeObject:tail];
    
    return YES;
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
    if (!_children.count)
        return;
    
    // 0 length scopes should not exist in a consistent tree
    ECASSERT(_length);
    
    // Scope must have a valid type
    ECASSERT(_type == TMScopeTypeRoot || _type == TMScopeTypeMatch || _type == TMScopeTypeCapture || _type == TMScopeTypeSpan || _type == TMScopeTypeBegin || _type == TMScopeTypeEnd || _type == TMScopeTypeContent);
    
    // If the scope isn't a root scope, it must have a parent scope. Additionally some types can only be children of others.
    ECASSERT(_type == TMScopeTypeRoot || _parent);
    ECASSERT(_type != TMScopeTypeContent || _parent->_type == TMScopeTypeSpan);
    ECASSERT(_type != TMScopeTypeCapture || _parent->_type == TMScopeTypeMatch || _parent->_type == TMScopeTypeBegin || _parent->_type == TMScopeTypeEnd);
    ECASSERT(_type != TMScopeTypeBegin || _parent->_type == TMScopeTypeSpan);
    ECASSERT(_type != TMScopeTypeEnd || _parent->_type == TMScopeTypeSpan);
    
    if (_type == TMScopeTypeSpan)
    {
        ECASSERT(_flags & TMScopeHasBegin);
        if (_flags & TMScopeHasBeginScope)
        {
            TMScope *beginScope = [_children objectAtIndex:0];
            ECASSERT(beginScope->_type == TMScopeTypeBegin);
        }
        if (_flags & TMScopeHasEndScope)
        {
            TMScope *endScope = [_children lastObject];
            ECASSERT(endScope->_type == TMScopeTypeEnd);
        }
        if (_flags & TMScopeHasContentScope)
        {
            TMScope *contentScope = [_children objectAtIndex:_flags & TMScopeHasBeginScope ? 1 : 0];
            ECASSERT(contentScope->_type == TMScopeTypeContent);
        }
    }
    
    // Children must be sorted, must not overlap, and must not extend beyond the parent's range, and must have non-zero length (this gets rechecked on recursion, but that's ok)
    NSUInteger scopeEnd = _location + _length;
    NSUInteger previousChildLocation = NSUIntegerMax;
    NSUInteger previousChildEnd = NSUIntegerMax;
    BOOL isFirstChild = YES;
    for (TMScope *childScope in _children)
    {
        ECASSERT(childScope->_length);
        ECASSERT(childScope->_location >= _location && childScope->_location + childScope->_length <= scopeEnd);
        if (!isFirstChild)
        {
            ECASSERT(previousChildLocation < childScope->_location);
            ECASSERT(previousChildEnd <= childScope->_location);
        }
        else
        {
            isFirstChild = NO;
        }
        previousChildLocation = childScope->_location;
        previousChildEnd = childScope->_location + childScope->_length;
        [childScope _checkConsistency];
    }
}

#endif

@end
