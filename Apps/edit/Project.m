//
//  Project.m
//  edit
//
//  Created by Uri Baghin on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Project.h"
#import <CoreData/CoreData.h>
#import "Node.h"
#import "File.h"

@interface Project ()
@property (nonatomic, strong) NSString *bundlePath;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSFileManager *_fileManager;
@property (nonatomic, strong) NSManagedObjectContext *_managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *_managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *_persistentStoreCoordinator;
@property (nonatomic, strong) Node *_rootNode;
- (Node *)_findRootNode;
- (void)_addNodesAtPath:(NSString *)path toNode:(Node *)node;
- (void)_addAllNodesInProjectRoot;
@end

@implementation Project

@synthesize bundlePath = _bundlePath;
@synthesize name = _name;
@synthesize _fileManager = __fileManager;
@synthesize _managedObjectContext = __managedObjectContext;
@synthesize _managedObjectModel = __managedObjectModel;
@synthesize _persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize _rootNode = __rootNode;

- (NSFileManager *)_fileManager
{
    if (!__fileManager)
        __fileManager = [[NSFileManager alloc] init];
    return __fileManager;
}

- (NSManagedObjectContext *)_managedObjectContext
{
    if (__managedObjectContext != nil)
        return __managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self _persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

- (NSManagedObjectModel *)_managedObjectModel
{
    if (__managedObjectModel != nil)
        return __managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Project" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

- (id)initWithBundle:(NSString *)bundlePath
{
    self = [super init];
    if (!self)
        return nil;
    self.bundlePath = bundlePath;
    NSURL *storeURL = [NSURL fileURLWithPath:[bundlePath stringByAppendingPathComponent:@"project.ecproj"]];
    if (![self._fileManager fileExistsAtPath:bundlePath])
        [self._fileManager createDirectoryAtPath:bundlePath withIntermediateDirectories:YES attributes:nil error:NULL];
    self._persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self _managedObjectModel]];
    NSError *error;
    if (![self._persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        //Replace this implementation with code to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    self.name = [bundlePath lastPathComponent];
    self._rootNode = [self _findRootNode];
    [self _addAllNodesInProjectRoot];
    [self saveContext];
    return self;
}

- (void)saveContext
{
    NSError *error;
    if (![self._managedObjectContext save:&error])
    {
        NSLog(@"Unresolved error in saving context %@, %@", error, [error userInfo]);
        abort();
    }
}

- (Node *)_findRootNode
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Node" inManagedObjectContext:self._managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"parent", nil];
    [fetchRequest setPredicate:predicate];
    NSArray *rootNodes = [self._managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    if ([rootNodes count] > 1)
        abort(); // core data file broken, all nodes except the root node should have a parent
    else if ([rootNodes count] == 1)
        return [rootNodes objectAtIndex:0];
    else
    {
        Node *_rootNode = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:self._managedObjectContext];
        _rootNode.name = @"";
        _rootNode.type = NodeTypeFolder;
        _rootNode.path = @"../";
        return _rootNode;
    }
}

- (void)_addNodesAtPath:(NSString *)path toNode:(Node *)node
{
    NSArray *subPaths = [self._fileManager contentsOfDirectoryAtPath:path error:NULL];
    NSMutableDictionary *subNodes = [NSMutableDictionary dictionaryWithCapacity:[subPaths count]];
    for (NSString *subPath in subPaths)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Node" inManagedObjectContext:self._managedObjectContext]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"parent", node];
        [fetchRequest setPredicate:predicate];
        NSUInteger count = [self._managedObjectContext countForFetchRequest:fetchRequest error:NULL];
        if (!count)
        {
            BOOL isDirectory;
            [self._fileManager fileExistsAtPath:[path stringByAppendingPathComponent:subPath] isDirectory:&isDirectory];
            if (isDirectory)
                [subNodes setObject:[node addNodeWithName:subPath type:NodeTypeFolder] forKey:subPath];
            else
                [node addNodeWithName:subPath type:NodeTypeFile];
        }
    }
    for (NSString *subPath in [subNodes allKeys])
        [self _addNodesAtPath:[path stringByAppendingPathComponent:subPath] toNode:[subNodes objectForKey:subPath]];
}

- (void)_addAllNodesInProjectRoot
{
    [self _addNodesAtPath:[self.bundlePath stringByAppendingPathComponent:self._rootNode.path] toNode:self._rootNode];
}

- (NSOrderedSet *)children
{
    return self._rootNode.children;
}

@end
