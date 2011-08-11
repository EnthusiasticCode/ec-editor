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


@implementation ACToolPanelController {
    NSMutableDictionary *toolControllers;
    NSMutableArray *enabledToolControllers;
}

#pragma makr - Properties

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

#pragma mark - Managing Tools by Identifiers

@synthesize enabledToolControllerIdentifiers;

- (void)setEnabledToolControllerIdentifiers:(NSArray *)array
{
    // TODO filter array and check if in [toolControllers allKeys]
    
    enabledToolControllerIdentifiers = [array copy];
    
    if (enabledToolControllers == nil)
        enabledToolControllers = [NSMutableArray new];
    else
        [enabledToolControllers removeAllObjects];
    
    for (NSString *identifier in enabledToolControllerIdentifiers)
    {
        // TODO unload not enabled tool controllers
        id button = [toolControllers objectForKey:identifier];
        if (button == nil)
            continue;
        // Load the tool controller if a button is stored instead
        ACToolController *toolController = nil;
        if ([button isKindOfClass:[UIButton class]])
        {
            toolController = (ACToolController *)[self.storyboard instantiateViewControllerWithIdentifier:identifier];
            toolController.tabButton = button;
            [toolControllers setObject:toolController forKey:identifier];
            //
            __weak ACToolController *weakController = toolController;
            [button setActionBlock:^(id sender) {
                [self setSelectedViewController:weakController];
            } forControlEvent:UIControlEventTouchUpInside];
        }
        else
        {
            toolController = (ACToolController *)button;
        }
        //
        [enabledToolControllers addObject:toolController];
    }
    
    // Set the selected view, it will also load the actual panel controller view
    // and thus initialize the tabsView.
    if ([enabledToolControllers count] > 0 
        && ![enabledToolControllers containsObject:selectedViewController])
    {
        [self setSelectedViewController:[enabledToolControllers objectAtIndex:0]];
    }
    
    // Layout buttons
    [tabsView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect tabButtonFrame = CGRectMake(0, 0, 44, 44);
    for (ACToolController *toolController in enabledToolControllers)
    {
        [tabsView addSubview:toolController.tabButton];
        toolController.tabButton.frame = tabButtonFrame;
        tabButtonFrame.origin.x += 45;
    }
}

- (NSArray *)toolControllerIdentifiers
{
    return [toolControllers allKeys];
}

- (void)addToolWithIdentifier:(NSString *)toolControllerIdentifier
{
    NSString *tabImageName = [NSString stringWithFormat:@"toolPanel%@Image", toolControllerIdentifier];
    NSString *selectedImageName = [NSString stringWithFormat:@"toolPanel%@SelectedImage", toolControllerIdentifier];
    [self addToolWithIdentifier:toolControllerIdentifier tabImageName:tabImageName selectedTabImageName:selectedImageName];
}


- (void)addToolWithIdentifier:(NSString *)toolControllerIdentifier tabImageName:(NSString *)tabImageName selectedTabImageName:(NSString *)selectedImageName
{
    ECASSERT(toolControllerIdentifier != nil);
    ECASSERT(self.storyboard != nil);
    ECASSERT([toolControllers objectForKey:toolControllerIdentifier] == nil); // may only be added once
    
    // Create tab button
    UIButton *tabButton = [UIButton new];
    [tabButton setImage:[UIImage imageNamed:tabImageName] forState:UIControlStateNormal];
    [tabButton setImage:[UIImage imageNamed:selectedImageName] forState:UIControlStateSelected];
    
    // toolControllers will hold a button if the actual controller is not instantiated yet
    if (toolControllers == nil)
        toolControllers = [NSMutableDictionary new];
    [toolControllers setObject:tabButton forKey:toolControllerIdentifier];
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

#pragma mark - Managing Tools by Controller

@synthesize enabledToolControllers;

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
