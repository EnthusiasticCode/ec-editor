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

- (Node *)addNodeWithName:(NSString *)name type:(NodeType)type
{
    Node *node = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:[self managedObjectContext]];
    node.name = name;
    node.type = type;
    node.parent = self;
    return node;
}

- (File *)addFileWithPath:(NSString *)path
{
    File *file = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:[self managedObjectContext]];
    file.path = path;
    file.type = NodeTypeFile;
    file.name = [path lastPathComponent];
    file.parent = self;
    return file;
}

@end
