//
//  ACHistoryItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACHistoryItem.h"
#import "ACTab.h"


@implementation ACHistoryItem

@dynamic tab;

- (NSURL *)URL
{
    return [NSURL URLWithString:[self primitiveValueForKey:@"URL"]];
}

- (void)setURL:(NSURL *)URL
{
    [self willChangeValueForKey:@"URL"];
    [self setPrimitiveValue:[URL absoluteString] forKey:@"URL"];
    [self didChangeValueForKey:@"URL"];
}

@end
