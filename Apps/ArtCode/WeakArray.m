//
//  WeakArray.m
//  ArtCode
//
//  Created by Uri Baghin on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeakArray.h"
#import "WeakObjectWrapper.h"

@interface WeakArray ()
{
  NSMutableArray *_contents;
}
- (void)_purge;
@end

@implementation WeakArray

#pragma mark - NSArray

- (id)init
{
  self = [super init];
  if (!self)
    return nil;
  _contents = [[NSMutableArray alloc] init];
  return self;
}

- (NSUInteger)count
{
  ASSERT(_contents);
  return [_contents count];
}

- (id)objectAtIndex:(NSUInteger)index
{
  ASSERT(_contents);
  WeakObjectWrapper *wrapper = [_contents objectAtIndex:index];
  if (!wrapper)
    return nil;
  return wrapper->object;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
  ASSERT(_contents);
  [self _purge];
  return [_contents countByEnumeratingWithState:state objects:buffer count:len];
}

- (id)copyWithZone:(NSZone *)zone
{
  ASSERT(_contents);
  [self _purge];
  NSMutableArray *copy = [[NSMutableArray alloc] init];
  for (WeakObjectWrapper *wrapper in _contents)
    [copy addObject:wrapper->object];
  return [copy copy];
}

#pragma mark - NSMutableArray

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
  ASSERT(_contents && anObject);
  [_contents insertObject:[WeakObjectWrapper wrapperWithObject:anObject] atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
  ASSERT(_contents);
  [_contents removeObjectAtIndex:index];
}

- (void)addObject:(id)anObject
{
  ASSERT(_contents && anObject);
  [_contents addObject:[WeakObjectWrapper wrapperWithObject:anObject]];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
  ASSERT(_contents && anObject);
  ((WeakObjectWrapper *)[_contents objectAtIndex:index])->object = anObject;
}

#pragma mark - Private methods

- (void)_purge
{
  ASSERT(_contents);
  NSIndexSet *indexes = [_contents indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
    if (((WeakObjectWrapper *)obj)->object)
      return NO;
    return YES;
  }];
  [_contents removeObjectsAtIndexes:indexes];
}

@end
