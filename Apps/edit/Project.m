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
@property (nonatomic, retain) Node *rootNode;
- (Node *)_findRootNode;
@end

@implementation Project

@synthesize bundle = _bundle;
@synthesize name = _name;
@synthesize fileManager = _fileManager;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize rootNode = _rootNode;

- (NSFileManager *)fileManager
{
    if (!_fileManager)
        _fileManager = [[NSFileManager alloc] init];
    return _fileManager;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
        return _managedObjectContext;
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
        return _managedObjectModel;
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Project" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return _managedObjectModel;
}

- (void)dealloc
{
    self.name = nil;
    self.rootNode = nil;
    self.bundle = nil;
    self.fileManager = nil;
    self.managedObjectContext = nil;
    self.persistentStoreCoordinator = nil;
    self.managedObjectModel = nil;
    [super dealloc];
}

- (id)initWithBundle:(NSString *)bundle
{
    self = [super init];
    if (!self)
        return nil;
    self.bundle = bundle;
    NSString *storePath = [bundle stringByAppendingPathComponent:@"project.ecproj"];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    if (![self.fileManager fileExistsAtPath:bundle])
        [self.fileManager createDirectoryAtPath:bundle withIntermediateDirectories:YES attributes:nil error:NULL];
    self.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]] autorelease];
    NSError *error;
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        //Replace this implementation with code to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    self.name = [bundle lastPathComponent];
    self.rootNode = [self _findRootNode];
    [self saveContext];
    return self;
}

- (void)saveContext
{
    NSError *error;
    if (![self.managedObjectContext save:&error])
    {
        NSLog(@"Unresolved error in saving context %@, %@", error, [error userInfo]);
        abort();
    }
}

- (Node *)_findRootNode
{
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
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
        Node *rootNode = [NSEntityDescription insertNewObjectForEntityForName:@"Node" inManagedObjectContext:self.managedObjectContext];
        rootNode.name = @"";
        return rootNode;
    }
}

@end
