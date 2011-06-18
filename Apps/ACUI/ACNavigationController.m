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
    
    // Setup jumpbar
    jumpBar.delegate = self;
    [jumpBar setFont:[UIFont styleFontWithSize:14]];
    [jumpBar setTextColor:[UIColor styleForegroundColor]];
    [jumpBar setTextShadowColor:[UIColor styleBackgroundShadowColor]];
    [jumpBar setTextShadowOffset:CGSizeMake(0, 1)];
    
    [jumpBar setButtonColor:[UIColor styleBackgroundColor]];
    [jumpBar setButtonHighlightColor:[UIColor styleHighlightColor]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Navigation Methods

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    CGRect viewFrame = self.view.bounds;
    viewFrame.origin.y += 44;
    viewFrame.size.height -= 44;
    
    UIViewController *topViewController = [self.childViewControllers lastObject];
    [self addChildViewController:viewController];
    if (animated)
    {
        [self transitionFromViewController:topViewController toViewController:viewController duration:1 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
            // TODO
        } completion:^(BOOL finished) {
            [viewController didMoveToParentViewController:self];
        }];
    }
    else
    {
        [topViewController.view removeFromSuperview];
        [self.view addSubview:viewController.view];
        viewController.view.frame = viewFrame;
        [viewController didMoveToParentViewController:self];
    }
}

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

@end
