//
//  ACQuickBrowsersContainerController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTab;


@interface ACQuickBrowsersContainerController : UITabBarController

+ (id)quickBrowsersContainerControllerForTab:(ACTab *)tab;

@property (nonatomic, strong) ACTab *tab;
@property (nonatomic, weak) UIPopoverController *popoverController;
@property (nonatomic, weak) UIButton *openingButton;

@end


@interface UIViewController (ACQuickBrowsersContainerController)

@property (nonatomic, strong, readonly) ACQuickBrowsersContainerController *quickBrowsersContainerController;

@end