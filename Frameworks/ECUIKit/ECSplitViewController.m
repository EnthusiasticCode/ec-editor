//
//  ECSplitViewController.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 20/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECSplitViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "ECInverseCornerShapeView.h"

#define CORNER_RADIUS 6
#define ANIMATION_DURATION 0.20


@interface ECSplitViewController () {
    UIView *sidebarContainerView;
    UIView *mainContainerView;
    
    __weak ECInverseCornerShapeView *roundedCorners[4];
    
    CGFloat sidebarWidth;
    CGFloat gutterWidth;
    
    BOOL splitInLandscape;
    BOOL splitInPortrait;
    
    __weak UISwipeGestureRecognizer *leftSwipeGestureRecognizer;
    __weak UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
}

- (void)setupMainView;
- (void)setupSidebarView;
- (void)layoutChildViewsForInterfaceOrientation:(UIInterfaceOrientation)orientation prepareForAnimation:(BOOL)prepareAnimation;
- (void)layoutChildViews;

- (void)enableSwipeRecognizers;
- (void)handleGestureSwipe:(UISwipeGestureRecognizer *)recognizer;
//- (void)handleGesturePan:(UIPanGestureRecognizer *)recognizer;

@end


@implementation ECSplitViewController

#pragma mark - Properties

@synthesize mainViewController, sidebarViewController;
@synthesize sidebarOnRight, sidebarVisible;
@synthesize panGestureEnabled, panGestureRecognizer;

- (NSArray *)viewControllers
{
    return self.childViewControllers;
}

- (void)setViewControllers:(NSArray *)viewControllers
{
    ECASSERT([viewControllers count] == 2);
    
    self.sidebarViewController = [viewControllers objectAtIndex:0];
    self.mainViewController = [viewControllers objectAtIndex:1];
}

- (void)setMainViewController:(UIViewController *)viewController
{
    ECASSERT([viewController isKindOfClass:[UIViewController class]]);
    
    if (viewController == mainViewController)
        return;
    
    [mainViewController removeFromParentViewController];
    if (mainViewController.isViewLoaded)
        [mainViewController.view removeFromSuperview];
    
    mainViewController = viewController;
    [self addChildViewController:mainViewController];
    
    if (self.isViewLoaded)
    {
        [self setupMainView];
        [self layoutChildViews];
    }
}

- (void)setSidebarViewController:(UIViewController *)viewController
{
    ECASSERT([viewController isKindOfClass:[UIViewController class]]);
    
    if (viewController == sidebarViewController)
        return;
    
    [sidebarViewController removeFromParentViewController];
    if (sidebarViewController.isViewLoaded)
        [sidebarViewController.view removeFromSuperview];
    
    sidebarViewController = viewController;
    [self addChildViewController:sidebarViewController];
    
    if (self.isViewLoaded)
    {
        [self setupSidebarView];
        [self layoutChildViews];
    }
}

- (void)setSidebarOnRight:(BOOL)value
{
    if (sidebarOnRight == value)
        return;
    
    sidebarOnRight = value;
    
    [self enableSwipeRecognizers];
}

- (BOOL)isSidebarVisible
{
    if (self.isSplittingView)
        return YES;
    return sidebarVisible;
}

- (void)setSidebarVisible:(BOOL)value
{
    [self setSidebarVisible:value animated:NO];
}

- (void)setSidebarVisible:(BOOL)value animated:(BOOL)animated
{
    if (sidebarVisible == value || self.isSplittingView)
        return;
    
    if (animated)
    {
        [self layoutChildViewsForInterfaceOrientation:self.interfaceOrientation prepareForAnimation:YES];
        
        sidebarVisible = value;
        
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self layoutChildViewsForInterfaceOrientation:self.interfaceOrientation prepareForAnimation:YES];
        } completion:^(BOOL finished) {
            [self layoutChildViews];
        }];
    }
    else
    {
        sidebarVisible = value;
        [self layoutChildViews];
    }
    
    [self enableSwipeRecognizers];
}

#pragma mark - Creating new controller

static void preinit(ECSplitViewController *self)
{
    self->gutterWidth = 1;
    self->sidebarWidth = 300;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    preinit(self);
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    preinit(self);
    if ((self = [super initWithCoder:coder]))
    {
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    sidebarContainerView = [UIView new];
    mainContainerView = [UIView new];
    
    self.view.backgroundColor = [UIColor blackColor];
    mainContainerView.backgroundColor = sidebarContainerView.backgroundColor = [UIColor clearColor];
    
    mainContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sidebarContainerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | (self.isSidebarOnRight ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin);
    
    [self setupMainView];
    // TODO here setting up even if not neccessary
    [self setupSidebarView];
    [self layoutChildViews];
    
    UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureSwipe:)];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    rightSwipeGestureRecognizer = swipeGestureRecognizer;
    
    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureSwipe:)];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    leftSwipeGestureRecognizer = swipeGestureRecognizer;
    
    [self enableSwipeRecognizers];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    sidebarContainerView = nil;
    mainContainerView = nil;
}

#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self layoutChildViewsForInterfaceOrientation:toInterfaceOrientation prepareForAnimation:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    sidebarVisible = NO;
    leftSwipeGestureRecognizer.enabled = rightSwipeGestureRecognizer.enabled = ![self isSplittingView];
    
    [self layoutChildViews];
}

#pragma mark - Setting view splitting

- (BOOL)isSplittingView
{
    return [self isSplittingViewForInterfaceOrientation:self.interfaceOrientation];
}

- (void)setSplittingView:(BOOL)splittingView
{
    [self setSplittingView:splittingView forInterfaceOrientation:self.interfaceOrientation animated:NO];
}

- (void)setSplittingView:(BOOL)value animated:(BOOL)animated
{
    [self setSplittingView:value forInterfaceOrientation:self.interfaceOrientation animated:animated];
}

- (BOOL)isSplittingViewForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation) ? splitInPortrait : splitInLandscape;
}

- (void)setSplittingView:(BOOL)value forInterfaceOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated
{
    if ([self isSplittingViewForInterfaceOrientation:orientation] == value)
        return;
    
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);
    BOOL willLayout = (isPortrait == UIInterfaceOrientationIsPortrait(self.interfaceOrientation));
    
    if (animated && willLayout)
        [self layoutChildViewsForInterfaceOrientation:orientation prepareForAnimation:YES];
    
    if (isPortrait)
        splitInPortrait = value;
    else
        splitInLandscape = value;
    
    if (!willLayout)
        return;
    
    if (animated)
    {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self layoutChildViewsForInterfaceOrientation:orientation prepareForAnimation:YES];
        } completion:^(BOOL finished) {
            [self layoutChildViews];
        }];
    }
    else
    {
        [self layoutChildViews];
    }
    
    [self enableSwipeRecognizers];
}

#pragma mark - Private Methods

- (void)setupMainView
{
    [mainContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [mainContainerView addSubview:mainViewController.view];
    [self.view addSubview:mainContainerView];
    
    mainViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mainViewController.view.frame = mainContainerView.bounds;
}

- (void)setupSidebarView
{
    [sidebarContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [sidebarContainerView addSubview:sidebarViewController.view];
    [self.view addSubview:sidebarContainerView];
    
    sidebarViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sidebarViewController.view.frame = sidebarContainerView.bounds;
}

- (void)layoutChildViewsForInterfaceOrientation:(UIInterfaceOrientation)orientation prepareForAnimation:(BOOL)prepareAnimation
{
    BOOL isSplitting = [self isSplittingViewForInterfaceOrientation:orientation];
    
    // Compute frames
    CGRect mainFrame = self.view.bounds;
    if (UIInterfaceOrientationIsPortrait(orientation) != UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        mainFrame = (CGRect){ mainFrame.origin, {mainFrame.size.height, mainFrame.size.width} };
    CGRect sidebarFrame = CGRectMake(sidebarOnRight ? mainFrame.size.width - sidebarWidth : 0, 0, sidebarWidth, mainFrame.size.height);
    
    // Adjust frames for configuration
    if (isSplitting)
    {
        // Adjust main view frame
        if (!sidebarOnRight)
            mainFrame.origin.x += gutterWidth + sidebarWidth;
        mainFrame.size.width -= gutterWidth + sidebarWidth;
    }
    else if (!sidebarVisible)
    {
        sidebarFrame.origin.x += sidebarOnRight ? sidebarWidth : -sidebarWidth;
    }
    
    // Apply frames
    mainContainerView.frame = mainFrame;
    sidebarContainerView.frame = sidebarFrame;
    
    // Setup sidebar view
    if (prepareAnimation || self.isSidebarVisible)
    {
        if (sidebarContainerView.superview == nil)
            [self.view addSubview:sidebarContainerView];
        if (isSplitting)
        {
            // Setup corners
            if (roundedCorners[0] == nil)
            {
                // Remove clipping
                self.sidebarViewController.view.layer.cornerRadius = 0;
                self.sidebarViewController.view.layer.masksToBounds = NO;
                sidebarContainerView.layer.shadowOpacity = 0;
                
                // Create rounded corners
                // 0,1 are top/bottom in main view, 2/3 are bottom/top in sidebar view
                [CATransaction begin];
                [CATransaction setDisableActions:YES];
                for (int i = 0; i < 4; ++i)
                {
                    BOOL isSidebar = i > 1;
                    BOOL isBottom = i % 3;
                    ECInverseCornerShapeView *corner = [[ECInverseCornerShapeView alloc] initWithFrame:CGRectMake((isSidebar ? sidebarWidth - CORNER_RADIUS : 0), (isBottom ? mainFrame.size.height - CORNER_RADIUS : 0), CORNER_RADIUS, CORNER_RADIUS)];
                    corner.transform = CGAffineTransformMakeRotation(-M_PI_2 * i);
                    corner.autoresizingMask = (isSidebar ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin) | (isBottom ? UIViewAutoresizingFlexibleTopMargin : UIViewAutoresizingFlexibleBottomMargin);
                    corner.backgroundColor = [UIColor blackColor];
                    if (isSidebar)
                        [sidebarContainerView addSubview:corner];
                    else
                        [mainContainerView addSubview:corner];
                    roundedCorners[i] = corner;
                }
                [CATransaction commit];
            }
        }
        else
        {
            // Setup clipping
            if (!sidebarContainerView.layer.masksToBounds)
            {
                // Remove rounded corners
                for (int i = 0; i < 4; ++i)
                    [roundedCorners[i] removeFromSuperview];
                
                // Apply clipping
                self.sidebarViewController.view.layer.cornerRadius = CORNER_RADIUS;
                self.sidebarViewController.view.layer.masksToBounds = YES;
                
                // Apply shadow
                sidebarContainerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:(CGRect){ CGPointZero, sidebarFrame.size } cornerRadius:CORNER_RADIUS].CGPath;
                sidebarContainerView.layer.shadowOffset = CGSizeMake(sidebarOnRight ? -5 : 5, 0);
                sidebarContainerView.layer.shadowOpacity = 0.3;
            }
        }
    }
    else
    {
        [sidebarContainerView removeFromSuperview];
    }
}

- (void)layoutChildViews
{
    [self layoutChildViewsForInterfaceOrientation:self.interfaceOrientation prepareForAnimation:NO];
}

#pragma mark - Private Methods - Handling Gestures

- (void)enableSwipeRecognizers
{
    rightSwipeGestureRecognizer.enabled = !sidebarVisible ^ sidebarOnRight;
    leftSwipeGestureRecognizer.enabled = sidebarVisible ^ sidebarOnRight;
}

- (void)handleGestureSwipe:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        BOOL isOpen = (recognizer == rightSwipeGestureRecognizer) ^ sidebarOnRight;
        [self setSidebarVisible:isOpen animated:YES];
    }
}

@end
