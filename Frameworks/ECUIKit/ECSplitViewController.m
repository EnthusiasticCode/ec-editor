//
//  ECSplitViewController.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 20/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECSplitViewController.h"

#import "ECBlockView.h"
#import "ECRoundedContentCornersView.h"


@interface ECSplitViewController () {
    ECRoundedContentCornersView *sidebarContainerView;
    ECRoundedContentCornersView *mainContainerView;
    
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

- (void)handleGestureSwipe:(UISwipeGestureRecognizer *)recognizer;
- (void)handleGesturePan:(UIPanGestureRecognizer *)recognizer;

@end


@implementation ECSplitViewController

#pragma mark - Properties

@synthesize mainViewController, sidebarViewController;
@synthesize cornerRadius;
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

- (void)setCornerRadius:(CGFloat)radius
{
    if (radius == cornerRadius)
        return;
    
    cornerRadius = radius;
    sidebarContainerView.contentCornerRadius = mainContainerView.contentCornerRadius = cornerRadius;
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
        
        [UIView animateWithDuration:2 animations:^{
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
}

#pragma mark - Creating new controller

static void preinit(ECSplitViewController *self)
{
    self->gutterWidth = 1;
    self->sidebarWidth = 300;
    
    self->cornerRadius = 30;
    
//    self->sidebarVisible = YES;
    self->splitInLandscape = YES;
}

static void init(ECSplitViewController *self)
{

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    preinit(self);
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    preinit(self);
    if ((self = [super initWithCoder:coder]))
    {
        init(self);
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    sidebarContainerView = [ECRoundedContentCornersView new];
    mainContainerView = [ECRoundedContentCornersView new];
    
    sidebarContainerView.contentCornerRadius = mainContainerView.contentCornerRadius = cornerRadius;
    self.view.backgroundColor = sidebarContainerView.backgroundColor = mainContainerView.backgroundColor = [UIColor redColor];
    
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    sidebarContainerView = nil;
    mainContainerView = nil;
}

#pragma mark View behaviours



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
    if (isPortrait)
        splitInPortrait = value;
    else
        splitInLandscape = value;
    
    if (isPortrait != UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        return;
    
    // TODO hide or show sidebar animated
}

#pragma mark - Private Methods

- (void)setupMainView
{
    [mainContainerView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [mainContainerView addSubview:mainViewController.view];
//    [mainContainerView sendSubviewToBack:mainViewController.view];
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
    
    // Setup sidebar view
    if (prepareAnimation || self.isSidebarVisible)
    {
        if (sidebarContainerView.superview == nil)
            [self.view addSubview:sidebarContainerView];
        sidebarContainerView.clipContent = !isSplitting;
        // TODO shadow
    }
    else
    {
        [sidebarContainerView removeFromSuperview];
    }
    
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
    
    // TODO adjust 
    // Apply frames
    mainContainerView.frame = mainFrame;
    sidebarContainerView.frame = sidebarFrame;
}

- (void)layoutChildViews
{
    [self layoutChildViewsForInterfaceOrientation:self.interfaceOrientation prepareForAnimation:NO];
}

#pragma mark - Private Methods - Handling Gestures

- (void)handleGestureSwipe:(UISwipeGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        BOOL isOpen = (recognizer == rightSwipeGestureRecognizer) ^ sidebarOnRight;
        [self setSidebarVisible:isOpen animated:YES];
    }
}

@end
