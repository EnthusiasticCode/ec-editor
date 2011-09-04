//
//  ACToolTarget.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACToolController;

// TODO rename/rework this protocol
// TODO integrate in navigation controller didChangeCurrentTabController..
@protocol ACNavigationTarget <NSObject>
@required

/// When implemented, create a new view controller that responds to the protocol methods.
+ (id)newNavigationTargetController;

/// Makes the target open the given URL.
- (void)openURL:(NSURL *)url;

/// Indicates if the tab bar can be displayed when the target is in foreground.
- (BOOL)enableTabBar;

/// Indicates if the tool controller with the given identifier should be enabled 
/// when the target is in foreground.
- (BOOL)enableToolPanelControllerWithIdentifier:(NSString *)toolControllerIdentifier;

@optional

/// When implemented, this method will be called to apply a filter to the navigable.
/// A nil value can be passed to reset the filter.
- (void)applyFilter:(NSString *)filter;

// TODO add filterPlaceholder, thik how to do if placeholder has to be dynamic

- (void)toolButtonAction:(id)sender;

/// Used to indicate that the controller should make every scrolling view to require
/// the given recognizer to fail.
- (void)setScrollToRequireGestureRecognizerToFail:(UIGestureRecognizer *)recognizer;

@end
