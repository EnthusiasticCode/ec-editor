//
//  ECDiscardableMutableDictionary.m
//  ECFoundation
//
//  Created by Uri Baghin on 11/2/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECDiscardableMutableDictionary.h"

@interface ECDiscardableMutableDictionary ()
{
    NSMutableDictionary *_dictionary;
    NSCache *_cache;
}
@end

@implementation ECDiscardableMutableDictionary

#pragma mark - NSDictionary

- (NSUInteger)count
{
    return [_dictionary count];
}

- (id)objectForKey:(id)key
{
    id object = [_dictionary objectForKey:key];
    if (!object)
        return nil;
    [_cache setObject:object forKey:key];
    return object;
}

- (NSEnumerator *)keyEnumerator
{
    return [_dictionary keyEnumerator];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    return [_dictionary countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - NSMutableDictionary

- (id)initWithCapacity:(NSUInteger)numItems
{
    self = [super init];
    if (!self)
        return nil;
    _dictionary = [NSMutableDictionary dictionaryWithCapacity:numItems];
    _cache = [[NSCache alloc] init];
    return self;
}

- (void)setObject:(id)object forKey:(id)key
{
    [_dictionary setObject:object forKey:key];
    [_cache setObject:object forKey:key];
}

- (void)removeObjectForKey:(id)key
{
    [_dictionary removeObjectForKey:key];
    [_cache removeObjectForKey:key];
}

@end
