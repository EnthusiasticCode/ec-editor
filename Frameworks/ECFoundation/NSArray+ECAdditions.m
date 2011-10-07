//
//  NSArray+ECAdditions.m
//  ECFoundation
//
//  Created by Uri Baghin on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSArray+ECAdditions.h"

@interface SortableWrapper : NSObject
@property (nonatomic, strong) NSNumber *sortKey;
@property (nonatomic, strong) id object;
@end

@implementation SortableWrapper
@synthesize sortKey;
@synthesize object;
@end

@implementation NSArray (ECAdditions)

- (NSArray *)cleanedArrayUsingBlock:(float (^)(id))scoreForObject
{
    return [self cleanedArrayUsingBlock:scoreForObject breakoffScore:0.0];
}

- (NSArray *)cleanedArrayUsingBlock:(float (^)(id))scoreForObject breakoffScore:(float)breakoffScore
{
    return [self cleanedArrayUsingBlock:scoreForObject breakoffScore:breakoffScore additionalSortDescriptors:nil];
}

- (NSArray *)cleanedArrayUsingBlock:(float (^)(id))scoreForObject breakoffScore:(float)breakoffScore additionalSortDescriptors:(NSArray *)sortDescriptors
{
    ECASSERT(scoreForObject);
    NSMutableArray *filteredWrappers = [[NSMutableArray alloc] init];
    for (id object in self)
    {
        float score = scoreForObject(object);
        if (score > breakoffScore)
        {
            SortableWrapper *wrapper = [[SortableWrapper alloc] init];
            wrapper.sortKey = [[NSNumber alloc] initWithFloat:score];
            wrapper.object = object;
            [filteredWrappers addObject:wrapper];
        }
    }
    if (![filteredWrappers count])
        return filteredWrappers;
    NSMutableArray *wrapperSortDescriptors = [NSMutableArray array];
    for (NSSortDescriptor *sortDescriptor in sortDescriptors)
    {
        ECASSERT([sortDescriptor selector]);
        [wrapperSortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:[@"object." stringByAppendingString:[sortDescriptor key]] ascending:[sortDescriptor ascending]]];
    }
    [wrapperSortDescriptors insertObject:[NSSortDescriptor sortDescriptorWithKey:@"sortKey" ascending:NO] atIndex:0];
    [filteredWrappers sortUsingDescriptors:wrapperSortDescriptors];
    NSMutableArray *cleanedArray = [NSMutableArray arrayWithCapacity:[filteredWrappers count]];
    for (SortableWrapper *wrapper in filteredWrappers)
        [cleanedArray addObject:wrapper.object];
    return cleanedArray;
}

@end
