//
//  Tab.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"
#import "ArtCodeLocation.h"

#import "DocSet.h"
#import "DocSetDownloadManager.h"

#import <objc/runtime.h>


@implementation ArtCodeTab

- (ArtCodeLocation *)currentLocation {
  return [self.history objectAtIndex:self.currentPositionValue];
}

+ (NSSet *)keyPathsForValuesAffectingcurrentLocation {
  return [NSSet setWithObject:@"currentPositionValue"];
}

- (BOOL)canMoveBackInHistory {
  return self.currentPositionValue > 0;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveBackInHistory {
  return [NSSet setWithObject:@"currentPositionValue"];
}

- (BOOL)canMoveForwardInHistory {
  return self.currentPositionValue < (int16_t)self.history.count - 1;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveForwardInHistory {
  return [NSSet setWithObjects:@"currentPositionValue", @"history", nil];
}

- (void)moveBackInHistory {
  if (!self.canMoveBackInHistory) {
    return;
  }
  self.currentPositionValue = self.currentPositionValue - 1;
}

- (void)moveForwardInHistory
{
  if (!self.canMoveForwardInHistory) {
    return;
  }
  self.currentPositionValue = self.currentPositionValue + 1;
}

#pragma mark - Validation

- (BOOL)_validateHistoryWithError:(NSError *__autoreleasing *)error {
  // Validates history and create an initial location if neccessary
  NSOrderedSet *oldHistory = self.history;
  NSOrderedSet *newHistory = oldHistory;
  if (![self validateValue:&newHistory forKey:@"history" error:error]) {
    return NO;
  }
  if (newHistory != oldHistory) {
    self.history = newHistory;
  }
  return YES;
}

- (BOOL)validateForInsert:(NSError *__autoreleasing *)error {
  if (![super validateForInsert:error]) {
    return NO;
  }
  return [self _validateHistoryWithError:error];
}

- (BOOL)validateForUpdate:(NSError *__autoreleasing *)error {
  if (![super validateForUpdate:error]) {
    return NO;
  }
  return [self _validateHistoryWithError:error];  
}

- (BOOL)validateValue:(__autoreleasing id *)value forKey:(NSString *)key error:(NSError *__autoreleasing *)error {
  if (![super validateValue:value forKey:key error:error]) {
    return NO;
  }
  // History should have at least one element pointing to the projects list location
  if ([key isEqualToString:@"history"] && [(NSOrderedSet *)(*value) count] == 0) {
    ArtCodeLocation *location = [ArtCodeLocation insertInManagedObjectContext:self.managedObjectContext];
    location.type = ArtCodeLocationTypeProjectsList;
    location.tab = self;
    *value = [NSOrderedSet orderedSetWithObject:location];
  }
  return YES;
}

#pragma mark - ArtCodeLocation

- (void)pushLocation:(ArtCodeLocation *)location
{
  ASSERT(location && self.history.count); // Cannot be called on empty tab
  // Adding path to history and move forward
  int16_t lastPosition = self.history.count - 1;
  if (self.currentPositionValue < lastPosition) {
    NSRange rangeToDelete = NSMakeRange(self.currentPositionValue + 1, lastPosition - self.currentPositionValue);
    [[self mutableOrderedSetValueForKey:@"history"] removeObjectsInRange:rangeToDelete];
  }
  [self addHistoryObject:location];
  [self moveForwardInHistory];
}

- (void)updateCurrentLocationWithLocation:(ArtCodeLocation *)location {
  [[self mutableOrderedSetValueForKey:@"history"] replaceObjectAtIndex:self.currentPositionValue withObject:location];
}

@end

#pragma mark

@implementation UIViewController (ArtCodeTab)

static void *artCodeTabKey;

- (ArtCodeTab *)artCodeTab {
  ArtCodeTab *tab = objc_getAssociatedObject(self, &artCodeTabKey);
  if (tab) {
    return tab;
  }
  
  UIViewController *controller = self;
  do {
    controller = controller.parentViewController;
    tab = objc_getAssociatedObject(controller, &artCodeTabKey);
  } while (tab == nil && controller != nil);
  return tab;
}

- (void)setArtCodeTab:(ArtCodeTab *)artCodeTab {
  objc_setAssociatedObject(self, &artCodeTabKey, artCodeTab, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
