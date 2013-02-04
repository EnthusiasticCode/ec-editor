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

  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
  NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"%K == %@", @"name", defaultSetName];
  [fetchRequest setPredicate:searchPredicate];
  
  NSManagedObjectContext *context = ArtCodeDatastore.defaultDatastore.managedObjectContext;
  
  NSArray *results = [context executeFetchRequest:fetchRequest error:NULL];
  if (results.count > 0) {
    ASSERT(results.count == 1); // if more than 1 they should be merged
    return results[0];
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
  return [self addNewTabWithDictionary:tab.currentLocation.dictionary];
}

- (ArtCodeTab *)addNewTabWithDictionary:(NSDictionary *)dictionary {
  ArtCodeTab *newTab = [ArtCodeTab insertInManagedObjectContext:self.managedObjectContext];
	[newTab pushLocationWithDictionary:dictionary];
  newTab.tabSet = self;
  [_objectsAddedSubject sendNext:newTab];
  return newTab;
}

@end
