//
//  ArtCodeTab.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Application, ACProject, ACProjectItem;

@interface ArtCodeTab : NSObject

+ (NSArray *)allTabs;
+ (ArtCodeTab *)blankTab;
+ (ArtCodeTab *)duplicateTab:(ArtCodeTab *)tab;
+ (void)removeTab:(ArtCodeTab *)tab;
+ (void)saveTabsToDisk;

@property (nonatomic, readonly, getter = isLoading) BOOL loading;

@property (nonatomic, strong, readonly) NSArray *historyURLs;

@property (nonatomic) NSUInteger currentHistoryPosition;

/// The current URL the tab history is pointing at. This property is read only.
/// To change the current URL use one of the move methods or pushURL.
@property (nonatomic, strong, readonly) NSURL *currentURL;

/// The current project for the tab's URL.
@property (nonatomic, strong, readonly) ACProject *currentProject;

/// The current project item for the tab's URL.
@property (nonatomic, strong, readonly) ACProjectItem *currentItem;

/// A value indicating if calling moveBackInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveBackInHistory;

/// A value indicating if calling moveForwardInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveForwardInHistory;

/// Pushes an URL to the tab's history.
/// Changes the current url to the newly pushed url, and deletes any history items following the previously current one
- (void)pushURL:(NSURL *)url;

/// Convinience method that moves the tab's history back by one step.
/// KVO attached to currentURL will be notified after this method is called.
- (void)moveBackInHistory;

/// Convinience method that moves the tab's history forward by one step.
/// KVO attached to currentURL will be notified after this method is called.
- (void)moveForwardInHistory;

@end


@interface UIViewController (ArtCodeTab)

/// Retrieve the ArtCode Tab that the view controller is in.
/// This methods try to retrieve the tab recursively on the receiver's parent view controller.
@property (nonatomic, weak) ArtCodeTab *artCodeTab;

@end
