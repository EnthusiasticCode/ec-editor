//
//  RootController.m
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootController.h"
#import "ProjectsController.h"
#import "FilesController.h"
#import "ECStoryboardSegue.h"
#import "UIView+ConcurrentAnimation.h"

static const CGFloat RootControllerAnimationDuration = 0.25;

static const NSString *ProjectsSegueIdentifier = @"Projects";
static const NSString *FilesSegueIdentifier = @"Files";

@interface RootController ()
{
    BOOL _animationFlag;
    void (^_setSidebarHiddenBlock)(BOOL hidden);
    NSString *_activeSidebarSegueIdentifier;
}
static NSInteger _indexOfSidebarSegue(NSString *segueIdentifier);
@end

@implementation RootController

@synthesize menuView = _menuView;
@synthesize sidebarView = _sidebarView;
@synthesize mainView = _mainView;
@synthesize sidebarHidden = _sidebarHidden;

- (void)setSidebarHidden:(BOOL)sidebarHidden
{
    [self setSidebarHidden:sidebarHidden animated:NO];
}

- (void)setSidebarHidden:(BOOL)sidebarHidden animated:(BOOL)animated
{
    if (!_setSidebarHiddenBlock)
        _setSidebarHiddenBlock = [^(BOOL hidden){
            CGRect menuFrame = self.menuView.frame;
            CGRect sidebarFrame = self.sidebarView.frame;
            CGRect mainFrame = self.mainView.frame;
            CGRect frame = self.view.frame;
            if (hidden)
            {
                sidebarFrame.size.width = 0.0;
                mainFrame.origin.x = sidebarFrame.origin.x;
            }
            else
            {
                sidebarFrame.size.width = 200.0;
                mainFrame.origin.x = sidebarFrame.origin.x + sidebarFrame.size.width;
            }
            mainFrame.size.width = frame.size.width - menuFrame.size.width - sidebarFrame.size.width;
            self.sidebarView.frame = sidebarFrame;
            self.mainView.frame = mainFrame;
        } copy];
    if (animated)
        [UIView animateConcurrentlyToAnimationsWithFlag:&_animationFlag duration:RootControllerAnimationDuration animations:^{
            _setSidebarHiddenBlock(sidebarHidden);
        } completion:NULL];
    else
        _setSidebarHiddenBlock(sidebarHidden);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

static NSInteger _indexOfSidebarSegue(NSString *segueIdentifier)
{
    if (!segueIdentifier)
        return -1;
    if ([segueIdentifier isEqualToString:(NSString *)ProjectsSegueIdentifier])
        return 0;
    if ([segueIdentifier isEqualToString:(NSString *)FilesSegueIdentifier])
        return 1;
    return -1;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:(NSString *)ProjectsSegueIdentifier] || [identifier isEqualToString:(NSString *)FilesSegueIdentifier])
    {
        [segue.destinationViewController setRootController:self];
        ECStoryboardSegue *customSegue = (ECStoryboardSegue *)segue;
        customSegue.exitingView = self.sidebarView;
        if (_indexOfSidebarSegue(_activeSidebarSegueIdentifier) < _indexOfSidebarSegue(identifier))
            customSegue.options = ECStoryboardSegueAnimationOptionEnterBottom | ECStoryboardSegueAnimationOptionExitTop;
        else
            customSegue.options = ECStoryboardSegueAnimationOptionEnterTop | ECStoryboardSegueAnimationOptionExitBottom;
        _activeSidebarSegueIdentifier = identifier;
        self.sidebarView = [segue.destinationViewController view];
    }
}

- (IBAction)hideSidebar:(id)sender
{
    [self setSidebarHidden:YES animated:YES];
}

- (IBAction)showSidebar:(id)sender
{
    [self setSidebarHidden:NO animated:YES];
}

@end
