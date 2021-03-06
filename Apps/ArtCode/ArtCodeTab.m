//
//  Tab.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeTab.h"

#import <objc/runtime.h>
#import "ArtCodeLocation.h"

@implementation ArtCodeTab

- (ArtCodeLocation *)currentLocation {
  if (self.currentPositionValue + 1 > (int16_t)self.history.count) return nil;
  return (self.history)[self.currentPositionValue];
}

+ (NSSet *)keyPathsForValuesAffectingCurrentLocation {
  return [NSSet setWithObjects:@"currentPosition", @"history", nil];
}

- (BOOL)canMoveBackInHistory {
  return self.currentPositionValue > 0;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveBackInHistory {
  return [NSSet setWithObject:@"currentPosition"];
}

- (BOOL)canMoveForwardInHistory {
  return self.currentPositionValue < (int16_t)self.history.count - 1;
}

+ (NSSet *)keyPathsForValuesAffectingCanMoveForwardInHistory {
  return [NSSet setWithObjects:@"currentPosition", @"history", nil];
}

- (void)moveBackInHistory {
  if (!self.canMoveBackInHistory) return;
  self.currentPositionValue = self.currentPositionValue - 1;
}

- (void)moveForwardInHistory {
  if (!self.canMoveForwardInHistory) return;
  self.currentPositionValue = self.currentPositionValue + 1;
}

- (void)awakeFromInsert {
  [super awakeFromInsert];
	[self pushLocationWithDictionary:@{ ArtCodeLocationAttributeKeys.type: @(ArtCodeLocationTypeProjectsList) }];
}

#pragma mark - ArtCodeLocation

- (void)pushLocation:(ArtCodeLocation *)location {
  ASSERT(location);
	// If the tab is empty just add the location, no need to do anything else
	if (self.history.count == 0) {
		[self.historySet addObject:location];
		return;
	}
  // Remove locations between the current position and the end of the history
  int16_t lastPosition = self.history.count - 1;
  if (self.currentPositionValue < lastPosition) {
    NSRange rangeToDelete = NSMakeRange(self.currentPositionValue + 1, lastPosition - self.currentPositionValue);
    NSArray *locationsToDelete = [self.history objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rangeToDelete]];
    [self.historySet removeObjectsInRange:rangeToDelete];
    for (ArtCodeLocation *loc in locationsToDelete) {
      [self.managedObjectContext deleteObject:loc];
    }
  }
  // Adding path to history and move forward
  [self.historySet addObject:location];
  [self moveForwardInHistory];
}

- (void)replaceCurrentLocationWithLocation:(ArtCodeLocation *)location {
  ArtCodeLocation *oldLocation = self.currentLocation;
  self.historySet[self.currentPositionValue] = location;
  [oldLocation.managedObjectContext deleteObject:oldLocation];
}

@end

#pragma mark

@implementation UIViewController (ArtCodeTab)

static void *artCodeTabKey;

- (ArtCodeTab *)artCodeTab {
  return objc_getAssociatedObject(self, &artCodeTabKey);
}

- (void)setArtCodeTab:(ArtCodeTab *)artCodeTab {
  objc_setAssociatedObject(self, &artCodeTabKey, artCodeTab, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
