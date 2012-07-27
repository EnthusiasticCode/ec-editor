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

+ (BOOL)automaticallyNotifiesObserversOfCurrentLocation {
  return NO;
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
  [self willChangeValueForKey:@"currentLocation"];
  self.currentPositionValue = self.currentPositionValue - 1;
  [self didChangeValueForKey:@"currentLocation"];
}

- (void)moveForwardInHistory
{
  if (!self.canMoveForwardInHistory) {
    return;
  }
  [self willChangeValueForKey:@"currentLocation"];
  self.currentPositionValue = self.currentPositionValue + 1;
  [self didChangeValueForKey:@"currentLocation"];
}

- (void)awakeFromInsert {
  [super awakeFromInsert];
  ArtCodeLocation *location = [ArtCodeLocation insertInManagedObjectContext:self.managedObjectContext];
  location.type = ArtCodeLocationTypeProjectsList;
  location.tab = self;
}

#pragma mark - ArtCodeLocation

- (void)pushLocation:(ArtCodeLocation *)location
{
  ASSERT(location && self.history.count); // Cannot be called on empty tab
  // Adding path to history and move forward
  int16_t lastPosition = self.history.count - 1;
  if (self.currentPositionValue < lastPosition) {
    NSRange rangeToDelete = NSMakeRange(self.currentPositionValue + 1, lastPosition - self.currentPositionValue);
    [[self historySet] removeObjectsInRange:rangeToDelete];
  }
  [[self historySet] addObject:location];
  [self moveForwardInHistory];
}

- (void)replaceCurrentLocationWithLocation:(ArtCodeLocation *)location {
  [self willChangeValueForKey:@"currentLocation"];
  ArtCodeLocation *oldLocation = self.currentLocation;
  [[self historySet] replaceObjectAtIndex:self.currentPositionValue withObject:location];
  [oldLocation.managedObjectContext deleteObject:oldLocation];
  [self didChangeValueForKey:@"currentLocation"];
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
