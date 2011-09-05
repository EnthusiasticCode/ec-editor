//
//  ACNode.m
//  ArtCode
//
//  Created by Uri Baghin on 8/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNode.h"
#import "ACURL.h"

#import "ECCodeUnit.h"
#import "ECCodeIndex.h"

@interface ACNode ()

@property (nonatomic, strong) ECCodeUnit *codeUnit;

@end


@implementation ACNode

@dynamic expanded;
@dynamic name, path;
@dynamic tag, type;
@dynamic children, parent;

@synthesize codeUnit = _codeUnit;

- (NSString *)nodeType
{
    switch (self.type) {
        case ACNodeTypeFolder:
            return ACStateNodeTypeFolder;
            break;
        case ACNodeTypeGroup:
            return ACStateNodeTypeGroup;
            break;
        case ACNodeTypeSourceFile:
            return ACStateNodeTypeSourceFile;
            break;
    }
    return nil;
}

- (NSUInteger)index
{
    return [self.parent.children indexOfObject:self];
}

- (void)setIndex:(NSUInteger)index
{
    [[self.parent mutableOrderedSetValueForKey:@"children"] insertObject:self atIndex:index];
}

- (NSURL *)URL
{
    CDNode *ancestor = self;
    NSMutableArray *pathComponents = [NSMutableArray array];
    [pathComponents addObject:ancestor.name];
    while (ancestor.parent) {
        ancestor = ancestor.parent;
        [pathComponents addObject:ancestor.name];
    }
    __block NSURL *URL = [NSURL ACURLForLocalProjectWithName:[pathComponents lastObject]];
    [pathComponents removeLastObject];
    [pathComponents enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id pathComponent, NSUInteger idx, BOOL *stop) {
        URL = [URL URLByAppendingPathComponent:pathComponent];
    }];
    return URL;
}

- (void)delete
{
    [self.managedObjectContext deleteObject:self];
}

- (NSURL *)fileURL
{
    NSURL *fileURL = [[[[[self.managedObjectContext.persistentStoreCoordinator.persistentStores objectAtIndex:0] URL] URLByDeletingLastPathComponent] URLByDeletingLastPathComponent] URLByAppendingPathComponent:ACProjectContentDirectory];
    for (NSString *pathComponent in [self.path pathComponents])
        fileURL = [fileURL URLByAppendingPathComponent:pathComponent];
    NSLog(@"%@", [fileURL URLByStandardizingPath]);
    return [fileURL URLByStandardizingPath];
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
            node = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:[self managedObjectContext]];
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

- (ACNode *)childNodeWithName:(NSString *)name
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Node"];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:[NSPredicate predicateWithFormat:@"%K == %@", @"parent", self], [NSPredicate predicateWithFormat:@"%K == %@", @"name", name], nil]];
    [fetchRequest setPredicate:predicate];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    return [results objectAtIndex:0];
}

- (NSString *)contentString
{
    return [NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:NULL];
}

- (void)loadCodeUnitWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        ECCodeIndex *index = [[ECCodeIndex alloc] init];
        self.codeUnit = [index unitForFile:[self.fileURL path]];
        completionHandler(true);
    });
}

@end
