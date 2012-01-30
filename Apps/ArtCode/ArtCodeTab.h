//
//  ArtCodeTab.h
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Application, HistoryItem, ArtCodeProject;

@interface ArtCodeTab : NSManagedObject

@property (nonatomic) int16_t currentHistoryPosition;
@property (nonatomic, strong) Application *application;
@property (nonatomic, strong) NSOrderedSet *historyItems;

/// The current URL the tab history is pointing at. This property is read only.
/// To change the current URL use one of the move methods or pushURL.
@property (nonatomic, strong, readonly) NSURL *currentURL;

/// The current project the currentURL is pointing at.
@property (nonatomic, strong, readonly) ArtCodeProject *currentProject;

/// Pushes an URL to the tab's history.
/// Changes the current url to the newly pushed url, and deletes any history items following the previously current one
- (void)pushURL:(NSURL *)url;

/// A value indicating if calling moveBackInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveBackInHistory;

/// A value indicating if calling moveForwardInHistory will have any effect.
@property (nonatomic, readonly) BOOL canMoveForwardInHistory;

/// Convinience method that moves the tab's history back by one step.
/// KVO attached to currentURL will be notified after this method is called.
- (void)moveBackInHistory;

/// Convinience method that moves the tab's history forward by one step.
/// KVO attached to currentURL will be notified after this method is called.
- (void)moveForwardInHistory;

@end
