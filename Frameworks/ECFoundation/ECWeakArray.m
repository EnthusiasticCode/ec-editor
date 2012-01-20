//
//  ECWeakArray.m
//  ECFoundation
//
//  Created by Uri Baghin on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ECWeakArray.h"
#import "WeakObjectWrapper.h"

@interface ECWeakArray ()
{
    NSMutableArray *_contents;
}
- (void)_purge;
@end

@implementation ECWeakArray

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
    ECASSERT(_contents);
    return [_contents count];
}

- (id)objectAtIndex:(NSUInteger)index
{
    ECASSERT(_contents);
    WeakObjectWrapper *wrapper = [_contents objectAtIndex:index];
    if (!wrapper)
        return nil;
    return wrapper->object;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    ECASSERT(_contents);
    [self _purge];
    return [_contents countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - NSMutableArray

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    ECASSERT(_contents && anObject);
    [_contents insertObject:[WeakObjectWrapper wrapperWithObject:anObject] atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    ECASSERT(_contents);
    [_contents removeObjectAtIndex:index];
}

- (void)addObject:(id)anObject
{
    ECASSERT(_contents && anObject);
    [_contents addObject:[WeakObjectWrapper wrapperWithObject:anObject]];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    ECASSERT(_contents && anObject);
    ((WeakObjectWrapper *)[_contents objectAtIndex:index])->object = anObject;
}

#pragma mark - Private methods

- (void)_purge
{
    ECASSERT(_contents);
    NSIndexSet *indexes = [_contents indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if (((WeakObjectWrapper *)obj)->object)
            return NO;
        return YES;
    }];
    [_contents removeObjectsAtIndexes:indexes];
}

@end
