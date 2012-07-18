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

#import "DocSet.h"
#import "DocSetDownloadManager.h"

#import <objc/runtime.h>


@implementation ArtCodeTab

- (ArtCodeLocation *)currentLocation {
  return [self.history objectAtIndex:self.currentPosition];
}

+ (NSSet *)keyPathsForValuesAffectingcurrentLocation {
  return [NSSet setWithObject:@"currentPosition"];
}

- (BOOL)canMoveBackInHistory {
  return self.currentPosition > 0;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveBackInHistory {
  return [NSSet setWithObject:@"currentPosition"];
}

- (BOOL)canMoveForwardInHistory {
  return self.currentPosition < (int16_t)self.history.count - 1;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveForwardInHistory {
  return [NSSet setWithObjects:@"currentPosition", @"history", nil];
}

- (void)pushLocation:(ArtCodeLocation *)location
{
  ASSERT(location && self.history.count); // Cannot be called on empty tab
  // Adding path to history and move forward
  int16_t lastPosition = self.history.count - 1;
  if (self.currentPosition < lastPosition) {
    NSRange rangeToDelete = NSMakeRange(self.currentPosition + 1, lastPosition - self.currentPosition);
    [[self mutableOrderedSetValueForKey:@"history"] removeObjectsInRange:rangeToDelete];
  }
  [self addHistoryObject:location];
  [self moveForwardInHistory];
}

- (void)moveBackInHistory {
  if (!self.canMoveBackInHistory) {
    return;
  }
  self.currentPosition = self.currentPosition - 1;
}

- (void)moveForwardInHistory
{
  if (!self.canMoveForwardInHistory) {
    return;
  }
  self.currentPosition = self.currentPosition + 1;
}

- (void)updateCurrentLocationWithLocation:(ArtCodeLocation *)location {
  [[self mutableOrderedSetValueForKey:@"history"] replaceObjectAtIndex:self.currentPosition withObject:location];
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
