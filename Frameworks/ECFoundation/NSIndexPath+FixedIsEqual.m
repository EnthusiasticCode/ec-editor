//
//  NSIndexPath+FixedIsEqual.m
//  edit
//
//  Created by Uri Baghin on 4/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSIndexPath+FixedIsEqual.h"
#import "ECHashing.h"

@implementation NSIndexPath (FixedIsEqual)

- (NSUInteger)hash
{
    static NSUInteger hash = NSUIntegerMax;
    if (hash != NSUIntegerMax)
        return hash;
    NSUInteger numIndexes = [self length];
    NSUInteger *indexes = malloc(numIndexes * sizeof(NSUInteger));
    for (NSUInteger i = 0; i < numIndexes; ++i)
        indexes[i] = [self indexAtPosition:i];
    hash = ECHashNSUIntegers(indexes, numIndexes);
    free(indexes);
    return hash;
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]])
        return [super isEqual:object];
    if ([self hash] != [object hash])
        return NO;
    NSUInteger numIndexes = [self length];
    if (numIndexes != [object length])
        return NO;
    for (NSUInteger i = 0; i < numIndexes; ++i)
        if ([self indexAtPosition:i] != [object indexAtPosition:i])
            return NO;
    return YES;
}

@end
