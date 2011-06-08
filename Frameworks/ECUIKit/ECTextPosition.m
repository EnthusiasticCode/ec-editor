//
//  ECTextPosition.m
//  edit
//
//  Created by Nicola Peduzzi on 02/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextPosition.h"


@implementation ECTextPosition
@synthesize index;

- (id)initWithIndex:(NSUInteger)idx
{
    self = [super init];
    index = idx;
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    if (NSShouldRetainWithZone(self, zone))
    {
        return [self retain];
    }
    else
    {
        ECTextPosition *result = [[ECTextPosition allocWithZone:zone] initWithIndex:index];
        return result;
    }
}

- (NSComparisonResult)compare:(id)other
{
    assert([other isKindOfClass:[self class]]);
    
    NSUInteger local = index;
    NSUInteger with = ((ECTextPosition*)other)->index;
    
    if (local < with)
        return NSOrderedAscending;
    else if (local == with)
        return NSOrderedSame;
    else
        return NSOrderedDescending;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%lu", (unsigned long)index];
}

@end
