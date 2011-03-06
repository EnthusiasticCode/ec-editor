//
//  ECRectSet.m
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECRectSet.h"


@implementation ECRectSet

@synthesize count;

- (CGRect)bounds
{
    if (CGRectIsNull(bounds))
    {
        for (NSUInteger i = 0; i < count; ++i)
        {
            bounds = CGRectUnion(bounds, buffer[i]);
        }
    }
    return bounds;
}

- (id)init
{
    if ((self = [super init]))
    {
        bounds = CGRectNull;
    }
    return self;
}

- (id)initWithRect:(CGRect)rect
{
    if ((self = [self init]))
    {
        buffer = (CGRect *)malloc(sizeof(CGRect));
        *buffer = rect;
        count = capacity = 1;
    }
    return self;
}

- (id)initWithRects:(ECRectSet *)rects
{
    if ((self = [self init]))
    {
        count = capacity = rects.count;
        buffer = (CGRect *)malloc(count * sizeof(CGRect));
        memcpy(buffer, rects->buffer, count * sizeof(CGRect));
    }
    return self;
}

- (void)dealloc
{
    free(buffer);
    [super dealloc];
}

- (void)enumerateRectsUsingBlock:(void (^)(CGRect, BOOL *))block
{
    BOOL stop = NO;
    for (NSUInteger i = 0; i < count; ++i)
    {
        block(buffer[i], &stop);
        if (stop)
            break;
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    if (NSShouldRetainWithZone(self, zone))
    {
        return [self retain];
    }
    else
    {
        ECRectSet *result = [[ECRectSet allocWithZone:zone] initWithRects:self];
        return result;
    }
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    if (NSShouldRetainWithZone(self, zone))
    {
        return [self retain];
    }
    else
    {
        ECMutableRectSet *result = [[ECMutableRectSet allocWithZone:zone] initWithRects:self];
        return result;
    }
}

+ (id)rectSet
{
    return [[[self alloc] init] autorelease];
}

+ (id)rectSetWithRect:(CGRect)rect
{
    return [[[self alloc] initWithRect:rect] autorelease];
}

@end


@implementation ECMutableRectSet

- (id)initWithCapacity:(NSUInteger)cap
{
    if ((self = [super init]))
    {
        capacity = cap;
        buffer = (CGRect *)malloc(cap * sizeof(CGRect));
    }
    return self;
}

- (void)addRect:(CGRect)rect
{
    // TODO guarantee single rect
    NSUInteger newCount = count + 1;
    if (capacity <= count)
    {
        buffer = (CGRect *)realloc(buffer, newCount * sizeof(CGRect));
        capacity = newCount;
    }
    buffer[count] = rect;
    count = newCount;
}

- (void)removeRect:(CGRect)rect
{
    for (NSUInteger i = 0; i < count; ++i)
    {
        if (CGRectEqualToRect(buffer[i], rect))
        {
            memmove(&buffer[i], &buffer[i + 1], (count - i) * sizeof(CGRect));
            count--;
            bounds = CGRectNull;
            return;
        }
    }
}

- (void)removeAllRects
{
    count = 0;
}

+ (id)rectSetWithCapacity:(NSUInteger)cap
{
    return [[[self alloc] initWithCapacity:cap] autorelease];
}

@end
