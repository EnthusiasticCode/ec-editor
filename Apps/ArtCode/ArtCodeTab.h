//
//  ArtCodeTab.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArtCodeProject, DocSet, DirectoryPresenter, ArtCodeLocation;

extern NSString * const ArtCodeTabDidChangeAllTabsNotification;

@interface ArtCodeTab : NSObject

/// Get an array of all tabs ordered as they shoyld be displayed
+ (NSArray *)allTabs;

+ (void)insertTab:(ArtCodeTab *)tab atIndex:(NSUInteger)index;
+ (void)moveTabAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
+ (void)removeTabAtIndex:(NSUInteger)tabIndex;

/// Get or set the current selected tab index that will be persisted.
+ (NSUInteger)currentTabIndex;
+ (void)setCurrentTabIndex:(NSUInteger)currentTabIndex;

// TODO this methods should not automatically modify the allTabs array
/// Generate a new tab without any URL in it's history
+ (ArtCodeTab *)blankTab;
+ (ArtCodeTab *)duplicateTab:(ArtCodeTab *)tab;

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
