//
//  QuickBrowsersContainerController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+PresentingPopoverController.h"

@class ArtCodeTab;


@interface QuickBrowsersContainerController : UITabBarController

+ (id)defaultQuickBrowsersContainerControllerForContentController:(UIViewController *)contentController;

/// The controller that requested the presentation of this quick browser.
@property (nonatomic, weak) UIViewController *contentController;

/// The button from which the quick browser was presented.
@property (nonatomic, weak) UIButton *openingButton;

@end


@interface UIViewController (QuickBrowsersContainerController)

@property (nonatomic, strong, readonly) QuickBrowsersContainerController *quickBrowsersContainerController;

@end