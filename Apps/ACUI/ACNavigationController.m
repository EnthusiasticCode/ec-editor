//
//  ACNavigationController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNavigationController.h"
#import "AppStyle.h"


@implementation ACNavigationController
@synthesize tabBar;

#pragma mark - Properties

@synthesize jumpBar, buttonEdit, buttonTools;

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        popoverController = [ECPopoverController new];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Setup present APIs to use this controller as reference.
    self.definesPresentationContext = YES;
    
    // Tools button
    [buttonTools setImage:[UIImage styleAddImage] forState:UIControlStateNormal];
    buttonTools.adjustsImageWhenHighlighted = NO;
    
    // Setup jumpbar
    jumpBar.delegate = self;
    [jumpBar setFont:[UIFont styleFontWithSize:14]];
    [jumpBar setTextColor:[UIColor styleForegroundColor]];
    [jumpBar setTextShadowColor:[UIColor styleForegroundShadowColor]];
    [jumpBar setTextShadowOffset:CGSizeMake(0, 1)];
    
    [jumpBar setButtonColor:[UIColor styleBackgroundColor]];
    [jumpBar setButtonHighlightColor:[UIColor styleHighlightColor]];
    
    [jumpBar setSearchString:@"Projects"];
    
    // Setup tab bar
    tabBar.delegate = self;
    tabBar.backgroundColor = [UIColor styleForegroundColor];
    
    UIButton *addTabButton = [UIButton new];
    [addTabButton setTitle:@"+" forState:UIControlStateNormal];
    
    UIButton *closeTabBarButton = [UIButton new];
    [closeTabBarButton setTitle:@"^" forState:UIControlStateNormal];

    tabBar.additionalControls = [NSArray arrayWithObjects:addTabButton, closeTabBarButton, nil];
    
    [tabBar addTabButtonWithTitle:@"One" animated:NO];
    [tabBar addTabButtonWithTitle:@"Two" animated:NO];
    [tabBar addTabButtonWithTitle:@"Three" animated:NO];

}

- (void)viewDidUnload
{
    [self setJumpBar:nil];
    [self setTabBar:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Navigation Methods

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    CGRect viewFrame = self.view.bounds;
    viewFrame.origin.y += 100;
    viewFrame.size.height -= 100;
    
    UIViewController *topViewController = [self.childViewControllers lastObject];
    [self addChildViewController:viewController];
    if (animated)
    {
        [self transitionFromViewController:topViewController 
                          toViewController:viewController 
                                  duration:1 
                                   options:UIViewAnimationOptionTransitionNone 
                                animations:nil completion:^(BOOL finished) {
                                    [viewController didMoveToParentViewController:self];
                                }];
    }
    else
    {
        // TODO souldn't be used like this?
        [topViewController.view removeFromSuperview];
        [self.view addSubview:viewController.view];
        viewController.view.frame = viewFrame;
        [viewController didMoveToParentViewController:self];
    }
}
//- (void)viewWillLayoutSubviews check this out
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    CGRect viewFrame = self.view.bounds;
    viewFrame.origin.y += 44;
    viewFrame.size.height -= 44;
    
    NSUInteger childViewControllersCount = [self.childViewControllers count];
    if (childViewControllersCount < 2)
        return nil;
    
    UIViewController *topViewController = [self.childViewControllers lastObject];
    UIViewController *viewController = [self.childViewControllers objectAtIndex:childViewControllersCount - 2];
    [viewController willMoveToParentViewController:self];
    if (animated)
    {
        [self transitionFromViewController:topViewController toViewController:viewController duration:1 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
            // ???
        } completion:^(BOOL finished) {
            [topViewController removeFromParentViewController];
        }];
    }
    else
    {
        [self.view addSubview:viewController.view];
        viewController.view.frame = viewFrame;
        [topViewController removeFromParentViewController];
    }
    return topViewController;
}

#pragma mark - Bar Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    buttonEdit.selected = editing;
    
    [[self.childViewControllers lastObject] setEditing:editing animated:animated];
}

- (IBAction)toggleTools:(id)sender
{
//    if (!popoverController)
//        popoverController = [ECPopoverController new];
}

- (IBAction)toggleEditing:(id)sender
{
    BOOL editing = !self.isEditing;
    [self setEditing:editing animated:YES];
}

#pragma mark - TabBarDelegate Methods Implementation

- (void)closeTabButtonAction:(id)sender
{
    NSUInteger tabIndex = [tabBar indexOfTab:(UIButton *)[sender superview]];
    [tabBar removeTabAtIndex:tabIndex animated:YES];
    
    // TODO also remove controller
}

- (BOOL)tabBar:(ECTabBar *)tabBar willAddTabButton:(UIButton *)tabButton atIndex:(NSUInteger)tabIndex
{    
    UIButton *closeButton = [UIButton new];
    CGRect frame = tabButton.bounds;
    frame.origin.x = frame.size.width - 35;
    frame.size.width = 35;
    closeButton.frame = frame;
    [closeButton addTarget:self action:@selector(closeTabButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [tabButton addSubview:closeButton];
    
    // TODO no appearance proxy for this?
    [tabButton.titleLabel setFont:[UIFont styleFontWithSize:14]];
    return YES;
}

@end
