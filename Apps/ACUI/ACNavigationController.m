//
//  ACNavigationController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ACNavigationController.h"
#import "AppStyle.h"


@implementation ACNavigationController
@synthesize contentScrollView;
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
    
    // TODO create internal views if not connected in IB
    
    // Setup present APIs to use this controller as reference.
    self.definesPresentationContext = YES;
    
    // Tools button
    [buttonTools setImage:[UIImage styleAddImageWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    buttonTools.adjustsImageWhenHighlighted = NO;
    
    // Setup jumpbar
    jumpBar.delegate = self;
    
    // Setup tab bar
    if (!tabBar)
        tabBar = [[ECTabBar alloc] initWithFrame:CGRectMake(0, 45, self.view.bounds.size.width, 44)];
    tabBar.delegate = self;
    tabBar.alwaysBounceHorizontal = YES;
    tabBar.backgroundColor = [UIColor styleForegroundColor];
    tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    UIButton *addTabButton = [UIButton new];
    [addTabButton setImage:[UIImage styleAddImageWithColor:[UIColor styleBackgroundColor] shadowColor:nil] forState:UIControlStateNormal];
    addTabButton.adjustsImageWhenHighlighted = NO;
    
    UIButton *closeTabBarButton = [UIButton new];
    [closeTabBarButton addTarget:self action:@selector(toggleTabBar:) forControlEvents:UIControlEventTouchUpInside];
    [closeTabBarButton setImage:[UIImage styleDisclosureArrowImageWithOrientation:UIImageOrientationUp color:[UIColor styleBackgroundColor]] forState:UIControlStateNormal];
    closeTabBarButton.adjustsImageWhenHighlighted = NO;

    tabBar.additionalControls = [NSArray arrayWithObjects:addTabButton, closeTabBarButton, nil];
    
    [tabBar addTabButtonWithTitle:@"One" animated:NO];
    [tabBar addTabButtonWithTitle:@"Two" animated:NO];
    [tabBar addTabButtonWithTitle:@"Three" animated:NO];
    [tabBar addTabButtonWithTitle:@"Four" animated:NO];
    
    // Tab gesture recognizer
    tabGestureRecognizer = [[ECSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleTabBar:)];
    tabGestureRecognizer.numberOfTouchesRequired = 3;
    tabGestureRecognizer.numberOfTouchesRequiredImmediatlyOrFailAfterInterval = .05;
    tabGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:tabGestureRecognizer];
    
    // Setup content scroll view
    contentScrollView.pagingEnabled = YES;
    contentScrollView.showsVerticalScrollIndicator = NO;
    contentScrollView.showsHorizontalScrollIndicator = NO;
}

- (void)viewDidUnload
{
    [self setJumpBar:nil];
    [self setTabBar:nil];
    tabGestureRecognizer = nil;
    [self setContentScrollView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Navigation Methods

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // Customize view controller's view's gesture recognizers
    if ([viewController.view isKindOfClass:[UIScrollView class]])
    {
        UIScrollView *scrollView = (UIScrollView *)viewController.view;
        [scrollView.panGestureRecognizer requireGestureRecognizerToFail:tabGestureRecognizer];
    }
    
    UIViewController *topViewController = [self.childViewControllers lastObject];
    [self addChildViewController:viewController];
    if (animated && topViewController)
    {
        [contentScrollView addSubview:viewController.view];
        viewController.view.frame = contentScrollView.bounds;
        viewController.view.alpha = 0;
        [UIView animateWithDuration:0.25 animations:^(void) {
            topViewController.view.alpha = 0;
            viewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [topViewController.view removeFromSuperview];
            [viewController didMoveToParentViewController:self];            
        }];
    }
    else
    {
        [topViewController.view removeFromSuperview];
        [contentScrollView addSubview:viewController.view];
        viewController.view.frame = contentScrollView.bounds;
        [viewController didMoveToParentViewController:self];
    }
    
    // Jump bar
}
//- (void)viewWillLayoutSubviews check this out
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{    
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
        [contentScrollView addSubview:viewController.view];
        viewController.view.frame = contentScrollView.bounds;
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

#pragma mark -

- (void)toggleTabBar:(id)sender
{    
    CGRect contentScrollViewFrame = contentScrollView.frame;
    CGRect tabBarFrame = CGRectMake(0, 45, contentScrollViewFrame.size.width, 44);
    if ([tabBar superview] != nil)
    {
        contentScrollViewFrame.size.height += tabBarFrame.size.height;
        contentScrollViewFrame.origin.y -= tabBarFrame.size.height;
        tabBarFrame.size.height = 0;
        [UIView animateWithDuration:.1 animations:^(void) {
            // TODO fix layout problems of tab buttons during animation?
            tabBar.frame = tabBarFrame;
            contentScrollView.frame = contentScrollViewFrame;
        } completion:^(BOOL finished) {
            [tabBar removeFromSuperview];
        }];
    }
    else
    {
        tabBarFrame.size.height = 0;
        tabBar.frame = tabBarFrame;
        tabBarFrame.size.height = 44;
        
        [self.view addSubview:tabBar];
        contentScrollViewFrame.size.height -= tabBarFrame.size.height;
        contentScrollViewFrame.origin.y += tabBarFrame.size.height;
        [UIView animateWithDuration:.1 animations:^(void) {
            tabBar.frame = tabBarFrame;
            contentScrollView.frame = contentScrollViewFrame;
        }];
    }
}

- (void)closeTabButtonAction:(id)sender
{
    NSUInteger tabIndex = [tabBar indexOfTab:(UIButton *)[sender superview]];
    [tabBar removeTabAtIndex:tabIndex animated:YES];
    
    // TODO also remove controller
}

#pragma mark - JumpBar Delegate Methods

- (void)popJumpBar:(id)sender
{
    [jumpBar popJumpElementAnimated:YES];
}

- (UIView *)jumpBar:(ECJumpBar *)jumpBar createElementForJumpPathComponent:(NSString *)pathComponent index:(NSUInteger)componentIndex
{
    UIButton *button = [UIButton new];
    [button setTitle:pathComponent forState:UIControlStateNormal];
    
    [button addTarget:self action:@selector(popJumpBar:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (NSString *)jumpBar:(ECJumpBar *)jumpBar pathComponentForJumpElement:(UIView *)jumpElement index:(NSUInteger)elementIndex
{
    return [(UIButton *)jumpElement currentTitle];
}

#pragma mark -

- (IBAction)tests:(id)sender {
    NSString *title = [NSString stringWithFormat:@"Path %u", [jumpBar.jumpElements count]];
    [jumpBar pushJumpElementsForPath:title animated:YES];
}


@end
