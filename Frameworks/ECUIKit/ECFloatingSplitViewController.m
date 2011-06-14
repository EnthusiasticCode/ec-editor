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
    struct
    {
        unsigned int delegateWillShowSidebar:1;
        unsigned int delegateDidShowSidebar:1;
        unsigned int delegateWillShowMain:1;
        unsigned int delegateDidShowMain:1;
        unsigned int delegateWillHideSidebar:1;
        unsigned int delegateDidHideSidebar:1;
    } _flags;
}
@property (nonatomic, strong) void (^_layoutBlock)(void);
- (void)_setup;
- (void)_layoutSubviewsWithAnimation:(BOOL)animated;
- (void)_swipe:(id)sender;
@end

@implementation ECFloatingSplitViewController

@synthesize delegate = _delegate;
@synthesize sidebarController = _sidebarController;
@synthesize mainController = _mainController;
@synthesize sidebarWidth = _sidebarWidth;
@synthesize sidebarHidden = _sidebarHidden;
@synthesize sidebarOnRight = _sidebarOnRight;
@synthesize sidebarFloating = _sidebarFloating;
@synthesize _layoutBlock = __layoutBlock;

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

- (void)setDelegate:(id<ECFloatingSplitViewControllerDelegate>)delegate
{
    if (delegate == _delegate)
        return;
    _delegate = delegate;
    _flags.delegateWillShowSidebar = [delegate respondsToSelector:@selector(floatingSplitViewController:willShowSidebarController:)];
    _flags.delegateDidShowSidebar = [delegate respondsToSelector:@selector(floatingSplitViewController:didShowSidebarController:)];
    _flags.delegateWillShowMain = [delegate respondsToSelector:@selector(floatingSplitViewController:willShowMainController:)];
    _flags.delegateDidShowMain = [delegate respondsToSelector:@selector(floatingSplitViewController:didShowMainController:)];
    _flags.delegateWillHideSidebar = [delegate respondsToSelector:@selector(floatingSplitViewControllerWillHideSidebar:)];
    _flags.delegateDidHideSidebar = [delegate respondsToSelector:@selector(floatingSplitViewControllerDidHideSidebar:)];
}

- (void)setSidebarController:(UIViewController *)sidebarController
{
    [self setSidebarController:sidebarController withTransition:nil];
}

- (void)setSidebarController:(UIViewController *)sidebarController withTransition:(CATransition *)transition
{
    if (sidebarController == _sidebarController)
        return;
    if (_flags.delegateWillShowSidebar)
        [self.delegate floatingSplitViewController:self willShowSidebarController:sidebarController];
    _sidebarController.floatingSplitViewController = nil;
    _sidebarController = sidebarController;
    sidebarController.floatingSplitViewController = self;
    if (_sidebarView)
    {
        [sidebarController viewWillAppear:(transition != nil)];
        [_sidebarView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_sidebarView addSubview:sidebarController.view];
        sidebarController.view.frame = _sidebarView.bounds;
        if (transition)
            [_sidebarView.layer addAnimation:transition forKey:(NSString *)ECFloatingSplitViewControllerTransitionKey];
        [sidebarController viewDidAppear:(transition != nil)];
    }
    if (_flags.delegateDidShowSidebar)
        [self.delegate floatingSplitViewController:self didShowSidebarController:sidebarController];
}

- (void)setMainController:(UIViewController *)mainController
{
    [self setMainController:mainController withTransition:nil];
}

- (void)setMainController:(UIViewController *)mainController withTransition:(CATransition *)transition
{
    if (mainController == _mainController)
        return;
    if (_flags.delegateWillShowMain)
        [self.delegate floatingSplitViewController:self willShowMainController:mainController];
    _mainController.floatingSplitViewController = nil;
    _mainController = mainController;
    mainController.floatingSplitViewController = self;
    if (_mainView)
    {
        [mainController viewWillAppear:(transition != nil)];
        [_mainView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_mainView addSubview:mainController.view];
        mainController.view.frame = _mainView.bounds;
        if (transition)
            [_mainView.layer addAnimation:transition forKey:(NSString *)ECFloatingSplitViewControllerTransitionKey];
        [mainController viewDidAppear:(transition != nil)];
    }
    if (_flags.delegateDidShowMain)
        [self.delegate floatingSplitViewController:self didShowMainController:mainController];
}

- (void)setSidebarWidth:(CGFloat)sidebarWidth
{
    if (sidebarWidth == _sidebarWidth)
        return;
    _sidebarWidth = sidebarWidth;
    [self _layoutSubviewsWithAnimation:NO];
}

- (void)setSidebarHidden:(BOOL)sidebarHidden
{
    [self setSidebarHidden:sidebarHidden animated:NO];
}

- (void)setSidebarHidden:(BOOL)sidebarHidden animated:(BOOL)animated
{
    if (sidebarHidden == _sidebarHidden)
        return;
    if (sidebarHidden && _flags.delegateWillHideSidebar)
        [self.delegate floatingSplitViewControllerWillHideSidebar:self];
    if (!sidebarHidden && _flags.delegateWillShowSidebar)
        [self.delegate floatingSplitViewController:self willShowSidebarController:self.sidebarController];
    _sidebarHidden = sidebarHidden;
    if (sidebarHidden)
    {
        [self.sidebarController viewWillDisappear:animated];
        if (animated)
        {
            [UIView animateWithDuration:ECFloatingSplitViewControllerAnimationDuration animations:^{
                CGRect frame = _sidebarView.frame;
                frame.origin.x = self.sidebarOnRight ? self.view.frame.size.width : -frame.size.width;
                _sidebarView.frame = frame;
                self._layoutBlock();
            } completion:^(BOOL finished) {
                [self.sidebarController.view removeFromSuperview];
                [_sidebarView removeFromSuperview];
            }];
        }
        else
        {
            [self.sidebarController.view removeFromSuperview];
            [_sidebarView removeFromSuperview];
            self._layoutBlock();
        }
        [self.sidebarController viewDidDisappear:animated];
    }
    else
    {
        [self.sidebarController viewWillAppear:animated];
        if (animated)
        {
            _sidebarView = [[UIView alloc] initWithFrame:CGRectMake(self.sidebarOnRight ? self.view.frame.size.width : 0.0, 0.0, 0.0, self.view.frame.size.height)];
            _sidebarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:_sidebarView];
            if (self.sidebarController)
            {
                [_sidebarView addSubview:self.sidebarController.view];
                self.sidebarController.view.frame = _sidebarView.bounds;
            }
            [UIView animateWithDuration:ECFloatingSplitViewControllerAnimationDuration animations:self._layoutBlock];
        }
        else
            self._layoutBlock();
        [self.sidebarController viewDidAppear:animated];
    }
    if (sidebarHidden && _flags.delegateDidHideSidebar)
        [self.delegate floatingSplitViewControllerDidHideSidebar:self];
    if (!sidebarHidden && _flags.delegateDidShowSidebar)
        [self.delegate floatingSplitViewController:self didShowSidebarController:self.sidebarController];
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

- (void (^)(void))_layoutBlock
{
    if (!__layoutBlock)
        __layoutBlock = [^{
            CGRect frame = self.view.frame;
            CGRect sidebarFrame = CGRectMake(self.sidebarOnRight ? frame.size.width - self.sidebarWidth : 0.0, 0.0, self.sidebarWidth, frame.size.height);
            CGRect mainFrame = CGRectMake((self.sidebarFloating || self.sidebarHidden || self.sidebarOnRight) ? 0.0 : self.sidebarWidth, 0.0, frame.size.width - ((self.sidebarFloating || self.sidebarHidden) ? 0.0 : self.sidebarWidth), frame.size.height);
            if (!self.sidebarHidden)
            {
                if (!_sidebarView)
                {
                    _sidebarView = [[UIView alloc] initWithFrame:sidebarFrame];
                    _sidebarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    [self.view addSubview:_sidebarView];
                    if (self.sidebarController)
                    {
                        [self.sidebarController viewWillAppear:NO];
                        [_sidebarView addSubview:self.sidebarController.view];
                        self.sidebarController.view.frame = _sidebarView.bounds;
                        [self.sidebarController viewDidAppear:NO];
                    }
                }
                _sidebarView.frame = sidebarFrame;
            }
            if (!_mainView)
            {
                _mainView = [[UIView alloc] initWithFrame:mainFrame];
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
            _mainView.frame = mainFrame;
        } copy];
    return __layoutBlock;
}

- (void)_layoutSubviewsWithAnimation:(BOOL)animated
{
    if (animated)
        [UIView animateWithDuration:ECFloatingSplitViewControllerAnimationDuration animations:self._layoutBlock];
    else
        self._layoutBlock();
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
    [self _layoutSubviewsWithAnimation:NO];
}

- (void)viewDidUnload
{
    _swipeGestureRecognizer = nil;
    _sidebarView = nil;
    _mainView = nil;
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.sidebarController didReceiveMemoryWarning];
    [self.mainController didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.sidebarController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.mainController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.sidebarController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.mainController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.sidebarController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.mainController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self _layoutSubviewsWithAnimation:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.sidebarController viewWillAppear:animated];
    [self.mainController viewWillAppear:animated];
    [self _layoutSubviewsWithAnimation:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.sidebarController viewDidAppear:animated];
    [self.mainController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.sidebarController viewWillDisappear:animated];
    [self.mainController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.sidebarController viewDidDisappear:animated];
    [self.mainController viewDidDisappear:animated];
}

@end
