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

@property (nonatomic, strong) ACTab *tab;
@property (nonatomic, weak) UIPopoverController *popoverController;

@end


@interface UIViewController (ACQuickBrowsersContainerController)

@property (nonatomic, strong, readonly) ACQuickBrowsersContainerController *quickBrowsersContainerController;

@end