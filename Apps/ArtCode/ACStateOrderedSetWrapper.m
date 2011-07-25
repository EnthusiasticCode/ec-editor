//
//  ACStateOrderedSetWrapper.m
//  ArtCode
//
//  Created by Uri Baghin on 7/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateOrderedSetWrapper.h"
#import "ACState.h"
#import "ACStateInternal.h"

@interface ACStateOrderedSetWrapper ()
{
    NSOrderedSet *_orderedSet;
}
@end

@implementation ACStateOrderedSetWrapper

- (id)initWithOrderedSet:(NSOrderedSet *)set
{
    // WARNING:
    // cannot subclass NSOrderedSet property because documentation is missing
    // refactor when documentation becomes available
    self = (ACStateOrderedSetWrapper *)[[NSObject alloc] init];
    //    self = [super init];
    if (!self)
        return nil;
    _orderedSet = set;
    return self;
}

+ (id)orderedSetWithOrderedSet:(NSOrderedSet *)set
{
    ACStateOrderedSetWrapper *orderedSet = [self alloc];
    orderedSet = [orderedSet initWithOrderedSet:set];
    return orderedSet;
}

- (NSUInteger)count
{
    return [_orderedSet count];
}

- (id)objectAtIndex:(NSUInteger)idx
{
    return [ACState ACStateProxyForObject:[_orderedSet objectAtIndex:idx]];
}

@end
