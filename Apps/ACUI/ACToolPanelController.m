//
//  ACToolPanelController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACToolPanelController.h"
#import "AppStyle.h"
#import <QuartzCore/QuartzCore.h>


@implementation ACToolPanelController {
    UIButton *selectedTabButton;
}

@synthesize tabsView;
@synthesize selectedViewController;

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO make this more efficient
    CALayer *viewLayer = self.view.layer;
    viewLayer.cornerRadius = 4;
    viewLayer.borderWidth = 2;
    viewLayer.borderColor = [UIColor styleBackgroundColor].CGColor;
    
    //
    viewLayer = tabsView.layer;
    viewLayer.borderColor = [UIColor styleBackgroundColor].CGColor;
    viewLayer.borderWidth = 1;
}

- (void)viewDidUnload
{
    [self setTabsView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Segue Management

- (void)setSelectedViewController:(UIViewController *)controller
{
    [self setSelectedViewController:controller animated:NO];
}

- (void)setSelectedViewController:(UIViewController *)controller animated:(BOOL)animated
{
    // Add controller if not present in child controllers
    [self addChildViewController:controller];
    
    // Calculate controller's size
    CGFloat tabsHeight = CGRectGetMaxY(self.tabsView.frame);
    CGRect controllerViewFrame = self.view.bounds;
    controllerViewFrame.origin.y = tabsHeight;
    controllerViewFrame.size.height -= tabsHeight;
    
    // Insert controller's view
    if (animated)
    {
        controller.view.frame = controllerViewFrame;
        if (!selectedViewController)
            [self.view addSubview:controller.view];
        [UIView transitionFromView:selectedViewController.view toView:controller.view duration:0.15 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
            selectedViewController = controller;
        }];
    }
    else
    {
        [selectedViewController.view removeFromSuperview];
        selectedViewController = controller;
        selectedViewController.view.frame = controllerViewFrame;
        [self.view addSubview:selectedViewController.view];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    selectedTabButton.selected = NO;
    selectedTabButton.backgroundColor = [UIColor clearColor];
    
    selectedTabButton = sender;
    selectedTabButton.selected = YES;
    selectedTabButton.backgroundColor = [UIColor styleBackgroundColor];
}

@end
