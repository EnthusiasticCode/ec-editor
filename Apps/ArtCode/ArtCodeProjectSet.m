//
//  ArtCodeProjectSet.m
//  ArtCode
//
//  Created by Uri Baghin on 7/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeProjectSet.h"
#import "ArtCodeDatastore.h"
#import "NSURL+Utilities.h"
#import "NSFileCoordinator+CoordinatedFileManagement.h"
#import "ArtCodeProject.h"


static NSString * const _localProjectsFolderName = @"LocalProjects";


@implementation ArtCodeProjectSet {
  RACSubject *_objectsAddedSubject;
  RACSubject *_objectsRemovedSubject;
}

- (RACSubscribable *)objectsAdded {
  if (!_objectsAddedSubject) {
    _objectsAddedSubject = [RACSubject subject];
  }
  return _objectsAddedSubject;
}

- (RACSubscribable *)objectsRemoved {
  if (!_objectsRemovedSubject) {
    _objectsRemovedSubject = [RACSubject subject];
  }
  return _objectsRemovedSubject;  
}

- (void)willTurnIntoFault {
  [super willTurnIntoFault];
  _objectsAddedSubject = nil;
  _objectsRemovedSubject = nil;
}

#pragma mark - KVO overrides

+ (NSSet *)keyPathsForValuesAffectingFileURL {
  return [NSSet setWithObject:@"name"];
}

#pragma mark - Public Methods

+ (ArtCodeProjectSet *)defaultSet {
  static NSString * const _defaultProjectSetName = @"default";
  static ArtCodeProjectSet *defaultSet = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"name", _defaultProjectSetName];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
    [fetchRequest setPredicate:predicate];
    NSManagedObjectContext *defaultContext = [[ArtCodeDatastore defaultDatastore] managedObjectContext];
    NSArray *results = [defaultContext executeFetchRequest:fetchRequest error:NULL];
    if ([results count]) {
      defaultSet = [results objectAtIndex:0];
    } else {
      defaultSet = [self insertInManagedObjectContext:defaultContext];
      [defaultSet setName:_defaultProjectSetName];
    }
  });
  return defaultSet;
}

- (NSURL *)fileURL {
  return [[[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:_localProjectsFolderName] URLByAppendingPathComponent:[self name]];
}

- (void)addNewProjectWithName:(NSString *)name completionHandler:(void (^)(ArtCodeProject *))completionHandler {
  [NSFileCoordinator coordinatedMakeDirectoryAtURL:[[self fileURL] URLByAppendingPathComponent:name] renameIfNeeded:NO completionHandler:^(NSError *error, NSURL *newURL) {
    if (error) {
      completionHandler(nil);
      return;
    }
    ArtCodeProject *project = [ArtCodeProject insertInManagedObjectContext:self.managedObjectContext];
    [project setName:[newURL lastPathComponent]];
    [project setProjectSet:self];
    [(RACSubject *)self.objectsAdded sendNext:project];
    completionHandler(project);
  }];
}

- (void)removeProject:(ArtCodeProject *)project completionHandler:(void (^)(NSError *))completionHandler {
  [NSFileCoordinator coordinatedDeleteItemsAtURLs:[NSArray arrayWithObject:[project fileURL]] completionHandler:^(NSError *error) {
    if (error) {
      completionHandler(error);
      return;
    }
    project.projectSet = nil;
    [(RACSubject *)self.objectsRemoved sendNext:project];
    [[self managedObjectContext] deleteObject:project];
    completionHandler(nil);
  }];
}

@end
