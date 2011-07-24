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
#import "UIControl+BlockAction.h"


@implementation ACToolPanelController

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
    
    //
//    [self performSegueWithIdentifier:@"rootSegue" sender:[tabsView.subviews objectAtIndex:0]];
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

- (void)addToolWithController:(ACToolController *)toolController tabImage:(UIImage *)tabImage selectedTabImage:(UIImage *)selectedImage
{
    [super addChildViewController:toolController];
    
    UIButton *tabButton = [UIButton new];
    [tabButton setImage:tabImage forState:UIControlStateNormal];
    [tabButton setImage:selectedImage forState:UIControlStateSelected];
    toolController.tabButton = tabButton;
    
    [tabButton setActionBlock:^(id sender) {
        [self setSelectedViewController:toolController animated:YES];
    } forControlEvent:UIControlEventTouchUpInside];
}

#pragma mark - Tabs Management

- (void)updateTabs
{
    NSMutableArray *visibleTabControllers = [[NSMutableArray alloc] initWithCapacity:[self.childViewControllers count]];
    for (ACToolController *toolController in self.childViewControllers)
    {
        if (toolController.isEnabled)
        {
            [visibleTabControllers addObject:toolController];
        }
        else
        {
            [toolController.tabButton removeFromSuperview];
        }
    }
    
    // Set the selected view, it will also load the actual panel controller view
    // and thus initialize the tabsView.
    if ([visibleTabControllers count] > 0 
        && ![visibleTabControllers containsObject:selectedViewController])
    {
        [self setSelectedViewController:[visibleTabControllers objectAtIndex:0]];
    }
    
    CGRect tabButtonFrame = CGRectMake(0, 0, 44, 44);
    for (ACToolController *toolController in visibleTabControllers)
    {
        [tabsView addSubview:toolController.tabButton];
        toolController.tabButton.frame = tabButtonFrame;
        tabButtonFrame.origin.x += 45;
    }
}

#pragma mark - Segue Management

- (void)setSelectedViewController:(ACToolController *)controller
{
    [self setSelectedViewController:controller animated:NO];
}

- (void)setSelectedViewController:(ACToolController *)controller animated:(BOOL)animated
{
    // Do nothing if already selected
    if (controller == selectedViewController)
        return;
    
    // Deselect button
    selectedViewController.tabButton.selected = NO;
    selectedViewController.tabButton.backgroundColor = [UIColor clearColor];
    
    // Add controller if not present in child controllers
    [self addChildViewController:controller];
    
    // Calculate controller's size
    CGRect controllerViewFrame = self.view.bounds;
    CGFloat tabsHeight = CGRectGetMaxY(self.tabsView.frame);
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
            
            // Select button
            selectedViewController.tabButton.selected = YES;
            selectedViewController.tabButton.backgroundColor = [UIColor styleBackgroundColor];
        }];
    }
    else
    {
        [selectedViewController.view removeFromSuperview];
        selectedViewController = controller;
        selectedViewController.view.frame = controllerViewFrame;
        [self.view addSubview:selectedViewController.view];
        
        // Select button
        selectedViewController.tabButton.selected = YES;
        selectedViewController.tabButton.backgroundColor = [UIColor styleBackgroundColor];
    }
}

@end
