//
//  ECWeakDictionary.m
//  ECFoundation
//
//  Created by Uri Baghin on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECWeakDictionary.h"
#import "WeakObjectWrapper.h"

@interface ECWeakDictionary ()
{
    NSMutableDictionary *_contents;
}
- (void)_purge;
@end

@implementation ECWeakDictionary

#pragma mark - NSDictionary

- (NSUInteger)count
{
    ECASSERT(_contents);
    [self _purge];
    return [_contents count];
}

- (id)objectForKey:(id)key
{
    ECASSERT(_contents);
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
    ECASSERT(_contents);
    [self _purge];
    return [_contents keyEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    ECASSERT(_contents);
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
    ECASSERT(_contents);
    return self;
}

- (void)setObject:(id)object forKey:(id)key
{
    ECASSERT(_contents && object);
    [_contents setObject:[WeakObjectWrapper wrapperWithObject:object] forKey:key];
}

- (void)removeObjectForKey:(id)key
{
    ECASSERT(_contents);
    [_contents removeObjectForKey:key];
}

#pragma mark - Private Methods

- (void)_purge
{
    ECASSERT(_contents);
    [_contents removeObjectsForKeys:[[_contents keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        if (((WeakObjectWrapper *)[_contents objectForKey:key])->object)
            return NO;
        return YES;
    }] allObjects]];
}

@end
