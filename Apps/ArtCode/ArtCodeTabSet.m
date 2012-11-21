//
//  ArtCodeTabSet.m
//  ArtCode
//
//  Created by Uri Baghin on 7/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTabSet.h"
#import "ArtCodeDatastore.h"
#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"

@implementation ArtCodeTabSet {
  RACSubject *_objectsAddedSubject;
}

#pragma mark - RAC Support

- (RACSignal *)objectsAdded {
  if (!_objectsAddedSubject) {
    _objectsAddedSubject = [RACSubject subject];
  }
  return _objectsAddedSubject;
}

- (void)willTurnIntoFault {
  [super willTurnIntoFault];
  _objectsAddedSubject = nil;
}

#pragma mark - Public Methods

+ (ArtCodeTabSet *)defaultSet {
  static NSString *defaultSetName = @"default";

  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
  NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"name", defaultSetName];
  [fetchRequest setPredicate:searchPredicate];
  
  NSManagedObjectContext *context = [[ArtCodeDatastore defaultDatastore] managedObjectContext];
  
  NSArray *results = [context executeFetchRequest:fetchRequest error:NULL];
  if ([results count] > 0) {
    ASSERT([results count] == 1); // if more than 1 they should be merged
    return [results objectAtIndex:0];
  }
  
  // At this point there is no default tab set and it should be created
  ArtCodeTabSet *defaultTabSet = [self insertInManagedObjectContext:context];
  defaultTabSet.name = defaultSetName;
  
  return defaultTabSet;
}

- (void)awakeFromInsert {
  [super awakeFromInsert];
  ArtCodeTab *blankTab = [ArtCodeTab insertInManagedObjectContext:self.managedObjectContext];
  blankTab.tabSet = self;
}

- (ArtCodeTab *)addNewTabByDuplicatingTab:(ArtCodeTab *)tab {
  return [self addNewTabWithLocationType:tab.currentLocation.type project:tab.currentLocation.project remote:tab.currentLocation.remote data:tab.currentLocation.data];
}

- (ArtCodeTab *)addNewTabWithLocationType:(ArtCodeLocationType)type project:(ArtCodeProject *)project remote:(ArtCodeRemote *)remote data:(NSData *)data {
  ArtCodeTab *newTab = [ArtCodeTab insertInManagedObjectContext:self.managedObjectContext];
  newTab.tabSet = self;
  ArtCodeLocation *newLocation = [ArtCodeLocation insertInManagedObjectContext:self.managedObjectContext];
  newLocation.type = type;
  newLocation.project = project;
  newLocation.remote = remote;
  newLocation.data = data;
  [newTab replaceCurrentLocationWithLocation:newLocation];
  // inform rag
  [_objectsAddedSubject sendNext:newTab];
  return newTab;
}

@end
