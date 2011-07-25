//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACModelNode.h"

NSString * const ACProjectContentDirectory = @"Content";

@interface ACProject ()
@property (nonatomic, strong, readonly) NSFileManager *fileManager;
@property (nonatomic, strong) ACModelNode *rootNode;
- (ACModelNode *)findRootNode;
- (void)addNodesAtPath:(NSString *)path toNode:(ACModelNode *)node;
- (void)addAllNodesInProjectRoot;
@end


@implementation ACProject

@synthesize fileManager = _fileManager;
@synthesize rootNode = _rootNode;

- (NSFileManager *)_fileManager
{
    if (!_fileManager)
        _fileManager = [[NSFileManager alloc] init];
    return _fileManager;
}

+ (NSString *)persistentStoreName
{
    return @"acproject.db";
}

- (ACModelNode *)findRootNode
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
        ACModelNode *rootNode = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:self.managedObjectContext];
        rootNode.name = @"";
        rootNode.type = [NSNumber numberWithInt:ACProjectNodeTypeFolder];
        rootNode.path = @"";
        return rootNode;
    }
}

- (void)addNodesAtPath:(NSString *)path toNode:(ACModelNode *)node
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
                [subNodes setObject:[node addNodeWithName:subPath type:ACProjectNodeTypeFolder] forKey:subPath];
            else
                [node addNodeWithName:subPath type:ACProjectNodeTypeFile];
        }
    }
    for (NSString *subPath in [subNodes allKeys])
        [self addNodesAtPath:[path stringByAppendingPathComponent:subPath] toNode:[subNodes objectForKey:subPath]];
}

- (NSURL *)contentDirectory
{
    return [self.fileURL URLByAppendingPathComponent:ACProjectContentDirectory];
}

- (NSURL *)documentDirectory
{
    return self.fileURL;
}

- (void)addAllNodesInProjectRoot
{
    [self addNodesAtPath:[[self contentDirectory] path] toNode:self.rootNode];
}

- (NSOrderedSet *)children
{
    return self.rootNode.children;
}

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [super openWithCompletionHandler:completionHandler];
    [self addAllNodesInProjectRoot];
}

@end
