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
@protocol ACToolTarget <NSObject>

+ (id)newToolTargetController;

- (void)openURL:(NSURL *)url;

- (BOOL)shouldShowTabBar;
- (BOOL)shouldShowToolPanelController:(ACToolController *)toolController;

@optional

/// When implemented, this method will be called to apply a filter to the navigable.
/// A nil value can be passed to reset the filter.
- (void)applyFilter:(NSString *)filter;

// TODO add filterPlaceholder, thik how to do if placeholder has to be dynamic

@end
