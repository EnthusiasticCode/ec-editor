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

+ (id)defaultQuickBrowsersContainerControllerForTab:(ArtCodeTab *)tab;

@property (nonatomic, weak) UIButton *openingButton;

- (id)initWithTab:(ArtCodeTab *)tab;

@end


@interface UIViewController (QuickBrowsersContainerController)

@property (nonatomic, strong, readonly) QuickBrowsersContainerController *quickBrowsersContainerController;

@end