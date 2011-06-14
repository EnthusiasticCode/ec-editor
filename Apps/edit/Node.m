//
//  Node.m
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Node.h"
#import "File.h"

@implementation Node

@dynamic collapsed;
@dynamic name;
@dynamic tag;
@dynamic type;
@dynamic path;
@dynamic children;
@dynamic nameWords;
@dynamic parent;

- (Node *)addNodeWithName:(NSString *)name type:(NodeType)type
{
    Node *node;
    switch (type) {
        case NodeTypeFile:
            node = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:[self managedObjectContext]];
            node.path = [self.path stringByAppendingPathComponent:name];
            break;
        case NodeTypeGroup:
            node = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:[self managedObjectContext]];
            node.path = self.path;
            break;
        case NodeTypeFolder:
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
