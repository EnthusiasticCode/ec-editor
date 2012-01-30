//
//  RectSet.m
//  edit
//
//  Created by Nicola Peduzzi on 06/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RectSet.h"


@implementation RectSet

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

- (id)initWithRects:(RectSet *)rects
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

- (CGRect)topLeftRect
{
    // TODO check for proper return
    return count ? buffer[0] : CGRectNull;
}

- (CGRect)bottomRightRect
{
    return count ? buffer[count - 1] : CGRectNull;
}

- (void)addRectsToContext:(CGContextRef)context
{
    CGContextAddRects(context, buffer, count);
}

- (id)copyWithZone:(NSZone *)zone
{
    // TODO check if proper ARC
    return [[RectSet alloc] initWithRects:self];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    // TODO check if proper ARC
    return [[MutableRectSet alloc] initWithRects:self];
}

//- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
//{
//    if (state->state >= count)
//    {
//        return 0;
//    }
//    
//    state->itemsPtr = buffer;
//    state->state = count;
//    state->mutationsPtr = (unsigned long*)self;
//    
//    return count;
//}

+ (id)rectSet
{
    return [[self alloc] init];
}

+ (id)rectSetWithRect:(CGRect)rect
{
    return [[self alloc] initWithRect:rect];
}

@end


@implementation MutableRectSet

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

- (void)addRects:(RectSet *)rects
{
    if (!rects || !rects.count)
        return;

    if (capacity - count < rects.count) 
    {
        capacity = count + rects.count;
        buffer = (CGRect *)realloc(buffer, capacity * sizeof(CGRect));
    }

    memcpy(&buffer[count], rects->buffer, rects.count * sizeof(CGRect));
    count += rects.count;
    
    // TODO calculate bounds?
}

- (void)removeRect:(CGRect)rect
{
    for (NSUInteger i = 0; i < count; ++i)
    {
        if (CGRectEqualToRect(buffer[i], rect))
        {
            memmove(&buffer[i], &buffer[i + 1], (count - i) * sizeof(CGRect));
            --count;
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
    return [[self alloc] initWithCapacity:cap];
}

@end
