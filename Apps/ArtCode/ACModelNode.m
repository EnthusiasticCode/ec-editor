//
//  ACModelNode.m
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACModelNode.h"
#import "ACModelHistoryItem.h"
#import "ACModelNode.h"


@implementation ACModelNode

@dynamic expanded;
@dynamic name;
@dynamic path;
@dynamic tag;
@dynamic type;
@dynamic children;
@dynamic parent;
@dynamic historyItems;

- (NSString *)absolutePath
{
    return [[[[[self.managedObjectContext.persistentStoreCoordinator.persistentStores objectAtIndex:0] URL] URLByDeletingLastPathComponent] URLByAppendingPathComponent:ACProjectContentDirectory] URLByStandardizingPath].path;
}

- (NSInteger)depth
{
    NSInteger depth = -1;
    ACModelNode *ancestor = self;
    while (ancestor.parent)
    {
        depth++;
        ancestor = ancestor.parent;
    }
    return depth;
}

- (ACModelNode *)addNodeWithName:(NSString *)name type:(ACProjectNodeType)type
{
    ACModelNode *node;
    switch (type) {
        case ACProjectNodeTypeFile:
            node = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:[self managedObjectContext]];
            node.path = [self.path stringByAppendingPathComponent:name];
            break;
        case ACProjectNodeTypeGroup:
            node = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:[self managedObjectContext]];
            node.path = self.path;
            break;
        case ACProjectNodeTypeFolder:
            node = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:[self managedObjectContext]];
            node.path = [self.path stringByAppendingPathComponent:name];
            break;
    }
    node.name = name;
    node.type = [NSNumber numberWithInt:type];
    node.parent = self;
    return node;
}

@end
