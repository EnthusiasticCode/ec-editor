//
//  ACURLEnabledProtocol.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 16/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ACToolController;

// TODO use ACURL instead of NSURL?
@protocol ACNavigable <NSObject>
@required

- (BOOL)canOpenURL:(NSURL *)url;
- (void)openURL:(NSURL *)url;

- (BOOL)shouldShowTabBar;
- (BOOL)shouldShowToolPanelController:(ACToolController *)toolController;

@optional

/// When implemented, this method will be called to apply a filter to the navigable.
/// A nil value can be passed to reset the filter.
- (void)applyFilter:(NSString *)filter;

@end
