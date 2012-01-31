//
//  NSURL+Compare.m
//  ArtCode
//
//  Created by Uri Baghin on 1/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSURL+Compare.h"

@implementation NSURL (Compare)

- (NSComparisonResult)compare:(NSURL *)other
{
    ECASSERT([self isFileURL] && [other isFileURL]);
    NSArray *pathComponents1 = [self pathComponents];
    NSArray *pathComponents2 = [other pathComponents];
    if ([pathComponents1 count] < [pathComponents2 count])
        return NSOrderedAscending;
    else if ([pathComponents1 count] > [pathComponents2 count])
        return NSOrderedDescending;
    
    __block NSComparisonResult result = NSOrderedSame;
    [pathComponents1 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        result = [(NSString *)obj compare:[pathComponents2 objectAtIndex:idx]];
        if (result != NSOrderedSame)
            *stop = YES;
    }];
    return result;
}

@end
