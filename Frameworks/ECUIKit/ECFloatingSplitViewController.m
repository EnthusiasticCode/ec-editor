//
//  ECFloatingSplitViewController.m
//  edit
//
//  Created by Uri Baghin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECFloatingSplitViewController.h"
#import <QuartzCore/QuartzCore.h>

static const void *ECFloatingSplitViewControllerAssociatedObjectKey;

@interface UIViewController (ECFloatingSplitViewControllerInternal)
@property (nonatomic, weak) ECFloatingSplitViewController *floatingSplitViewController;
@end

@implementation UIViewController (ECFloatingSplitViewControllerInternal)

- (ECFloatingSplitViewController *)floatingSplitViewController
{
    return objc_getAssociatedObject(self, ECFloatingSplitViewControllerAssociatedObjectKey);
}

- (void)setFloatingSplitViewController:(ECFloatingSplitViewController *)floatingSplitViewController
{
    objc_setAssociatedObject(self, ECFloatingSplitViewControllerAssociatedObjectKey, floatingSplitViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

static const NSString *ECFloatingSplitViewControllerTransitionKey = @"ECFloatingSplitViewControllerTransitionKey";

static const CGFloat ECFloatingSplitViewControllerAnimationDuration = 0.15;

@interface ECFloatingSplitViewController ()
{
    UIView *_sidebarView;
    UIView *_mainView;
    UISwipeGestureRecognizer *_swipeGestureRecognizer;
}
- (void)_setup;
- (void)_layoutSubviewsWithAnimation:(BOOL)animated;
- (void)_layoutSubviewsWithinFrame:(CGRect)frame;
- (void)_addSidebarViewWithSidebarHidden:(BOOL)sidebarHidden;
- (void)_removeSidebarView;
- (CGRect)_sidebarFrameWithinFrame:(CGRect)frame sidebarHidden:(BOOL)sidebarHidden;
- (void)_addMainViewWithSidebarHidden:(BOOL)sidebarHidden;
- (void)_removeMainView;
- (CGRect)_mainFrameWithinFrame:(CGRect)frame sidebarHidden:(BOOL)sidebarHidden;
- (void)_swipe:(id)sender;
@end

@implementation ECFloatingSplitViewController

@synthesize sidebarController = _sidebarController;
@synthesize mainController = _mainController;
@synthesize sidebarWidth = _sidebarWidth;
@synthesize sidebarHidden = _sidebarHidden;
@synthesize sidebarOnRight = _sidebarOnRight;
@synthesize sidebarFloating = _sidebarFloating;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

- (void)_setup
{
    _sidebarOnRight = YES;
    _sidebarFloating = YES;
    _sidebarWidth = 200.0;
}

- (void)setSidebarController:(UIViewController *)sidebarController
{
    [self setSidebarController:sidebarController withTransition:nil];
}

- (void)setSidebarController:(UIViewController *)sidebarController withTransition:(CATransition *)transition
{
    if (sidebarController == _sidebarController)
        return;
    [_sidebarController willMoveToParentViewController:nil];
    _sidebarController.floatingSplitViewController = nil;
    [_sidebarController.view removeFromSuperview];
    [_sidebarController removeFromParentViewController];
    _sidebarController = sidebarController;
    [self addChildViewController:sidebarController];
    sidebarController.floatingSplitViewController = self;
    if (_sidebarView)
    {
        [sidebarController viewWillAppear:(transition != nil)];
        [_sidebarView addSubview:sidebarController.view];
        sidebarController.view.frame = _sidebarView.bounds;
        if (transition)
            [_sidebarView.layer addAnimation:transition forKey:(NSString *)ECFloatingSplitViewControllerTransitionKey];
        [sidebarController viewDidAppear:(transition != nil)];
    }
    [sidebarController didMoveToParentViewController:self];
}

- (void)setMainController:(UIViewController *)mainController
{
    [self setMainController:mainController withTransition:nil];
}

- (void)setMainController:(UIViewController *)mainController withTransition:(CATransition *)transition
{
    if (mainController == _mainController)
        return;
    [_mainController willMoveToParentViewController:nil];
    _mainController.floatingSplitViewController = nil;
    [_mainController.view removeFromSuperview];
    [_mainController removeFromParentViewController];
    _mainController = mainController;
    [self addChildViewController:mainController];
    mainController.floatingSplitViewController = self;
    if (_mainView)
    {
        [mainController viewWillAppear:(transition != nil)];
        [_mainView addSubview:mainController.view];
        mainController.view.frame = _mainView.bounds;
        if (transition)
            [_mainView.layer addAnimation:transition forKey:(NSString *)ECFloatingSplitViewControllerTransitionKey];
        [mainController viewDidAppear:(transition != nil)];
    }
    [mainController didMoveToParentViewController:self];
}

- (void)setSidebarWidth:(CGFloat)sidebarWidth
{
    [self setSidebarWidth:sidebarWidth animated:NO];
}

- (void)setSidebarWidth:(CGFloat)sidebarWidth animated:(BOOL)animated
{
    if (sidebarWidth == _sidebarWidth)
        return;
    _sidebarWidth = sidebarWidth;
    [self _layoutSubviewsWithAnimation:animated];
}

- (void)setSidebarHidden:(BOOL)sidebarHidden
{
    [self setSidebarHidden:sidebarHidden animated:NO];
}

- (void)setSidebarHidden:(BOOL)sidebarHidden animated:(BOOL)animated
{
    if (sidebarHidden == _sidebarHidden)
        return;
    _sidebarHidden = sidebarHidden;
    if (sidebarHidden)
    {
        if (animated)
        {
            [UIView animateWithDuration:ECFloatingSplitViewControllerAnimationDuration animations:^{
                [self _layoutSubviewsWithAnimation:NO];
            } completion:^(BOOL finished) {
                [self _removeSidebarView];
            }];
        }
        else
        {
            [self _removeSidebarView];
            [self _layoutSubviewsWithAnimation:NO];
        }
    }
    else
    {
        [self _addSidebarViewWithSidebarHidden:YES];
        [self _layoutSubviewsWithAnimation:animated];
    }
}

- (void)setSidebarOnRight:(BOOL)sidebarOnRight
{
    [self setSidebarOnRight:sidebarOnRight animated:NO];
}

- (void)setSidebarOnRight:(BOOL)sidebarOnRight animated:(BOOL)animated
{
    if (sidebarOnRight == _sidebarOnRight)
        return;
    _sidebarOnRight = sidebarOnRight;
    [self _layoutSubviewsWithAnimation:animated];
}

- (void)setSidebarFloating:(BOOL)sidebarFloating
{
    [self setSidebarFloating:sidebarFloating animated:NO];
}

- (void)setSidebarFloating:(BOOL)sidebarFloating animated:(BOOL)animated
{
    if (sidebarFloating == _sidebarFloating)
        return;
    _sidebarFloating = sidebarFloating;
    [self _layoutSubviewsWithAnimation:animated];
}

- (void)_layoutSubviewsWithAnimation:(BOOL)animated
{
    if (animated)
        [UIView animateWithDuration:ECFloatingSplitViewControllerAnimationDuration animations:^(void) {
            [self _layoutSubviewsWithinFrame:self.view.bounds];
        }];
    else
        [self _layoutSubviewsWithinFrame:self.view.bounds];
}

- (void)_layoutSubviewsWithinFrame:(CGRect)frame
{
    _sidebarView.frame = [self _sidebarFrameWithinFrame:frame sidebarHidden:self.sidebarHidden];
    _mainView.frame = [self _mainFrameWithinFrame:frame sidebarHidden:self.sidebarHidden];
}

- (void)_addSidebarViewWithSidebarHidden:(BOOL)sidebarHidden
{
    ECASSERT(_sidebarView == nil);
    _sidebarView = [[UIView alloc] initWithFrame:[self _sidebarFrameWithinFrame:self.view.bounds sidebarHidden:sidebarHidden]];
    _sidebarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _sidebarView.layer.cornerRadius = 5.0;
    _sidebarView.layer.shadowColor = [UIColor blackColor].CGColor;
    _sidebarView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
    _sidebarView.layer.shadowOpacity = 1.0;
    _sidebarView.layer.shadowRadius = 5.0;
    [self.view addSubview:_sidebarView];
    if (self.sidebarController)
    {
        [self.sidebarController viewWillAppear:NO];
        [_sidebarView addSubview:self.sidebarController.view];
        self.sidebarController.view.frame = _sidebarView.bounds;
        [self.sidebarController viewDidAppear:NO];
    }
}

- (void)_removeSidebarView
{
    [self.sidebarController viewWillDisappear:NO];
    [self.sidebarController.view removeFromSuperview];
    [_sidebarView removeFromSuperview];
    _sidebarView = nil;
    [self.sidebarController viewDidDisappear:YES];
}

- (CGRect)_sidebarFrameWithinFrame:(CGRect)frame sidebarHidden:(BOOL)sidebarHidden
{
    return CGRectMake((self.sidebarOnRight ? frame.size.width - self.sidebarWidth : 0.0) + (sidebarHidden ? self.sidebarWidth * (self.sidebarOnRight ? 1 : -1) : 0.0), 0.0, self.sidebarWidth, frame.size.height);
}

- (void)_addMainViewWithSidebarHidden:(BOOL)sidebarHidden
{
    ECASSERT(_mainView == nil);
    _mainView = [[UIView alloc] initWithFrame:[self _mainFrameWithinFrame:self.view.bounds sidebarHidden:sidebarHidden]];
    _mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_mainView];
    [self.view sendSubviewToBack:_mainView];
    if (self.mainController)
    {
        [self.mainController viewWillAppear:NO];
        [_mainView addSubview:self.mainController.view];
        self.mainController.view.frame = _mainView.bounds;
        [self.mainController viewDidAppear:NO];
    }
}

- (void)_removeMainView
{
    [self.mainController viewWillDisappear:NO];
    [self.sidebarController.view removeFromSuperview];
    [_mainView removeFromSuperview];
    _mainView = nil;
    [self.mainController viewDidDisappear:NO];
}

- (CGRect)_mainFrameWithinFrame:(CGRect)frame sidebarHidden:(BOOL)sidebarHidden
{
    return CGRectMake((self.sidebarFloating || sidebarHidden || self.sidebarOnRight) ? 0.0 : self.sidebarWidth, 0.0, frame.size.width - ((self.sidebarFloating || sidebarHidden) ? 0.0 : self.sidebarWidth), frame.size.height);
}

- (void)_swipe:(id)sender
{
    if (sender != _swipeGestureRecognizer)
        return;
    [self setSidebarHidden:!self.sidebarHidden animated:YES];
    _swipeGestureRecognizer.direction = (self.sidebarHidden ^ self.sidebarOnRight) ? UISwipeGestureRecognizerDirectionRight : UISwipeGestureRecognizerDirectionLeft;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_swipe:)];
    _swipeGestureRecognizer.numberOfTouchesRequired = 1;
    _swipeGestureRecognizer.direction = (self.sidebarHidden ^ self.sidebarOnRight) ? UISwipeGestureRecognizerDirectionRight : UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:_swipeGestureRecognizer];
    [self _addSidebarViewWithSidebarHidden:self.sidebarHidden];
    [self _addMainViewWithSidebarHidden:self.sidebarHidden];
    [self _layoutSubviewsWithAnimation:NO];
}

- (void)viewDidUnload
{
    _swipeGestureRecognizer = nil;
    [self _removeSidebarView];
    [self _removeMainView];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect frame;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation) != UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
        frame = CGRectMake(0.0, 0.0, self.view.bounds.size.height, self.view.bounds.size.width);
    else
        frame = self.view.bounds;
    [self _layoutSubviewsWithinFrame:frame];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _layoutSubviewsWithAnimation:NO];
}

@end
