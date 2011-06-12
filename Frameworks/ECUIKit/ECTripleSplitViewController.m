//
//  ECTripleSplitViewController.m
//  edit
//
//  Created by Uri Baghin on 6/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTripleSplitViewController.h"
#import <QuartzCore/QuartzCore.h>

static const void *ECTripleSplitViewControllerAssociatedObjectKey;

@interface UIViewController (ECTripleSplitViewControllerInternal)
@property (nonatomic, weak) ECTripleSplitViewController *tripleSplitViewController;
@end

@implementation UIViewController (ECTripleSplitViewControllerInternal)

- (ECTripleSplitViewController *)tripleSplitViewController
{
    return objc_getAssociatedObject(self, ECTripleSplitViewControllerAssociatedObjectKey);
}

- (void)setTripleSplitViewController:(ECTripleSplitViewController *)tripleSplitViewController
{
    objc_setAssociatedObject(self, ECTripleSplitViewControllerAssociatedObjectKey, tripleSplitViewController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

static const NSString *ECTripleSplitViewControllerTransitionKey = @"ECTripleSplitViewControllerTransitionKey";

static const CGFloat ECTripleSplitViewControllerAnimationDuration = 0.15;

@interface ECTripleSplitViewController ()
{
    UIView *_menuView;
    UIView *_sidebarView;
    UIView *_mainView;
}
@property (nonatomic, strong) void (^_layoutBlock)(void);
- (void)setup;
- (void)layoutSubviewsWithAnimation:(BOOL)animated;
@end

@implementation ECTripleSplitViewController

@synthesize delegate = _delegate;
@synthesize menuController = _menuController;
@synthesize sidebarController = _sidebarController;
@synthesize mainController = _mainController;
@synthesize menuWidth = _menuWidth;
@synthesize sidebarWidth = _sidebarWidth;
@synthesize sidebarHidden = _sidebarHidden;
@synthesize _layoutBlock = __layoutBlock;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    [self setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self)
        return nil;
    [self setup];
    return self;
}

- (void)setup
{
    _menuWidth = 50.0;
    _sidebarWidth = 200.0;
}

- (void)setMenuController:(UIViewController *)menuController
{
    [self setMenuController:menuController withTransition:nil];
}

- (void)setMenuController:(UIViewController *)menuController withTransition:(CATransition *)transition
{
    if (menuController == _menuController)
        return;
    _menuController.tripleSplitViewController = nil;
    _menuController = menuController;
    menuController.tripleSplitViewController = self;
    if (!_menuView)
        return;
    [_menuView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_menuView addSubview:menuController.view];
    menuController.view.frame = _menuView.bounds;
    if (transition)
        [_menuView.layer addAnimation:transition forKey:(NSString *)ECTripleSplitViewControllerTransitionKey];
}

- (void)setSidebarController:(UIViewController *)sidebarController
{
    [self setSidebarController:sidebarController withTransition:nil];
}

- (void)setSidebarController:(UIViewController *)sidebarController withTransition:(CATransition *)transition
{
    if (sidebarController == _sidebarController)
        return;
    _sidebarController.tripleSplitViewController = nil;
    _sidebarController = sidebarController;
    sidebarController.tripleSplitViewController = self;
    if (!_sidebarView)
        return;
    [_sidebarView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_sidebarView addSubview:sidebarController.view];
    sidebarController.view.frame = _sidebarView.bounds;
    if (transition)
        [_sidebarView.layer addAnimation:transition forKey:(NSString *)ECTripleSplitViewControllerTransitionKey];
}

- (void)setMainController:(UIViewController *)mainController
{
    [self setMainController:mainController withTransition:nil];
}

- (void)setMainController:(UIViewController *)mainController withTransition:(CATransition *)transition
{
    if (mainController == _mainController)
        return;
    _mainController.tripleSplitViewController = nil;
    _mainController = mainController;
    mainController.tripleSplitViewController = self;
    if (!_mainView)
        return;
    [_mainView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_mainView addSubview:mainController.view];
    mainController.view.frame = _mainView.bounds;
    if (transition)
        [_mainView.layer addAnimation:transition forKey:(NSString *)ECTripleSplitViewControllerTransitionKey];
}

- (void)setMenuWidth:(CGFloat)menuWidth
{
    if (menuWidth == _menuWidth)
        return;
    _menuWidth = menuWidth;
    [self layoutSubviewsWithAnimation:NO];
}

- (void)setSidebarWidth:(CGFloat)sidebarWidth
{
    if (sidebarWidth == _sidebarWidth)
        return;
    _sidebarWidth = sidebarWidth;
    [self layoutSubviewsWithAnimation:NO];
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
        [self.sidebarController viewWillDisappear:animated];
        if (animated)
        {
            [UIView animateWithDuration:ECTripleSplitViewControllerAnimationDuration animations:^{
                CGRect frame = _sidebarView.frame;
                frame.size.width = 0.0;
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
            _sidebarView = [[UIView alloc] initWithFrame:CGRectMake(self.menuWidth, 0.0, 0.0, self.view.frame.size.height)];
            _sidebarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:_sidebarView];
            if (self.sidebarController)
            {
                [_sidebarView addSubview:self.sidebarController.view];
                self.sidebarController.view.frame = _sidebarView.bounds;
            }
            [UIView animateWithDuration:ECTripleSplitViewControllerAnimationDuration animations:self._layoutBlock];
        }
        else
            self._layoutBlock();
        [self.sidebarController viewDidAppear:animated];
    }
}

- (void (^)(void))_layoutBlock
{
    if (!__layoutBlock)
        __layoutBlock = [^{
            CGRect frame = self.view.frame;
            CGRect menuFrame = CGRectMake(0.0, 0.0, self.menuWidth, frame.size.height);
            CGRect sidebarFrame = CGRectMake(self.menuWidth, 0.0, self.sidebarWidth, frame.size.height);
            CGRect mainFrame = CGRectMake(self.menuWidth + (self.sidebarHidden ? 0.0 : self.sidebarWidth), 0.0, frame.size.width - self.menuWidth - (self.sidebarHidden ? 0.0 : self.sidebarWidth), frame.size.height);
            if (!_menuView)
            {
                _menuView = [[UIView alloc] initWithFrame:menuFrame];
                _menuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [self.view addSubview:_menuView];
                if (self.menuController)
                {
                    [_menuView addSubview:self.menuController.view];
                    self.menuController.view.frame = _menuView.bounds;
                }
            }
            _menuView.frame = menuFrame;
            if (!self.sidebarHidden)
            {
                if (!_sidebarView)
                {
                    _sidebarView = [[UIView alloc] initWithFrame:sidebarFrame];
                    _sidebarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    [self.view addSubview:_sidebarView];
                    if (self.sidebarController)
                    {
                        [_sidebarView addSubview:self.sidebarController.view];
                        self.sidebarController.view.frame = _sidebarView.bounds;
                    }
                }
                _sidebarView.frame = sidebarFrame;
            }
            if (!_mainView)
            {
                _mainView = [[UIView alloc] initWithFrame:mainFrame];
                _mainView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [self.view addSubview:_mainView];
                if (self.mainController)
                {
                    [_mainView addSubview:self.mainController.view];
                    self.mainController.view.frame = _mainView.bounds;
                }
            }
            _mainView.frame = mainFrame;
        } copy];
    return __layoutBlock;
}

- (void)layoutSubviewsWithAnimation:(BOOL)animated
{
    if (animated)
        [UIView animateWithDuration:ECTripleSplitViewControllerAnimationDuration animations:self._layoutBlock];
    else
        self._layoutBlock();
}

- (void)viewDidLoad
{
    [self layoutSubviewsWithAnimation:NO];
}

- (void)viewDidUnload
{
    _menuView = nil;
    _sidebarView = nil;
    _mainView = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self.menuController didReceiveMemoryWarning];
    [self.sidebarController didReceiveMemoryWarning];
    [self.mainController didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.menuController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.sidebarController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.mainController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.menuController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.sidebarController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.mainController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.menuController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.sidebarController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.mainController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self layoutSubviewsWithAnimation:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.menuController viewWillAppear:animated];
    [self.sidebarController viewWillAppear:animated];
    [self.mainController viewWillAppear:animated];
    [self layoutSubviewsWithAnimation:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.menuController viewDidAppear:animated];
    [self.sidebarController viewDidAppear:animated];
    [self.mainController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.menuController viewWillDisappear:animated];
    [self.sidebarController viewWillDisappear:animated];
    [self.mainController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.menuController viewDidDisappear:animated];
    [self.sidebarController viewDidDisappear:animated];
    [self.mainController viewDidDisappear:animated];
}

@end
