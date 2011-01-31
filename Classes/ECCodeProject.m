//
//  ECCodeProject.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeProject.h"
#import <CoreData/CoreData.h>


@implementation ECCodeProject


@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;
@synthesize rootDirectory;
@synthesize name;

+ (BOOL)instancesRespondToSelector:(SEL)aSelector
{
    if (aSelector == @selector(init))
        return NO;
    return [super instancesRespondToSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (aSelector == @selector(init))
        return NO;
    return [super respondsToSelector:aSelector];
}

- (id)initWithRootDirectory:(NSString *)theRootDirectory name:(NSString *)theName
{
    self = [super init];
    if (self)
    {
        name = [theName retain];
        rootDirectory = [theRootDirectory retain];
    }
    return self;
}

- (void)dealloc
{
    // Saves changes in the application's managed object context before the application terminates.
    NSError *error = nil;
    if (managedObjectContext) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
    [rootDirectory release];
    [name release];
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    [super dealloc];
}

#pragma mark -
#pragma mark Core Data template

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext)
        return managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator)
    {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel)
        return managedObjectModel;
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    
    if (persistentStoreCoordinator)
        return persistentStoreCoordinator;
    
    NSURL *storeUrl = [NSURL fileURLWithPath:[self.rootDirectory stringByAppendingPathComponent:[self.name stringByAppendingPathExtension:@"sqlite"]]];
    
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible
         * The schema for the persistent store is incompatible with current managed object model
         Check the error message to determine what the actual problem was.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator;
}

@end
