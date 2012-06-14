//
//  CodeScope.m
//  CodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMScope+Internal.h"
#import "TMPreference.h"

@interface TMScope ()
- (id)_initWithParent:(TMScope *)parent identifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode type:(TMScopeType)type content:(NSString *)content;
- (void)_loadSymbolListProperties;
@end

#pragma mark -

@implementation TMScope {
  NSRange _identifierRange;
  NSMutableArray *_children;
  NSString *_content;
  NSNumber *_indentation;
  NSNumber *_separator;
}

#pragma mark - Properties

@synthesize syntaxNode = _syntaxNode, endRegexp = _endRegexp, location = _location, length = _length, flags = _flags, parent = _parent, qualifiedIdentifier = _qualifiedIdentifier, identifiersStack = _identifiersStack, type = _type, title = _title, icon = _icon;

- (NSString *)identifier
{
  if (!_identifierRange.length)
    return nil;
  return [_qualifiedIdentifier substringWithRange:_identifierRange];
}

- (NSString *)spelling {
  return [_content substringWithRange:NSMakeRange(_location, _length)];
}

- (NSString *)title {
  if (!_title) {
    [self _loadSymbolListProperties];
  }
  return _title;
}

- (UIImage *)icon {
  if (!_icon) {
    [self _loadSymbolListProperties];
  }
  return _icon;
}

- (NSUInteger)indentation {
  if (!_indentation) {
    [self _loadSymbolListProperties];
  }
  return [_indentation unsignedIntegerValue];
}

- (BOOL)isSeparator {
  if (!_separator) {
    [self _loadSymbolListProperties];
  }
  return [_separator boolValue];
}

- (NSArray *)children
{
  return [_children copy];
}

+ (NSSet *)keyPathsForValuesAffectingQualifiedIdentifier
{
  return [NSSet setWithObject:@"identifier"];
}

- (id)_initWithParent:(TMScope *)parent identifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode type:(TMScopeType)type content:(NSString *)content
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
  _content = content;
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
  TMScope *childScope = [[[self class] alloc] _initWithParent:self identifier:identifier syntaxNode:syntaxNode type:type content:_content];
  childScope->_location = location;
  childScope->_parent = self;
  if (!_children)
    _children = [NSMutableArray new];
  NSUInteger childInsertionIndex = [_children indexOfObject:childScope inSortedRange:NSMakeRange(0, [_children count]) options:NSBinarySearchingInsertionIndex usingComparator:scopeComparator];
  if (childInsertionIndex == [_children count])
    [_children addObject:childScope];
  else
    [_children insertObject:childScope atIndex:childInsertionIndex];
  
  return childScope;
}

+ (TMScope *)newRootScopeWithIdentifier:(NSString *)identifier syntaxNode:(TMSyntaxNode *)syntaxNode content:(NSString *)content
{
  ASSERT(identifier && syntaxNode && content);
  return [[self alloc] _initWithParent:nil identifier:identifier syntaxNode:syntaxNode type:TMScopeTypeRoot content:content];
}

- (void)removeFromParent
{
  ASSERT(_parent && _parent->_children && [_parent->_children containsObject:self]);
  // We're only using it on span and content type scopes at the moment
  ASSERT(_type == TMScopeTypeContent || _type == TMScopeTypeSpan);
  if (_type == TMScopeTypeContent)
    _parent->_flags &= ~TMScopeHasContentScope;
  [_parent->_children removeObject:self];
}

#pragma mark - Scope Tree Querying

- (NSMutableArray *)scopeStackAtOffset:(NSUInteger)offset options:(TMScopeQueryOptions)options
{
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
      if ((childScopeLocation < offset && childScopeEnd > offset)
          || (childScopeLocation == offset && options & TMScopeQueryRight && (!(options & TMScopeQueryOpenOnly) || !(childScope->_flags & TMScopeHasBegin))))
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
      if ((childScopeLocation < offset && childScopeEnd > offset)
          || (childScopeEnd == offset && options & TMScopeQueryLeft && (!(options & TMScopeQueryOpenOnly) || !(childScope->_flags & TMScopeHasEnd))))
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

- (void)shiftByReplacingRange:(NSRange)oldRange withRange:(NSRange)newRange
{
  ASSERT(oldRange.location == newRange.location);
  ASSERT(!_parent);
  
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
  ASSERT(!_parent);
  
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
  // We're looking for two scopes to merge, one ending at offset, one starting at offset
  TMScope *head = nil;
  TMScope *tail = nil;
  BOOL scopesMatch = NO;
  BOOL treeIsBroken = NO;
  NSArray *leftScopeStack = [self scopeStackAtOffset:offset options:TMScopeQueryLeft | TMScopeQueryOpenOnly];
  NSArray *rightScopeStack = [self scopeStackAtOffset:offset options:TMScopeQueryRight | TMScopeQueryOpenOnly];
  
  NSUInteger maxDepth = MIN(leftScopeStack.count, rightScopeStack.count);
  
  for (NSUInteger depth = 0; depth < maxDepth; ++depth)
  {
    head = [leftScopeStack objectAtIndex:depth];
    tail = [rightScopeStack objectAtIndex:depth];
    if (head == tail)
      continue;
    if (head && head->_type == TMScopeTypeSpan && head->_type == tail->_type && [head.identifier isEqualToString:tail.identifier] && !(head->_flags & TMScopeHasEnd) && !(tail->_flags & TMScopeHasBegin))
    {
      scopesMatch = YES;
      treeIsBroken = YES;
      break;
    }
    treeIsBroken = YES;
  }
  
  if (!treeIsBroken)
    return YES;
  
  if (!scopesMatch)
    return NO;
  
  ASSERT(head && tail && head->_type == TMScopeTypeSpan && tail->_type == TMScopeTypeSpan && head->_parent && head->_parent == tail->_parent && [head.identifier isEqualToString:tail.identifier]);
  ASSERT(head->_location + head->_length == tail->_location);
  
  [head->_children addObjectsFromArray:tail->_children];
  [head->_parent->_children removeObject:tail];
  
  return YES;
}

#pragma mark - Private Methods

- (void)_loadSymbolListProperties {
  // Transform
  NSString *(^transformation)(NSString *) = ((NSString *(^)(NSString *))[TMPreference preferenceValueForKey:TMPreferenceSymbolTransformationKey qualifiedIdentifier:self.qualifiedIdentifier]);
  _title = transformation ? transformation(self.spelling) : self.spelling;
  // TODO add preference for icon
  NSUInteger titleLength = [_title length];
  NSUInteger indentation = 0;
  for (; indentation < titleLength; ++indentation)
  {
    if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[_title characterAtIndex:indentation]])
      break;
  }
  _title = indentation ? [_title substringFromIndex:indentation] : _title;
  _indentation = [NSNumber numberWithUnsignedInteger:indentation];
}

#pragma mark - Debug Methods

#if DEBUG

- (void)_checkConsistency
{
  if (!_children.count)
    return;
  
  // 0 length scopes should not exist in a consistent tree
  ASSERT(_length);
  
  // Scope must have a valid type
  ASSERT(_type == TMScopeTypeRoot || _type == TMScopeTypeMatch || _type == TMScopeTypeCapture || _type == TMScopeTypeSpan || _type == TMScopeTypeBegin || _type == TMScopeTypeEnd || _type == TMScopeTypeContent);
  
  // If the scope isn't a root scope, it must have a parent scope. Additionally some types can only be children of others.
  ASSERT(_type == TMScopeTypeRoot || _parent);
  ASSERT(_type != TMScopeTypeContent || _parent->_type == TMScopeTypeSpan);
  ASSERT(_type != TMScopeTypeCapture || _parent->_type == TMScopeTypeMatch || _parent->_type == TMScopeTypeBegin || _parent->_type == TMScopeTypeEnd);
  ASSERT(_type != TMScopeTypeBegin || _parent->_type == TMScopeTypeSpan);
  ASSERT(_type != TMScopeTypeEnd || _parent->_type == TMScopeTypeSpan);
  
  if (_type == TMScopeTypeSpan)
  {
    ASSERT(_flags & TMScopeHasBegin);
    if (_flags & TMScopeHasBeginScope)
    {
      TMScope *beginScope = [_children objectAtIndex:0];
      ASSERT(beginScope->_type == TMScopeTypeBegin);
    }
    if (_flags & TMScopeHasEndScope)
    {
      TMScope *endScope = [_children lastObject];
      ASSERT(endScope->_type == TMScopeTypeEnd);
    }
    if (_flags & TMScopeHasContentScope)
    {
      TMScope *contentScope = [_children objectAtIndex:_flags & TMScopeHasBeginScope ? 1 : 0];
      ASSERT(contentScope->_type == TMScopeTypeContent);
    }
  }
  
  // Children must be sorted, must not overlap, and must not extend beyond the parent's range, and must have non-zero length (this gets rechecked on recursion, but that's ok)
  NSUInteger scopeEnd = _location + _length;
  NSUInteger previousChildLocation = NSUIntegerMax;
  NSUInteger previousChildEnd = NSUIntegerMax;
  BOOL isFirstChild = YES;
  for (TMScope *childScope in _children)
  {
    ASSERT(childScope->_length);
    ASSERT(childScope->_location >= _location && childScope->_location + childScope->_length <= scopeEnd);
    if (!isFirstChild)
    {
      ASSERT(previousChildLocation < childScope->_location);
      ASSERT(previousChildEnd <= childScope->_location);
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
