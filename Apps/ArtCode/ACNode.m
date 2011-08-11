//
//  ACNode.m
//  ArtCode
//
//  Created by Uri Baghin on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNode.h"
#import "ACURL.h"

@implementation ACNode

- (NSString *)absolutePath
{
    return [[[[[self.managedObjectContext.persistentStoreCoordinator.persistentStores objectAtIndex:0] URL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:ACProjectContentDirectory] URLByStandardizingPath].path;
}

- (NSInteger)depth
{
    NSInteger depth = -1;
    CDNode *ancestor = self;
    while (ancestor.parent)
    {
        depth++;
        ancestor = ancestor.parent;
    }
    return depth;
}

- (ACNode *)addNodeWithName:(NSString *)name type:(ACNodeType)type
{
    ACNode *node;
    switch (type) {
        case ACNodeTypeSourceFile:
            node = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:[self managedObjectContext]];
            node.path = [self.path stringByAppendingPathComponent:name];
            break;
        case ACNodeTypeGroup:
            node = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:[self managedObjectContext]];
            node.path = self.path;
            break;
        case ACNodeTypeFolder:
            node = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:[self managedObjectContext]];
            node.path = [self.path stringByAppendingPathComponent:name];
            break;
    }
    node.name = name;
    node.type = type;
    node.parent = self;
    return node;
}

@end
