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
#import <ReactiveCocoaIO/RCIODirectory.h>
#import "ArtCodeProject.h"


static NSString * const _localProjectsFolderName = @"LocalProjects";


@implementation ArtCodeProjectSet {
  RACSubject *_objectsAddedSubject;
  RACSubject *_objectsRemovedSubject;
}

- (RACSignal *)objectsAdded {
  if (!_objectsAddedSubject) {
    _objectsAddedSubject = [RACSubject subject];
  }
  return _objectsAddedSubject;
}

- (RACSignal *)objectsRemoved {
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
      defaultSet = results[0];
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

- (void)addNewProjectWithName:(NSString *)name labelColor:(UIColor *)labelColor completionHandler:(void (^)(ArtCodeProject *))completionHandler {
  [[[RCIODirectory itemWithURL:[[self fileURL] URLByAppendingPathComponent:name]] flattenMap:^(RCIODirectory *directory) {
		return [directory create];
	}] subscribeNext:^(RCIODirectory *directory) {
    ArtCodeProject *project = [ArtCodeProject insertInManagedObjectContext:self.managedObjectContext];
    [project setName:name];
    [project setLabelColor:labelColor];
    [project setProjectSet:self];
    [_objectsAddedSubject sendNext:project];
    completionHandler(project);
  } error:^(NSError *error) {
    completionHandler(nil);
  }];
}

- (void)removeProject:(ArtCodeProject *)project completionHandler:(void (^)(NSError *))completionHandler {
  [[[[RCIODirectory itemWithURL:project.fileURL] map:^RACSignal *(RCIODirectory *directory) {
    return [directory delete];
  }] switchToLatest] subscribeError:^(NSError *error) {
    completionHandler(error);
  } completed:^{
    project.projectSet = nil;
    [_objectsRemovedSubject sendNext:project];
    [[self managedObjectContext] deleteObject:project];
    completionHandler(nil);
  }];
}

- (NSString *)relativePathForFileURL:(NSURL *)fileURL {
  NSString *path = fileURL.path;
  NSString *projectSetPath = self.fileURL.path;
  if (![path hasPrefix:projectSetPath]) {
    return @"";
  }
  return [path substringFromIndex:projectSetPath.length + 1];
}

@end
