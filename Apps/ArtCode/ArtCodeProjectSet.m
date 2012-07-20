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
static NSString * const _defaultProjectSetName = @"default";


@interface ArtCodeProjectSet ()

- (NSURL *)_fileURL;

@end


@implementation ArtCodeProjectSet

+ (ArtCodeProjectSet *)defaultSet {
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
      defaultSet.name = _defaultProjectSetName;
    }
  });
  return defaultSet;
}

- (NSURL *)_fileURL {
  return [[[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:_localProjectsFolderName] URLByAppendingPathComponent:self.name];
}

- (void)addNewProjectWithName:(NSString *)name completionHandler:(void (^)(ArtCodeProject *))completionHandler {
  [NSFileCoordinator coordinatedMakeDirectoryAtURL:[[self _fileURL] URLByAppendingPathComponent:name] renameIfNeeded:NO completionHandler:^(NSError *error, NSURL *newURL) {
    if (error) {
      completionHandler(nil);
      return;
    }
    ArtCodeProject *project = [ArtCodeProject insertInManagedObjectContext:self.managedObjectContext];
    project.name = [newURL lastPathComponent];
    project.projectSet = self;
    completionHandler(project);
  }];
}

- (void)removeProject:(ArtCodeProject *)project completionHandler:(void (^)(NSError *))completionHandler {
  [NSFileCoordinator coordinatedDeleteItemsAtURLs:[NSArray arrayWithObject:[project fileURL]] completionHandler:^(NSError *error) {
    if (error) {
      completionHandler(error);
      return;
    }
    [self.managedObjectContext deleteObject:project];
    completionHandler(nil);
  }];
}

@end
