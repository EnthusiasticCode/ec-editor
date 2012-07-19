//
//  ArtCodeDatastore.m
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeDatastore.h"
#import <CoreData/CoreData.h>
#import "NSURL+Utilities.h"

@interface ArtCodeDatastore ()

@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)_saveContext;

@end

@implementation ArtCodeDatastore {
  RACDisposable *_autosaveDisposable;
}

@synthesize managedObjectContext = _managedObjectContext, managedObjectModel = _managedObjectModel, persistentStoreCoordinator = _persistentStoreCoordinator;

+ (ArtCodeDatastore *)defaultDatastore {
  static ArtCodeDatastore *_defaultDatastore = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _defaultDatastore = [[self alloc] init];
  });
  return _defaultDatastore;
}

- (NSManagedObjectContext *)managedObjectContext {
  if (!_managedObjectContext) {
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [self persistentStoreCoordinator];
    if (persistentStoreCoordinator) {
      _managedObjectContext = [[NSManagedObjectContext alloc] init];
      [_managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    }
  }
  return _managedObjectContext;
}

- (void)setUp {
  ASSERT(!_autosaveDisposable);
  _autosaveDisposable = [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:[self managedObjectContext]] throttle:2.0] subscribeNext:^(id x) {
    [self _saveContext];
  }];
}

- (void)tearDown {
  ASSERT(_autosaveDisposable);
  [_autosaveDisposable dispose];
  _autosaveDisposable = nil;
  [self _saveContext];
}

#pragma mark - Private Methods

- (NSManagedObjectModel *)managedObjectModel {
  if (!_managedObjectModel) {
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]];
  }
  return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  if (!_persistentStoreCoordinator) {
    NSURL *storeURL = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:@"Datastore.sqlite"];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
       
       Typical reasons for an error here include:
       * The persistent store is not accessible;
       * The schema for the persistent store is incompatible with current managed object model.
       Check the error message to determine what the actual problem was.
       
       
       If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
       
       If you encounter schema incompatibility errors during development, you can reduce their frequency by:
       * Simply deleting the existing store:
       [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
       
       * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
       [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
       
       Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
       
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
  }
  return _persistentStoreCoordinator;
}

- (void)_saveContext {
  NSError *error = nil;
  [[self managedObjectContext] save:&error];
  if (error) {
    NSLog(@"Saving error: %@", error);
    abort();
  }
}

@end
