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
}

- (void)setupMainView;
- (void)setupSidebarView;

@end


@implementation ECSplitViewController

#pragma mark - Properties

@synthesize mainViewController, sidebarViewController;
@synthesize cornerRadius;
@synthesize sidebarOnRight, sidebarVisible;

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
        [self.view setNeedsLayout];
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
        [self.view setNeedsLayout];
    }
}

- (void)setCornerRadius:(CGFloat)radius
{
    if (radius == cornerRadius)
        return;
    
    cornerRadius = radius;
    sidebarContainerView.contentCornerRadius = mainContainerView.contentCornerRadius = cornerRadius;
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

- (void)loadView
{
    sidebarContainerView = [ECRoundedContentCornersView new];
    mainContainerView = [ECRoundedContentCornersView new];
    
    ECBlockView *view = [ECBlockView new];
    __weak ECSplitViewController *this = self;
    view.layoutSubviewsBlock = ^(UIView *view) {
        CGRect bounds = view.bounds;
        CGRect sidebarFrame = CGRectMake(this.isSidebarOnRight ? bounds.size.width - this->sidebarWidth : 0, 0, this->sidebarWidth, bounds.size.height);
        if ([this isSplittingView])
        {
            // View splitting like normal splitview
            this->sidebarContainerView.frame = sidebarFrame;
            
            if (!this.sidebarOnRight)
                bounds.origin.x += this->gutterWidth + this->sidebarWidth;
            bounds.size.width -= this->gutterWidth + this->sidebarWidth;
            this->mainContainerView.frame = bounds;
        }
        else
        {
            this->mainContainerView.frame = bounds;
            if ([this isSidebarVisible])
            {
                // Sidebar floating
                [view bringSubviewToFront:this->sidebarContainerView];
                this->sidebarContainerView.frame = sidebarFrame;
            }
        }
    };
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    sidebarContainerView.contentCornerRadius = mainContainerView.contentCornerRadius = cornerRadius;
    self.view.backgroundColor = sidebarContainerView.backgroundColor = mainContainerView.backgroundColor = [UIColor redColor];
    
    mainContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    sidebarContainerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | (self.isSidebarOnRight ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin);
    
    [self setupMainView];
    [self setupSidebarView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    sidebarContainerView = nil;
    mainContainerView = nil;
}

- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers
{
    return NO;
}

#pragma mark View behaviours



#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    for (UIViewController *controller in self.childViewControllers)
    {
        [controller willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
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
    [mainContainerView addSubview:mainViewController.view];
    [mainContainerView sendSubviewToBack:mainViewController.view];
    [self.view addSubview:mainContainerView];
    
    mainViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mainViewController.view.frame = mainContainerView.bounds;
}

- (void)setupSidebarView
{
    if ([self isSidebarVisible])
    {
        [sidebarContainerView addSubview:sidebarViewController.view];
        [self.view addSubview:sidebarContainerView];
        
        sidebarViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        sidebarViewController.view.frame = sidebarContainerView.bounds;
        
        sidebarContainerView.clipContent = ![self isSplittingView];    
        // TODO shadow with shadowpath
    }
    else
    {
        [sidebarContainerView removeFromSuperview];
    }
}

@end
