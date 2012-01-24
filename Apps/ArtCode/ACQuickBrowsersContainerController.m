//
//  ACQuickBrowsersContainerController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACQuickBrowsersContainerController.h"

@implementation ACQuickBrowsersContainerController

@synthesize tab, popoverController;

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end


@implementation UIViewController (ACQuickBrowsersContainerController)

- (ACQuickBrowsersContainerController *)quickBrowsersContainerController
{
    return (ACQuickBrowsersContainerController *)self.parentViewController;
}

@end