//
//  CodeScope.m
//  CodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMScope+Internal.h"
#import "TMPreference.h"
#import "TMSymbol.h"


@interface TMScope ()
- (id)_initWithParent:(TMScope *)parent identifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode type:(TMScopeType)type;
@end

#pragma mark -

@implementation TMScope {
  NSRange _identifierRange;
  NSMutableArray *_children;
  TMSymbol *_symbol;
}

#pragma mark - Properties

@synthesize syntaxNode = _syntaxNode, endRegexp = _endRegexp, location = _location, length = _length, flags = _flags, parent = _parent, qualifiedIdentifier = _qualifiedIdentifier, identifiersStack = _identifiersStack, content = _content, type = _type;

- (NSString *)identifier
{
  if (!_identifierRange.length)
    return nil;
  return [_qualifiedIdentifier substringWithRange:_identifierRange];
}

- (NSString *)spelling {
  return [self.content substringWithRange:NSMakeRange(_location, _length)];
}

- (NSString *)content {
  if (self.parent) {
    return self.parent.content;
  }
  return _content;
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

- (NSString *)description
{
  return [[super description] stringByAppendingString:self.qualifiedIdentifier];
}

#pragma mark - Initializers

static NSComparisonResult(^scopeComparator)(TMScope *, TMScope *) = ^NSComparisonResult(TMScope *first, TMScope *second){
  if (first.location < second.location)
    return NSOrderedAscending;
  else if (first.location > second.location)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
};

- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode location:(NSUInteger)location type:(TMScopeType)type
{
  ASSERT(!identifier || [identifier isKindOfClass:[NSString class]]);
  TMScope *childScope = [[[self class] alloc] _initWithParent:self identifier:identifier syntaxNode:syntaxNode type:type];
  childScope->_location = location;
  childScope->_parent = self;
  if (!_children)
    _children = [NSMutableArray new];
  NSUInteger childInsertionIndex = [_children indexOfObject:childScope inSortedRange:NSMakeRange(0, [_children count]) options:NSBinarySearchingInsertionIndex | NSBinarySearchingLastEqual usingComparator:scopeComparator];
  if (childInsertionIndex == [_children count])
    [_children addObject:childScope];
  else
    [_children insertObject:childScope atIndex:childInsertionIndex];
  
  return childScope;
}

+ (TMScope *)newRootScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode
{
  ASSERT(identifier && syntaxNode);
  return [[self alloc] _initWithParent:nil identifier:identifier syntaxNode:syntaxNode type:TMScopeTypeRoot];
}

- (void)removeFromParent
{
  ASSERT(_parent && _parent->_children && [_parent->_children containsObject:self]);
  if (_type == TMScopeTypeContent)
    _parent->_flags &= ~TMScopeHasContentScope;
  [_parent->_children removeObject:self];
}

#pragma mark - Scope Tree Querying

- (NSMutableArray *)scopeStackAtOffset:(NSUInteger)offset options:(TMScopeQueryOptions)options
{
  ASSERT((options & TMScopeQueryLeft) || (options & TMScopeQueryRight));
  ASSERT(!_parent);
  if (offset > _length)
    return nil;
  NSMutableArray *scopeStack = [NSMutableArray arrayWithObject:self];
  for (;;)
  {
    TMScope *scope = [scopeStack lastObject];
    if (!scope->_children || !scope->_children.count)
      break;
    NSRange childrenRange = NSMakeRange(0, scope->_children.count);
    TMScope *sentinel = [[TMScope alloc] init];
    sentinel->_location = offset;
    NSUInteger insertionIndex = [scope->_children indexOfObject:sentinel inSortedRange:childrenRange options:NSBinarySearchingInsertionIndex | NSBinarySearchingFirstEqual usingComparator:scopeComparator];
    ASSERT(insertionIndex != NSNotFound);
    
    if (insertionIndex < childrenRange.length)
    {
      TMScope *childScope = [scope->_children objectAtIndex:insertionIndex];
      NSUInteger childScopeLocation = childScope->_location;
      NSUInteger childScopeEnd = childScope->_location + childScope->_length;
      BOOL scopePassesQueryOpenOnly = !(options & TMScopeQueryOpenOnly) || ((childScope->_type == TMScopeTypeSpan ) && !(childScope->_flags & TMScopeHasBegin));
      if ((childScopeLocation < offset && childScopeEnd > offset)
          || (childScopeLocation == offset && options & TMScopeQueryRight && scopePassesQueryOpenOnly)
          // Very special case for 0 length tailless scopes (it can happen when a content scope is created at the end of a line)
          || (childScopeLocation == offset && childScopeEnd == offset && scopePassesQueryOpenOnly))
      {
        [scopeStack addObject:childScope];
        continue;
      }
    }
    if (insertionIndex > 0)
    {
      TMScope *childScope = [scope->_children objectAtIndex:insertionIndex - 1];
      NSUInteger childScopeLocation = childScope->_location;
      NSUInteger childScopeEnd = childScope->_location + childScope->_length;
      BOOL scopePassesQueryOpenOnly = !(options & TMScopeQueryOpenOnly) || ((childScope->_type == TMScopeTypeSpan ) && !(childScope->_flags & TMScopeHasEnd));
      if ((childScopeLocation < offset && childScopeEnd > offset)
          || (childScopeEnd == offset && options & TMScopeQueryLeft && scopePassesQueryOpenOnly))
      {
        [scopeStack addObject:childScope];
        continue;
      }
    }
    // We didn't find a matching child scope, break out
    break;
  }
  return scopeStack;
}

#pragma mark - Scope Tree Changes

#define CHECK_IF_WITHIN_PARENT_BOUNDS(scope) ASSERT(scope->_parent ? scope->_location >= scope->_parent->_location && scope->_location + scope->_length <= scope->_parent->_location + scope->_parent->_length : YES);

- (void)shiftByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange onRemove:(void(^)(TMScope *scope))block
{
  ASSERT(oldRange.location == newRange.location);
  ASSERT(!_parent);
  
  // First of all remove all the child scopes in the old range.
  [self removeChildScopesInRange:oldRange onRemove:block];
  
  // Adjust the root scope
  ASSERT(_length + newRange.length >= oldRange.length);
  _length = (_length + newRange.length) - oldRange.length;
  
  if (!_children) {
    return;
  }
  
  NSMutableArray *scopeEnumeratorStack = [NSMutableArray arrayWithObject:[_children objectEnumerator]];
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

- (void)removeChildScopesInRange:(NSRange)range onRemove:(void(^)(TMScope *))block
{
  ASSERT(!_parent);
  static void(^emptyBlock)(TMScope *) = ^(TMScope *scope){
  };
  block = block ?: emptyBlock;
  
  static void(^callBlockOnDescendantsOfScope)(void(^)(TMScope *), TMScope *) = ^(void(^calledBlock)(TMScope *), TMScope *scope){
    calledBlock(scope);
    if ([scope->_children count]){
      NSMutableArray *scopeEnumeratorStack = [NSMutableArray arrayWithObject:[scope->_children objectEnumerator]];
      while ([scopeEnumeratorStack count]) {
        while (scope = [[scopeEnumeratorStack lastObject] nextObject]) {
          calledBlock(scope);
          if (scope->_children.count) {
            [scopeEnumeratorStack addObject:[scope->_children objectEnumerator]];
          }
        }
        [scopeEnumeratorStack removeLastObject];
      }
    }
  };
  
  NSMutableArray *childScopeIndexStack = [[NSMutableArray alloc] init];
  TMScope *scope = self;
  NSUInteger rangeEnd = NSMaxRange(range);
  NSUInteger childScopeIndex = 0;
  for (;;)
  {
    if (childScopeIndex < scope->_children.count)
    {
      BOOL recurse = NO;
      TMScope *childScope = [scope->_children objectAtIndex:childScopeIndex];
      ASSERT(childScope->_type == TMScopeTypeMatch || childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent || childScope->_type == TMScopeTypeBegin || childScope->_type == TMScopeTypeEnd);
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
        callBlockOnDescendantsOfScope(block, childScope);
        [scope->_children removeObjectAtIndex:childScopeIndex];
        if (childScope->_type == TMScopeTypeContent)
          scope->_flags &= ~TMScopeHasContentScope;
        continue;
      }
      else if (childScopeRange.location >= range.location)
      {
        // If the span child scope isn't contained in the range, but it's start is, clip off it's head, then recurse
        ASSERT(childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent);
        ASSERT(rangeEnd > childScopeRange.location && childScopeRange.length >= rangeEnd - childScopeRange.location);
        if (childScope->_type & TMScopeTypeSpan)
        {
          if (childScope->_flags & TMScopeHasBeginScope)
          {
            callBlockOnDescendantsOfScope(block, [childScope->_children objectAtIndex:0]);
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
        ASSERT(childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent);
        ASSERT(childScopeEnd >= range.location && childScopeRange.length >= childScopeEnd - range.location);
        if (childScope->_type & TMScopeTypeSpan)
        {
          if (childScope->_flags & TMScopeHasEndScope)
          {
            callBlockOnDescendantsOfScope(block, [childScope->_children lastObject]);
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
        ASSERT(childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent);
        ASSERT(childScopeRange.location < range.location && childScopeEnd > rangeEnd);
        if (childScope->_type & TMScopeTypeSpan)
        {
          if (childScope->_flags & TMScopeHasBeginScope)
          {
            TMScope *beginScope = [childScope->_children objectAtIndex:0];
            if (range.location < beginScope->_location + beginScope->_length)
            {
              callBlockOnDescendantsOfScope(block, [childScope->_children objectAtIndex:0]);
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
              callBlockOnDescendantsOfScope(block, [childScope->_children lastObject]);
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
        ASSERT(childScope->_type == TMScopeTypeSpan || childScope->_type == TMScopeTypeContent);
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
    ASSERT(scope);
  }
}

- (BOOL)attemptMergeAtOffset:(NSUInteger)offset
{
  ASSERT(!_parent);
  if (offset >= _length)
    return NO;
  
  // We're looking for scopes to merge, one ending at offset, one starting at offset
  __block BOOL scopesMatch = YES;
  __block BOOL treeIsBroken = NO;
  NSArray *leftScopeStack = [self scopeStackAtOffset:offset options:TMScopeQueryLeft | TMScopeQueryOpenOnly];
  NSArray *rightScopeStack = [self scopeStackAtOffset:offset options:TMScopeQueryRight | TMScopeQueryOpenOnly];
  
  // If we have a different stack depth, they don't match up
  if (leftScopeStack.count != rightScopeStack.count) {
    return NO;
  }
  
  // Compare scopes at each depth to see if they all match
  [leftScopeStack enumerateObjectsUsingBlock:^(TMScope *head, NSUInteger depth, BOOL *stop) {
    TMScope *tail = [rightScopeStack objectAtIndex:depth];
    if (head == tail) {
      return;
    }
    treeIsBroken = YES;
    if (head->_type != TMScopeTypeSpan || head->_type != tail->_type || (head.identifier != tail.identifier && ![head.identifier isEqualToString:tail.identifier]) || (head->_flags & TMScopeHasEnd) || (tail->_flags & TMScopeHasBegin)) {
      scopesMatch = NO;
      *stop = YES;
      return;
    }
  }];
  
  // If the scopes at any depth don't match, fail the merge
  if (!scopesMatch) {
    return NO;
  }
  
  // If the tree is not broken, there is no need to merge
  if (!treeIsBroken) {
    // Check if the right scopes all have a begin, so they don't end up headless
    for (TMScope *rightScope in rightScopeStack) {
      if (rightScope->_type == TMScopeTypeSpan && !(rightScope->_flags & TMScopeHasBegin)) {
        return NO;
      }
    }
    return YES;
  }
  
  // Proceed to merge
  [leftScopeStack enumerateObjectsUsingBlock:^(TMScope *head, NSUInteger depth, BOOL *stop) {
    TMScope *tail = [rightScopeStack objectAtIndex:depth];
    if (head == tail) {
      return;
    }
    ASSERT(head && tail && head->_type == TMScopeTypeSpan && tail->_type == TMScopeTypeSpan && head->_parent == tail->_parent && (head.identifier == tail.identifier || [head.identifier isEqualToString:tail.identifier]));
    ASSERT(head->_location + head->_length == tail->_location);
    if (tail->_flags & TMScopeHasEnd) {
      head->_flags |= TMScopeHasEnd;
    }
    if (tail->_flags & TMScopeHasEndScope) {
      head->_flags |= TMScopeHasEndScope;
    }
    head.length = head.length + tail.length;
    [head->_children addObjectsFromArray:tail->_children];
    for (TMScope *tailChild in tail->_children) {
      tailChild->_parent = head;
    }
    [head->_parent->_children removeObject:tail];
  }];
  
  return YES;
}

- (TMSymbol *)symbol {
  if (!_symbol) {
    if (![TMPreference preferenceValueForKey:TMPreferenceShowInSymbolListKey qualifiedIdentifier:self.qualifiedIdentifier]) {
      _symbol = (id)[NSNull null];
      return nil;
    }
    _symbol = [[TMSymbol alloc] initWithScope:self];
  }
  return _symbol != (id)[NSNull null] ? _symbol : nil;
}

#pragma mark - Debug Methods

#if DEBUG

- (void)_checkConsistency
{
  if (!_children.count)
    return;
  
  // Scope must have a valid type
  ASSERT(_type == TMScopeTypeRoot || _type == TMScopeTypeMatch || _type == TMScopeTypeCapture || _type == TMScopeTypeSpan || _type == TMScopeTypeBegin || _type == TMScopeTypeEnd || _type == TMScopeTypeContent);
  
  // If the scope isn't a root scope, it must have a parent scope. Additionally some types can only be children of others.
  ASSERT(_type == TMScopeTypeRoot || _parent);
  ASSERT(_type != TMScopeTypeContent || _parent->_type == TMScopeTypeSpan);
  ASSERT(_type != TMScopeTypeCapture || _parent->_type == TMScopeTypeMatch || _parent->_type == TMScopeTypeBegin || _parent->_type == TMScopeTypeEnd);
  ASSERT(_type != TMScopeTypeBegin || _parent->_type == TMScopeTypeSpan);
  ASSERT(_type != TMScopeTypeEnd || _parent->_type == TMScopeTypeSpan);
  
  if (_type == TMScopeTypeSpan) {
    ASSERT(_flags & TMScopeHasBegin);
    if (_flags & TMScopeHasBeginScope) {
      TMScope *beginScope = [_children objectAtIndex:0];
      ASSERT(beginScope->_type == TMScopeTypeBegin);
    }
    if (_flags & TMScopeHasEndScope) {
      TMScope *endScope = [_children lastObject];
      ASSERT(endScope->_type == TMScopeTypeEnd);
    }
    if (_flags & TMScopeHasContentScope) {
      TMScope *contentScope = [_children objectAtIndex:_flags & TMScopeHasBeginScope ? 1 : 0];
      ASSERT(contentScope->_type == TMScopeTypeContent);
    }
  }
  
  // Children must be sorted, must not overlap, and must not extend beyond the parent's range
  NSUInteger scopeEnd = _location + _length;
  NSUInteger previousChildLocation = NSUIntegerMax;
  NSUInteger previousChildEnd = NSUIntegerMax;
  BOOL isFirstChild = YES;
  for (TMScope *childScope in _children) {
    ASSERT(childScope->_location >= _location && childScope->_location + childScope->_length <= scopeEnd);
    if (!isFirstChild) {
      ASSERT(previousChildLocation <= childScope->_location);
      ASSERT(previousChildEnd <= childScope->_location);
    } else {
      isFirstChild = NO;
    }
    previousChildLocation = childScope->_location;
    previousChildEnd = childScope->_location + childScope->_length;
    [childScope _checkConsistency];
  }
}

#endif

@end
