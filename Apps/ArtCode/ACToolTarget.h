//
//  ACToolTarget.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACToolController;

@protocol ACToolTarget <NSObject>

- (void)openURL:(NSURL *)url;

- (BOOL)shouldShowTabBar;
- (BOOL)shouldShowToolPanelController:(ACToolController *)toolController;

@optional

/// When implemented, this method will be called to apply a filter to the navigable.
/// A nil value can be passed to reset the filter.
- (void)applyFilter:(NSString *)filter;

@end
