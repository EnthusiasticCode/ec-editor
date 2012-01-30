//
//  TextPosition.m
//  edit
//
//  Created by Nicola Peduzzi on 02/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextPosition.h"


@implementation TextPosition
@synthesize index;

- (id)initWithIndex:(NSUInteger)idx
{
    self = [super init];
    index = idx;
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSComparisonResult)compare:(id)other
{
    assert([other isKindOfClass:[self class]]);
    
    NSUInteger local = index;
    NSUInteger with = ((TextPosition*)other)->index;
    
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
