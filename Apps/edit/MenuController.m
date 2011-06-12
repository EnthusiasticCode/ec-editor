//
//  MenuController.m
//  edit
//
//  Created by Uri Baghin on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuController.h"
#import "ECStoryboardTripleSplitSidebarSegue.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat TransitionDuration = 0.15;

static const NSString *ProjectsSidebarIdentifier = @"Projects";
static const NSString *FilesSidebarIdentifier = @"Files";

@interface MenuController ()
@property (nonatomic, weak) ECTripleSplitViewController *tripleSplitViewController;
static NSInteger _indexForSidebarIdentifier(NSString *identifier);
@end

@implementation MenuController

@synthesize tripleSplitViewController = _tripleSplitViewController;

- (void)setTripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController
{
    if (tripleSplitViewController == _tripleSplitViewController)
        return;
    _tripleSplitViewController.delegate = nil;
    _tripleSplitViewController = tripleSplitViewController;
    tripleSplitViewController.delegate = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

static NSInteger _indexForSidebarIdentifier(NSString *identifier)
{
    if (!identifier)
        return -1;
    if ([ProjectsSidebarIdentifier isEqualToString:identifier])
        return 1;
    if ([FilesSidebarIdentifier isEqualToString:identifier])
        return 2;
    return NSIntegerMax;
}

- (void)tripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController willShowSidebarController:(UIViewController *)viewController
{
    [(UIButton *)[self.view viewWithTag:_indexForSidebarIdentifier(self.tripleSplitViewController.sidebarController.title)] setSelected:NO];
    [(UIButton *)[self.view viewWithTag:_indexForSidebarIdentifier(viewController.title)] setSelected:YES];
}

- (IBAction)hideSidebar:(id)sender
{
    [(UIButton *)[self.view viewWithTag:_indexForSidebarIdentifier(self.tripleSplitViewController.sidebarController.title)] setSelected:NO];
    [self.tripleSplitViewController setSidebarHidden:YES animated:YES];
}

- (IBAction)showSidebar:(id)sender
{
    [self.tripleSplitViewController setSidebarHidden:NO animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CATransition *transition = [CATransition animation];
    transition.duration = TransitionDuration;
    transition.type = kCATransitionPush;
    if (_indexForSidebarIdentifier(self.tripleSplitViewController.sidebarController.title) > _indexForSidebarIdentifier([segue.destinationViewController title]))
        transition.subtype = kCATransitionFromBottom;
    else
        transition.subtype = kCATransitionFromTop;
    [(ECStoryboardTripleSplitSidebarSegue *)segue setTransition:transition];
}

@end
