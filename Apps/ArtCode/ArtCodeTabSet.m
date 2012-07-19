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

@implementation ArtCodeTabSet

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

#pragma mark - Validation

- (BOOL)_validateTabsWithError:(NSError *__autoreleasing *)error {
  // Validates tabs and create a blank tab if neccessary
  NSOrderedSet *oldTabs = self.tabs;
  NSOrderedSet *newTabs = oldTabs;
  if (![self validateValue:&newTabs forKey:@"tabs" error:error]) {
    return NO;
  }
  if (newTabs != oldTabs) {
    self.tabs = newTabs;
  }
  return YES;
}

- (BOOL)validateForInsert:(NSError *__autoreleasing *)error {
  if (![super validateForInsert:error]) {
    return NO;
  }
  return [self _validateTabsWithError:error];
}

- (BOOL)validateForUpdate:(NSError *__autoreleasing *)error {
  if (![super validateForUpdate:error]) {
    return NO;
  }
  return [self _validateTabsWithError:error];
}

- (BOOL)validateValue:(__autoreleasing id *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)error {
  if (![super validateValue:value forKey:key error:error]) {
    return NO;
  }
  // Insert a single blank tab if there are no tabs in the value
  if ([key isEqualToString:@"tabs"] && [(NSOrderedSet *)(*value) count] == 0) {
    ArtCodeTab *blankTab = [ArtCodeTab insertInManagedObjectContext:self.managedObjectContext];
    blankTab.tabSet = self;
    *value = [NSOrderedSet orderedSetWithObject:blankTab];
  }
  return YES;
}

@end
