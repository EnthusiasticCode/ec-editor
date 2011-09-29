//
//  ACGroup.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACGroup.h"
#import "ACURL.h"

@implementation ACGroup

- (NSURL *)ACURL
{
    
}

- (NSString *)relativePath;
{
    NSMutableArray *pathComponents = [NSMutableArray array];
    ACNode *node = self;
    do
    {
        [pathComponents insertObject:node.name atIndex:0];
        node = node.parent;
    }
    while (node);
    return [pathComponents componentsJoinedByString:@"/"];
}

@end
