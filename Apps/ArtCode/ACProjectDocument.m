//
//  ACProjectDocument.m
//  ArtCode
//
//  Created by Uri Baghin on 8/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectDocument.h"
#import "ACNode.h"
#import "ACURL.h"

@interface ACProjectDocument ()
@property (nonatomic, strong, readonly) NSFileManager *fileManager;
- (ACNode *)findRootNode;
- (void)addNodesAtPath:(NSString *)path toNode:(ACNode *)node;
- (void)addAllNodesInProjectRoot;
@end

@implementation ACProjectDocument

@synthesize fileManager = _fileManager;
@synthesize rootNode = _rootNode;

- (NSFileManager *)fileManager
{
    if (!_fileManager)
        _fileManager = [[NSFileManager alloc] init];
    return _fileManager;
}

- (ACNode *)rootNode
{
    if (!_rootNode)
        _rootNode = [self findRootNode];
    return _rootNode;
}

+ (NSString *)persistentStoreName
{
    return @"acproject.db";
}

- (NSDictionary *)persistentStoreOptions
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
}

- (ACNode *)findRootNode
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Node" inManagedObjectContext:self.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"parent", nil];
    [fetchRequest setPredicate:predicate];
    NSArray *rootNodes = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    if ([rootNodes count] > 1)
        abort(); // core data file broken, all nodes except the root node should have a parent
    else if ([rootNodes count] == 1)
        return [rootNodes objectAtIndex:0];
    else
    {
        ACNode *rootNode = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:self.managedObjectContext];
        rootNode.name = @"";
        rootNode.type = ACNodeTypeFolder;
        rootNode.path = @"";
        return rootNode;
    }
}

- (void)addNodesAtPath:(NSString *)path toNode:(ACNode *)node
{
    NSArray *subPaths = [self.fileManager contentsOfDirectoryAtPath:path error:NULL];
    NSMutableDictionary *subNodes = [NSMutableDictionary dictionaryWithCapacity:[subPaths count]];
    for (NSString *subPath in subPaths)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Node" inManagedObjectContext:self.managedObjectContext]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"parent", node];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:predicate, [NSPredicate predicateWithFormat:@"%K == %@", @"path", [path stringByAppendingPathComponent:subPath]], nil]];
        [fetchRequest setPredicate:predicate];
        NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:NULL];
        if (!count)
        {
            BOOL isDirectory;
            [self.fileManager fileExistsAtPath:[path stringByAppendingPathComponent:subPath] isDirectory:&isDirectory];
            if (isDirectory)
                [subNodes setObject:[node addNodeWithName:subPath type:ACNodeTypeFolder] forKey:subPath];
            else
                [node addNodeWithName:subPath type:ACNodeTypeSourceFile];
        }
    }
    for (NSString *subPath in [subNodes allKeys])
        [self addNodesAtPath:[path stringByAppendingPathComponent:subPath] toNode:[subNodes objectForKey:subPath]];
}

- (void)addAllNodesInProjectRoot
{
    [self addNodesAtPath:[self.fileURL URLByAppendingPathComponent:ACProjectContentDirectory].path toNode:self.rootNode];
}

@end
