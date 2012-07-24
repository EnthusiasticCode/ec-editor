//
//  ArtCodeTab.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "_ArtCodeTab.h"

@class ArtCodeLocation;


@interface ArtCodeTab : _ArtCodeTab

/// The current URL the tab history is pointing at. This property is read only.
/// To change the current URL use one of the move methods or pushURL.
@property (nonatomic, strong, readonly) ArtCodeLocation *currentLocation;

/// A value indicating if calling moveBackInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveBackInHistory;

/// A value indicating if calling moveForwardInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveForwardInHistory;

/// Convinience method that moves the tab's history back by one step.
/// KVO attached to currentLocation will be notified after this method is called.
- (void)moveBackInHistory;

/// Convinience method that moves the tab's history forward by one step.
/// KVO attached to currentLocation will be notified after this method is called.
- (void)moveForwardInHistory;

@end


@interface UIViewController (ArtCodeTab)

/// Retrieve the ArtCode Tab that the view controller is in.
/// This methods try to retrieve the tab recursively on the receiver's parent view controller.
@property (nonatomic, strong) ArtCodeTab *artCodeTab;

@end
