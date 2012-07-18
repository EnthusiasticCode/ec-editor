//
//  ArtCodeTab.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Tab.h"

@class ArtCodeProject, DocSet, DirectoryPresenter, ArtCodeLocation;

extern NSString * const ArtCodeTabDidChangeAllTabsNotification;

@interface ArtCodeTab : Tab

#pragma mark Tab attributes

@property (nonatomic, readonly, getter = isLoading) BOOL loading;

@property (nonatomic, strong, readonly) NSArray *historyURLs;

@property (nonatomic, readonly) NSUInteger tabIndex;

/// Remove the tab from the system tabs
- (void)remove;

#pragma mark Current state

@property (nonatomic) NSUInteger currentHistoryPosition;

/// The current URL the tab history is pointing at. This property is read only.
/// To change the current URL use one of the move methods or pushURL.
@property (nonatomic, strong, readonly) ArtCodeLocation *currentLocation;

/// The current project for the tab's URL.
@property (nonatomic, strong, readonly) ArtCodeProject *currentProject;

/// Access to the current URL docset if any.
@property (nonatomic, strong, readonly) DocSet *currentDocSet;

#pragma mark History management

/// A value indicating if calling moveBackInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveBackInHistory;

/// A value indicating if calling moveForwardInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveForwardInHistory;

/// Pushes an URL to the tab's history.
/// Changes the current url to the newly pushed url, and deletes any history items following the previously current one
- (void)pushLocation:(ArtCodeLocation *)url;

/// Convinience method that moves the tab's history back by one step.
/// KVO attached to currentLocation will be notified after this method is called.
- (void)moveBackInHistory;

/// Convinience method that moves the tab's history forward by one step.
/// KVO attached to currentLocation will be notified after this method is called.
- (void)moveForwardInHistory;

/// Updates the current location with the given one. 
/// This method can be used to change some properties of the current location 
/// without leaving traces in the history.
- (void)updateCurrentLocationWithLocation:(ArtCodeLocation *)location;

@end


@interface UIViewController (ArtCodeTab)

/// Retrieve the ArtCode Tab that the view controller is in.
/// This methods try to retrieve the tab recursively on the receiver's parent view controller.
@property (nonatomic, strong) ArtCodeTab *artCodeTab;

@end
