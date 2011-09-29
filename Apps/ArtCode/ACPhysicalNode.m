//
//  ACPhysicalNode.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACPhysicalNode.h"
#import "ACURL.h"

@implementation ACPhysicalNode

@dynamic physicalChildren;
@dynamic physicalParent;

- (NSString *)relativePath;
{
    NSMutableArray *pathComponents = [NSMutableArray array];
    ACPhysicalNode *node = self;
    do
    {
        [pathComponents insertObject:node.name atIndex:0];
        node = node.physicalParent;
    }
    while (node);
    return [pathComponents componentsJoinedByString:@"/"];
}

@end
