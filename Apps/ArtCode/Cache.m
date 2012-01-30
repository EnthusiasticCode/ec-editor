//
//  Cache.m
//  Foundation
//
//  Created by Uri Baghin on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Cache.h"
#import "WeakDictionary.h"

@interface Cache ()
{
    NSCache *_cache;
    WeakDictionary *_dictionary;
}
@end

@implementation Cache

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _cache = [[NSCache alloc] init];
    _dictionary = [WeakDictionary dictionary];
    return self;
}

#pragma mark - NSCache

- (NSString *)name
{
    return [_cache name];
}

- (void)setName:(NSString *)n
{
    [_cache setName:n];
}

- (id)objectForKey:(id)key
{
    id object = [_dictionary objectForKey:key];
    ECASSERT(object || ![_cache objectForKey:key]);
    if (!object)
        return nil;
    [_cache setObject:object forKey:key];
    return object;
}

- (void)setObject:(id)obj forKey:(id)key
{
    [_cache setObject:obj forKey:key];
    [_dictionary setObject:obj forKey:key];
}

- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g
{
    [_cache setObject:obj forKey:key cost:g];
    [_dictionary setObject:obj forKey:key];
}

- (void)removeObjectForKey:(id)key
{
    [_cache removeObjectForKey:key];
    [_dictionary removeObjectForKey:key];
}

- (void)removeAllObjects
{
    [_cache removeAllObjects];
    [_dictionary removeAllObjects];
}

- (NSUInteger)countLimit
{
    return [_cache countLimit];
}

- (void)setCountLimit:(NSUInteger)lim
{
    [_cache setCountLimit:lim];
}

- (NSUInteger)totalCostLimit
{
    return [_cache totalCostLimit];
}

- (void)setTotalCostLimit:(NSUInteger)lim
{
    [_cache setTotalCostLimit:lim];
}

- (BOOL)evictsObjectsWithDiscardedContent
{
    return [_cache evictsObjectsWithDiscardedContent];
}

- (void)setEvictsObjectsWithDiscardedContent:(BOOL)b
{
    [_cache setEvictsObjectsWithDiscardedContent:b];
}

- (id<NSCacheDelegate>)delegate
{
    return [_cache delegate];
}

- (void)setDelegate:(id<NSCacheDelegate>)d
{
    [_cache setDelegate:d];
}

#pragma mark - NSDictionary

- (NSUInteger)count
{
    return [_dictionary count];
}

- (NSEnumerator *)keyEnumerator
{
    return [_dictionary keyEnumerator];
}

- (NSEnumerator *)objectEnumerator
{
    return [_dictionary objectEnumerator];
}

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
    [_dictionary enumerateKeysAndObjectsUsingBlock:block];
}

- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)opts usingBlock:(void (^)(id key, id obj, BOOL *stop))block
{
    [_dictionary enumerateKeysAndObjectsWithOptions:opts usingBlock:block];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    return [_dictionary countByEnumeratingWithState:state objects:buffer count:len];
}

@end
