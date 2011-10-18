//
//  ACToolbarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTopBarController.h"
#import "ACTopBarToolbar.h"
#import <QuartzCore/QuartzCore.h>

#define DEFAULT_TOOLBAR_HEIGHT 44

@interface ACTopBarController () {
@private
    NSMutableArray *toolbars;
}

- (void)layoutChildViewsAnimated:(BOOL)animated;
- (void)setupDefaultToolbarAnimated:(BOOL)animated;

@end


@implementation ACTopBarController

@synthesize defaultToolbar = _defaultToolbar, contentViewController = _contentViewController;
@synthesize toolbarHeight = _toolbarHeight;

- (void)setContentViewController:(UIViewController *)contentViewController
{
    [self setContentViewController:contentViewController animated:NO];
}

- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated
{
    if (contentViewController == _contentViewController)
        return;
    
    [self willChangeValueForKey:@"contentViewController"];
    
    if (self.isViewLoaded)
    {
        if (_contentViewController != nil && animated)
        {
            [UIView transitionFromView:_contentViewController.view toView:contentViewController.view duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
                [_contentViewController.view removeFromSuperview];
            }];
        }
        else
        {
            [self.view addSubview:contentViewController.view];
            [_contentViewController.view removeFromSuperview];
        }
        
        [self layoutChildViewsAnimated:animated];
        [self setupDefaultToolbarAnimated:animated];
    }
    
    [self.childViewControllers makeObjectsPerformSelector:@selector(removeFromParentViewController)];
    [self addChildViewController:contentViewController];
    _contentViewController = contentViewController;
    
    [self didChangeValueForKey:@"contentViewController"];
}

- (UIView *)currentToolbarView
{
    if (toolbars && [toolbars count])
        return [toolbars lastObject];
    return self.defaultToolbar;
}

- (CGFloat)toolbarHeight
{
    if (_toolbarHeight == 0)
        _toolbarHeight = DEFAULT_TOOLBAR_HEIGHT;
    return _toolbarHeight;
}

- (void)setToolbarHeight:(CGFloat)toolbarHeight
{
    [self setToolbarHeight:toolbarHeight animated:NO];
}

- (void)setToolbarHeight:(CGFloat)toolbarHeight animated:(BOOL)animated
{
    if (toolbarHeight == _toolbarHeight 
        || (toolbarHeight != DEFAULT_TOOLBAR_HEIGHT && self.currentToolbarView == self.defaultToolbar))
        return;
    
    _toolbarHeight = toolbarHeight;
    [self layoutChildViewsAnimated:animated];
}

- (void)resetToolbarHeightAnimated:(BOOL)animated
{
    [self setToolbarHeight:DEFAULT_TOOLBAR_HEIGHT animated:animated];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Adding child views
    UIView *currentToolbar = self.currentToolbarView;
    if (currentToolbar != self.defaultToolbar)
    {
        [self.defaultToolbar removeFromSuperview];
        [self.view addSubview:currentToolbar];
    }
    [self.view addSubview:self.contentViewController.view];
    
    // Layout and setup
    [self setupDefaultToolbarAnimated:NO];
    [self layoutChildViewsAnimated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Additional toolbars

- (void)pushToolbarView:(UIView *)toolbarView animated:(BOOL)animated
{
    ECASSERT(toolbarView != nil);
    
    UIView *lastToolbar = self.currentToolbarView;
    toolbarView.frame = lastToolbar.frame;
    toolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    if (!toolbars)
        toolbars = [NSMutableArray new];
    [toolbars addObject:toolbarView];
    
    if (self.isViewLoaded)
    {
        [self resetToolbarHeightAnimated:animated];
        
        if (animated)
        {
            lastToolbar.layer.anchorPointZ = 19;
            [self.view addSubview:toolbarView];
            toolbarView.frame = lastToolbar.frame;
            toolbarView.layer.anchorPointZ = 19;
            toolbarView.layer.transform = CATransform3DMakeRotation(M_PI_2, -1, 0, 0);
            toolbarView.layer.opacity = 0.4;
            
            [UIView animateWithDuration:0.2 animations:^{
                lastToolbar.layer.transform = CATransform3DMakeRotation(M_PI_2, 1, 0, 0);
                lastToolbar.layer.opacity = 0.4;
                toolbarView.layer.transform = CATransform3DIdentity;
                toolbarView.layer.opacity = 1;
            } completion:^(BOOL finished) {
                lastToolbar.layer.transform = CATransform3DIdentity;
                [lastToolbar removeFromSuperview];
            }];
        }
        else
        {
            [lastToolbar removeFromSuperview];
            [self.view addSubview:toolbarView];
            [self layoutChildViewsAnimated:NO];
        }
    }
}

- (void)popToolbarViewAnimated:(BOOL)animated
{
    if (![toolbars count])
        return;
    
    if (self.isViewLoaded)
    {
        [self resetToolbarHeightAnimated:animated];
        
        UIView *currentToolbar = [toolbars lastObject];
        UIView *lastToolbar = self.defaultToolbar;
        if ([toolbars count] > 1)
            lastToolbar = [toolbars objectAtIndex:[toolbars count] - 2];
        if (animated)
        {
            currentToolbar.layer.anchorPointZ = 19;
            [self.view addSubview:lastToolbar];
            lastToolbar.frame = currentToolbar.frame;
            lastToolbar.layer.anchorPointZ = 19;
            lastToolbar.layer.transform = CATransform3DMakeRotation(M_PI_2, 1, 0, 0);
            lastToolbar.layer.opacity = 0.4;
            
            [UIView animateWithDuration:0.2 animations:^{
                currentToolbar.layer.transform = CATransform3DMakeRotation(M_PI_2, -1, 0, 0);
                currentToolbar.layer.opacity = 0.4;
                lastToolbar.layer.transform = CATransform3DIdentity;
                lastToolbar.layer.opacity = 1;
            } completion:^(BOOL finished) {
                currentToolbar.layer.transform = CATransform3DIdentity;
                [currentToolbar removeFromSuperview];
            }];
        }
        else
        {
            [currentToolbar removeFromSuperview];
            [self.view addSubview:lastToolbar];
        }
        
        [self layoutChildViewsAnimated:NO];
    }
    
    [toolbars removeLastObject];
}

#pragma mark - Private methods

- (void)layoutChildViewsAnimated:(BOOL)animated
{
    CGRect contentFrame = self.view.bounds;
    CGRect toolbarFrame = contentFrame;
    toolbarFrame.size.height = self.toolbarHeight;
    contentFrame.origin.y += toolbarFrame.size.height;
    contentFrame.size.height -= toolbarFrame.size.height;
    
    if (animated)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.currentToolbarView.frame = toolbarFrame;
            if (self.contentViewController && self.contentViewController.isViewLoaded)
                self.contentViewController.view.frame = contentFrame;
        }];
    }
    else
    {
        self.currentToolbarView.frame = toolbarFrame;
        if (self.contentViewController && self.contentViewController.isViewLoaded)
            self.contentViewController.view.frame = contentFrame;
    }
}

- (void)setupDefaultToolbarAnimated:(BOOL)animated
{
    [self.defaultToolbar.titleControl setTitle:_contentViewController.navigationItem.title forState:UIControlStateNormal];
    [self.defaultToolbar setToolItem:self.contentViewController.navigationItem.rightBarButtonItem animated:animated];
}

@end


@implementation UIViewController (ACTopBarController)

- (ACTopBarController *)topBarController
{
    UIViewController *parent = self;
    while (parent && ![parent isKindOfClass:[ACTopBarController class]])
        parent = parent.parentViewController;
    return (ACTopBarController *)parent;
}

@end
