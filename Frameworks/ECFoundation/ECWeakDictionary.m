//
//  ECWeakDictionary.m
//  ECFoundation
//
//  Created by Uri Baghin on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECWeakDictionary.h"

@interface WeakObjectWrapper : NSObject
{
    @package
    __weak id object;
}
+ (WeakObjectWrapper *)wrapperWithObject:(id)object;
@end

@implementation WeakObjectWrapper

+ (WeakObjectWrapper *)wrapperWithObject:(id)object
{
    WeakObjectWrapper *wrapper = [[self alloc] init];
    wrapper->object = object;
    return wrapper;
}

@end

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
    [self _purge];
    return [_contents count];
}

- (id)objectForKey:(id)key
{
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
    [self _purge];
    return [_contents keyEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    [self _purge];
    return [_contents countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - NSMutableDictionary

- (id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (!self)
        return nil;
    _contents = [NSMutableDictionary dictionaryWithCapacity:numItems];
    return self;
}

- (void)setObject:(id)object forKey:(id)key
{
    [_contents setObject:[WeakObjectWrapper wrapperWithObject:object] forKey:key];
}

- (void)removeObjectForKey:(id)key
{
    [_contents removeObjectForKey:key];
}

#pragma mark - Private Methods

- (void)_purge
{
    [_contents removeObjectsForKeys:[[_contents keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        if (((WeakObjectWrapper *)[_contents objectForKey:key])->object)
            return NO;
        return YES;
    }] allObjects]];
}

@end
