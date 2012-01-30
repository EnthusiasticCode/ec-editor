//
//  DiscardableMutableDictionary.m
//  Foundation
//
//  Created by Uri Baghin on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DiscardableMutableDictionary.h"

@interface DiscardableMutableDictionary ()
{
    NSMutableDictionary *_dictionary;
    NSCache *_cache;
}
@end

@implementation DiscardableMutableDictionary

#pragma mark - NSDictionary

- (NSUInteger)count
{
    ECASSERT(_dictionary && _cache);
    return [_dictionary count];
}

- (id)objectForKey:(id)key
{
    ECASSERT(_dictionary && _cache);
    id object = [_dictionary objectForKey:key];
    if (!object)
        return nil;
    [_cache setObject:object forKey:key];
    return object;
}

- (NSEnumerator *)keyEnumerator
{
    ECASSERT(_dictionary && _cache);
    return [_dictionary keyEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    ECASSERT(_dictionary && _cache);
    return [_dictionary countByEnumeratingWithState:state objects:buffer count:len];
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
    _dictionary = [NSMutableDictionary dictionaryWithCapacity:numItems];
    _cache = [[NSCache alloc] init];
    ECASSERT(_dictionary && _cache);
    return self;
}

- (void)setObject:(id)object forKey:(id)key
{
    ECASSERT(_dictionary && _cache);
    [_dictionary setObject:object forKey:key];
    [_cache setObject:object forKey:key];
}

- (void)removeObjectForKey:(id)key
{
    ECASSERT(_dictionary && _cache);
    [_dictionary removeObjectForKey:key];
    [_cache removeObjectForKey:key];
}

@end
