//
//  IndexedRange.m
//  edit
//
//  Created by Uri Baghin on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IndexedRange.h"


@implementation IndexedRange

@synthesize range = _range;

+ (IndexedRange *)rangeWithNSRange:(NSRange)nsrange
{
    if (nsrange.location == NSNotFound)
        return nil;
    IndexedRange *range = [[IndexedRange alloc] init];
    range.range = nsrange;
    return [range autorelease];
}

- (UITextPosition *)start
{
    return [IndexedPosition positionWithIndex:self.range.location];
}

- (UITextPosition *)end
{
    return [IndexedPosition positionWithIndex:(self.range.location + self.range.length)];
}

-(BOOL)isEmpty {
    return (self.range.length == 0);
}

@end
