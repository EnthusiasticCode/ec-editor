//
//  IndexedPosition.m
//  edit
//
//  Created by Uri Baghin on 1/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "IndexedPosition.h"


@implementation IndexedPosition

@synthesize index = _index;

+ (IndexedPosition *)positionWithIndex:(NSUInteger)index
{
    IndexedPosition *pos = [[IndexedPosition alloc] init];
    pos.index = index;
    return [pos autorelease];
}

@end
