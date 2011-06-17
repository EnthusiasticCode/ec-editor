//
//  ECFloatingSplitViewController.m
//  edit
//
//  Created by Uri Baghin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECFloatingSplitViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIViewController (ECFloatingSplitViewController)

- (ECFloatingSplitViewController *)floatingSplitViewController
{
    UIViewController *ancestor = self.parentViewController;
    while (ancestor && ![ancestor isKindOfClass:[ECFloatingSplitViewController class]])
        ancestor = [ancestor parentViewController];
    return (ECFloatingSplitViewController *)ancestor;
}

@end

static NSString *const ECFloatingSplitViewControllerTransitionKey = @"ECFloatingSplitViewControllerTransitionKey";

static const CGFloat ECFloatingSplitViewControllerAnimationDuration = 0.15;

@interface ECFloatingSplitViewController ()
{
    UIView *_sidebarView;
    UIView *_mainView;
    UISwipeGestureRecognizer *_swipeGestureRecognizer;
}
static void _init(ECFloatingSplitViewController *self);
- (void)_layoutSubviewsWithAnimation:(BOOL)animated;
- (void)_layoutSubviewsWithinFrame:(CGRect)frame;
- (void)_addSidebarViewWithSidebarHidden:(BOOL)sidebarHidden;
- (void)_removeSidebarView;
- (CGRect)_sidebarFrameWithinFrame:(CGRect)frame sidebarHidden:(BOOL)sidebarHidden;
- (void)_addMainViewWithSidebarHidden:(BOOL)sidebarHidden;
- (void)_removeMainView;
- (CGRect)_mainFrameWithinFrame:(CGRect)frame sidebarHidden:(BOOL)sidebarHidden;
- (void)_addSwipeRecognizer;
- (void)_removeSwipeRecognizer;
- (void)_swipe:(id)sender;
- (UISwipeGestureRecognizerDirection)_nextSwipeDirection;
@end

@implementation ECFloatingSplitViewController

@synthesize sidebarController = _sidebarController;
@synthesize mainController = _mainController;
@synthesize sidebarWidth = _sidebarWidth;
@synthesize sidebarEdge = _sidebarEdge;
@synthesize sidebarLocked = _sidebarLocked;
@synthesize sidebarHidden = _sidebarHidden;
@synthesize sidebarFloating = _sidebarFloating;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    _init(self);
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self)
        return nil;
    _init(self);
    return self;
}

static void _init(ECFloatingSplitViewController *self)
{
    self->_sidebarEdge = ECFloatingSplitViewControllerSidebarEdgeLeft;
    self->_sidebarFloating = YES;
    self->_sidebarWidth = 200.0;
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
    [_sidebarController.view removeFromSuperview];
    [_sidebarController removeFromParentViewController];
    _sidebarController = sidebarController;
    [self addChildViewController:sidebarController];
    if (_sidebarView)
    {
        [sidebarController viewWillAppear:(transition != nil)];
        [_sidebarView addSubview:sidebarController.view];
        sidebarController.view.frame = _sidebarView.bounds;
        if (transition)
            [_sidebarView.layer addAnimation:transition forKey:ECFloatingSplitViewControllerTransitionKey];
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
    [_mainController.view removeFromSuperview];
    [_mainController removeFromParentViewController];
    _mainController = mainController;
    [self addChildViewController:mainController];
    if (_mainView)
    {
        [mainController viewWillAppear:(transition != nil)];
        [_mainView addSubview:mainController.view];
        mainController.view.frame = _mainView.bounds;
        if (transition)
            [_mainView.layer addAnimation:transition forKey:ECFloatingSplitViewControllerTransitionKey];
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
    if (!self.isViewLoaded)
        return;
    [self _layoutSubviewsWithAnimation:animated];
}

- (void)setSidebarEdge:(ECFloatingSplitViewControllerSidebarEdge)sidebarEdge
{
    [self setSidebarEdge:sidebarEdge animated:NO];
}

- (void)setSidebarEdge:(ECFloatingSplitViewControllerSidebarEdge)sidebarEdge animated:(BOOL)animated
{
    if (sidebarEdge == _sidebarEdge)
        return;
    if (!self.isViewLoaded || self.sidebarHidden)
    {
        _sidebarEdge = sidebarEdge;
        return;
    }
    [self setSidebarHidden:YES animated:animated];
    _sidebarEdge = sidebarEdge;
    [self setSidebarHidden:NO animated:animated];
}

- (void)setSidebarLocked:(BOOL)sidebarLocked
{
    if (sidebarLocked == _sidebarLocked)
        return;
    _sidebarLocked = sidebarLocked;
    if (!self.isViewLoaded)
        return;    
    if (sidebarLocked)
        [self _removeSwipeRecognizer];
    else
        [self _addSwipeRecognizer];
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
    if (!self.isViewLoaded)
        return;
    _swipeGestureRecognizer.direction = [self _nextSwipeDirection];
    if (!sidebarHidden)
    {
        [self _addSidebarViewWithSidebarHidden:YES];
        [self _layoutSubviewsWithAnimation:animated];
        return;
    }
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

- (void)setSidebarFloating:(BOOL)sidebarFloating
{
    [self setSidebarFloating:sidebarFloating animated:NO];
}

- (void)setSidebarFloating:(BOOL)sidebarFloating animated:(BOOL)animated
{
    if (sidebarFloating == _sidebarFloating)
        return;
    if (!self.isViewLoaded || self.sidebarHidden)
    {
        _sidebarFloating = sidebarFloating;
        return;
    }
    [self setSidebarHidden:YES animated:animated];
    _sidebarFloating = sidebarFloating;
    [self setSidebarHidden:NO animated:animated];
}

- (void)_layoutSubviewsWithAnimation:(BOOL)animated
{
    if (!_mainView && !_sidebarView)
        return;
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
    if (self.sidebarFloating)
    {
        _sidebarView.layer.cornerRadius = 5.0;
        _sidebarView.layer.shadowColor = [UIColor blackColor].CGColor;
        _sidebarView.layer.shadowOffset = CGSizeMake(0.0, 1.0);
        _sidebarView.layer.shadowOpacity = 1.0;
        _sidebarView.layer.shadowRadius = 5.0;
    }
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
    CGRect sidebarFrame;
    switch (self.sidebarEdge)
    {
        case ECFloatingSplitViewControllerSidebarEdgeTop:
            sidebarFrame = CGRectMake(0.0, sidebarHidden ? -self.sidebarWidth : 0.0, frame.size.width, self.sidebarWidth);
            break;
        case ECFloatingSplitViewControllerSidebarEdgeBottom:
            sidebarFrame = CGRectMake(0.0, sidebarHidden ? frame.size.height : frame.size.height - self.sidebarWidth, frame.size.width, self.sidebarWidth);
            break;
        case ECFloatingSplitViewControllerSidebarEdgeLeft:
            sidebarFrame = CGRectMake(sidebarHidden ? -self.sidebarWidth : 0.0, 0.0, self.sidebarWidth, frame.size.height);
            break;
        case ECFloatingSplitViewControllerSidebarEdgeRight:
            sidebarFrame = CGRectMake(sidebarHidden ? frame.size.width : frame.size.width - self.sidebarWidth, 0.0, self.sidebarWidth, frame.size.height);
            break;
    }
    return sidebarFrame;
}

- (void)_addMainViewWithSidebarHidden:(BOOL)sidebarHidden
{
    ECASSERT(_mainView == nil);
    _mainView = [[UIView alloc] initWithFrame:[self _mainFrameWithinFrame:self.view.bounds sidebarHidden:sidebarHidden]];
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
    if (sidebarHidden || self.sidebarFloating)
        return frame;
    CGRect mainFrame;
    switch (self.sidebarEdge)
    {
        case ECFloatingSplitViewControllerSidebarEdgeTop:
            mainFrame = CGRectMake(0.0, self.sidebarWidth, frame.size.width, frame.size.height - self.sidebarWidth);
            break;
        case ECFloatingSplitViewControllerSidebarEdgeBottom:
            mainFrame = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height - self.sidebarWidth);
            break;
        case ECFloatingSplitViewControllerSidebarEdgeLeft:
            mainFrame = CGRectMake(self.sidebarWidth, 0.0, frame.size.width - self.sidebarWidth, frame.size.height);
            break;
        case ECFloatingSplitViewControllerSidebarEdgeRight:
            mainFrame = CGRectMake(0.0, 0.0, frame.size.width - self.sidebarWidth, frame.size.height);
            break;
    }
    return mainFrame;
}

- (void)_addSwipeRecognizer
{
    _swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_swipe:)];
    _swipeGestureRecognizer.numberOfTouchesRequired = 1;
    _swipeGestureRecognizer.direction = [self _nextSwipeDirection];
    [self.view addGestureRecognizer:_swipeGestureRecognizer];
}

- (void)_removeSwipeRecognizer
{
    [self.view removeGestureRecognizer:_swipeGestureRecognizer];
    _swipeGestureRecognizer = nil;
}

- (void)_swipe:(id)sender
{
    if (sender != _swipeGestureRecognizer)
        return;
    [self setSidebarHidden:!self.sidebarHidden animated:YES];
}

- (UISwipeGestureRecognizerDirection)_nextSwipeDirection
{
    UISwipeGestureRecognizerDirection direction;
    switch (self.sidebarEdge)
    {
        case ECFloatingSplitViewControllerSidebarEdgeTop:
            direction = self.sidebarHidden ? UISwipeGestureRecognizerDirectionDown : UISwipeGestureRecognizerDirectionUp;
            break;
        case ECFloatingSplitViewControllerSidebarEdgeBottom:
            direction = self.sidebarHidden ? UISwipeGestureRecognizerDirectionUp : UISwipeGestureRecognizerDirectionDown;
            break;
        case ECFloatingSplitViewControllerSidebarEdgeLeft:
            direction = self.sidebarHidden ? UISwipeGestureRecognizerDirectionRight : UISwipeGestureRecognizerDirectionLeft;
            break;
        case ECFloatingSplitViewControllerSidebarEdgeRight:
            direction = self.sidebarHidden ? UISwipeGestureRecognizerDirectionLeft : UISwipeGestureRecognizerDirectionRight;
            break;
    }
    return direction;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (!self.sidebarLocked)
        [self _addSwipeRecognizer];
    [self _addSidebarViewWithSidebarHidden:self.sidebarHidden];
    [self _addMainViewWithSidebarHidden:self.sidebarHidden];
    [self _layoutSubviewsWithAnimation:NO];
}

- (void)viewDidUnload
{
    if (!self.sidebarLocked)
        [self _removeSwipeRecognizer];
    [self _removeSidebarView];
    [self _removeMainView];
    [super viewDidUnload];
}

- (void)viewWillLayoutSubviews
{
    [self _layoutSubviewsWithAnimation:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self _layoutSubviewsWithAnimation:NO];
}

@end
