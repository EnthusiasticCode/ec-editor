//
//  ECStackBuffer.m
//  edit
//
//  Created by Uri Baghin on 4/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECStackCache.h"

@interface ECStackCache ()
{
    NSMutableArray *_stack;
}
@end

@implementation ECStackCache

@synthesize cacheSize = _cacheSize;
@synthesize target = _target;
@synthesize action = _action;


- (id)initWithTarget:(id)target action:(SEL)action size:(NSUInteger)size
{
    self = [super init];
    if (!self)
        return nil;
    _cacheSize = size;
    _stack = [[NSMutableArray alloc] initWithCapacity:size];
    _target = target;
    _action = action;
    return self;
}

- (NSUInteger)count
{
    return [_stack count];
}

- (id)pop
{
    if (![_stack count])
        return [_target performSelector:_action withObject:self];
    id object = [_stack lastObject];
    [_stack removeLastObject];
    return object;
}

- (void)push:(id)object;
{
    if ([_stack count] >= _cacheSize)
        return;
    [_stack addObject:object];
}

@end
