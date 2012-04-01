//
//  WeakDictionary.m
//  Foundation
//
//  Created by Uri Baghin on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "WeakDictionary.h"
#import "WeakObjectWrapper.h"

@interface WeakDictionary ()
{
  NSMutableDictionary *_contents;
}
- (void)_purge;
@end

@implementation WeakDictionary

#pragma mark - NSDictionary

- (NSUInteger)count
{
  ASSERT(_contents);
  [self _purge];
  return [_contents count];
}

- (id)objectForKey:(id)key
{
  ASSERT(_contents);
  WeakObjectWrapper *wrapper = [_contents objectForKey:key];
  if (!wrapper)
    return nil;
  if (!wrapper->object)
  {
    [_contents removeObjectForKey:key];
    return nil;
  }
  return wrapper->object;
}

- (NSEnumerator *)keyEnumerator
{
  ASSERT(_contents);
  [self _purge];
  return [_contents keyEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
  ASSERT(_contents);
  [self _purge];
  return [_contents countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - NSMutableDictionary

- (id)init
{
  return [self initWithCapacity:1];
}

- (id)initWithCapacity:(NSUInteger)numItems
{
  self = [super init];
  if (!self)
    return nil;
  _contents = [NSMutableDictionary dictionaryWithCapacity:numItems];
  ASSERT(_contents);
  return self;
}

- (void)setObject:(id)object forKey:(id)key
{
  ASSERT(_contents && object);
  [_contents setObject:[WeakObjectWrapper wrapperWithObject:object] forKey:key];
}

- (void)removeObjectForKey:(id)key
{
  ASSERT(_contents);
  [_contents removeObjectForKey:key];
}

#pragma mark - Private Methods

- (void)_purge
{
  ASSERT(_contents);
  [_contents removeObjectsForKeys:[[_contents keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
    if (((WeakObjectWrapper *)[_contents objectForKey:key])->object)
      return NO;
    return YES;
  }] allObjects]];
}

@end
