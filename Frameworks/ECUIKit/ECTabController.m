//
//  ECTabController.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 29/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


#import "ECTabController.h"
#import "UIView+ReuseIdentifier.h"

#define TABBAR_HEIGHT 44


@interface ECTabController () {
    NSMutableArray *orderedChildViewControllers;
}

@property (nonatomic, readonly, strong) UIView *contentView;
@end

@implementation ECTabController

#pragma mark - Properties

@synthesize tabBar = _tabBar, contentView = _contentView;
@synthesize selectedViewControllerIndex;

- (ECTabBar *)tabBar
{
    if (_tabBar == nil)
    {
        // Creating tab bar
        _tabBar = [[ECTabBar alloc] init];
        _tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _tabBar.delegate = self;
    }
    return _tabBar;
}

- (UIView *)contentView
{
    if (_contentView == nil)
    {
        // Creating the content view
        _contentView = [[UIView alloc] init];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (NSArray *)childViewControllers
{
    return orderedChildViewControllers;
}

- (UIViewController *)selectedViewController
{
    if (selectedViewControllerIndex == NSNotFound)
        return nil;
    
    return [orderedChildViewControllers objectAtIndex:selectedViewControllerIndex];
}

- (void)setSelectedViewControllerIndex:(NSUInteger)index
{
    [self setSelectedViewControllerIndex:index animated:NO];
}

- (void)setSelectedViewControllerIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (selectedViewControllerIndex == index)
        return;
        
    [self.tabBar setSelectedTabIndex:index animated:animated];
}

#pragma mark - Controller initialization

static void init(ECTabController *self)
{
    self->selectedViewControllerIndex = NSNotFound;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder]))
    {
        init(self);
    }
    return self;
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)loadView
{
    [super loadView];
    
    CGRect bounds = self.view.bounds;
    
    // Creating tab bar
    self.tabBar.frame = CGRectMake(0, 0, bounds.size.width, TABBAR_HEIGHT);
    self.tabBar.backgroundColor = [UIColor grayColor];
    [self.view addSubview:self.tabBar];
    
    // Creating the content view
    self.contentView.frame = CGRectMake(0, TABBAR_HEIGHT, bounds.size.width, bounds.size.height - TABBAR_HEIGHT);
    [self.view addSubview:self.contentView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _tabBar = nil;
    _contentView = nil;
}

#pragma mark - Managing tabs

- (void)addChildViewController:(UIViewController *)childController
{
    [self addChildViewController:childController animated:NO];
}

- (void)addChildViewController:(UIViewController *)childController animated:(BOOL)animated
{
    [super addChildViewController:childController];
    
    // Adding to ordered array of controllers
    if (orderedChildViewControllers == nil)
        orderedChildViewControllers = [NSMutableArray new];
    [orderedChildViewControllers addObject:childController];
    
    // Add tab button
    [self.tabBar addTabWithTitle:childController.navigationItem.title animated:animated];
    
    // Set selection
    if (self.selectedViewControllerIndex == NSNotFound)
        [self setSelectedViewControllerIndex:([orderedChildViewControllers count] - 1) animated:animated];
    
    [childController didMoveToParentViewController:self];
}

- (void)removeChildViewControllerAtIndex:(NSUInteger)controllerIndex animated:(BOOL)animated
{
    ECASSERT(controllerIndex < [orderedChildViewControllers count]);
    
    [self.tabBar removeTabControlAtIndex:controllerIndex animated:animated];
}

- (void)moveChildViewControllerAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated
{
    ECASSERT(fromIndex < [orderedChildViewControllers count]);
    ECASSERT(toIndex < [orderedChildViewControllers count]);
    
    [self.tabBar moveTabControlAtIndex:fromIndex toIndex:toIndex animated:animated];
    
    [self tabBar:self.tabBar didMoveTabControl:nil fromIndex:fromIndex toIndex:toIndex];
}

#pragma mark - Tab bar delegate methods

- (UIControl *)tabBar:(ECTabBar *)tabBar controlForTabWithTitle:(NSString *)title atIndex:(NSUInteger)tabIndex
{
    static NSString *tabButtonIdentifier = @"TabButton";
    
    UIButton *control = (UIButton *)[tabBar dequeueReusableTabControlWithIdentifier:tabButtonIdentifier];
    if (control == nil)
    {
        control = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        control.reuseIdentifier = tabButtonIdentifier;
    }
    [control setTitle:title forState:UIControlStateNormal];
    // TODO close button
    return control;
}

- (BOOL)tabBar:(ECTabBar *)tabBar willSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)index
{
    UIViewController *toViewController = nil;
    if (index != NSNotFound)
    {
        ECASSERT(index < [orderedChildViewControllers count]);
        toViewController = [orderedChildViewControllers objectAtIndex:index];
        toViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    
    UIViewController *fromViewController = self.selectedViewController;
    toViewController.view.alpha = 0;
    toViewController.view.frame = self.contentView.bounds;
    [self.contentView addSubview:toViewController.view];
    [UIView animateWithDuration:0.20 animations:^{
        toViewController.view.alpha = 1;
        fromViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [fromViewController.view removeFromSuperview];
    }];
    
    selectedViewControllerIndex = index;
    
    return YES;
}

- (BOOL)tabBar:(ECTabBar *)tabBar willRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex
{ 
    UIViewController *controller = [orderedChildViewControllers objectAtIndex:tabIndex];
    [controller willMoveToParentViewController:nil];
    
    [orderedChildViewControllers removeObject:controller];

    // Change selection if needed
    if (self.selectedViewControllerIndex == tabIndex)
    {
        if (tabIndex > 0)
            tabIndex -= 1;
        if (tabIndex < [orderedChildViewControllers count])
            [self setSelectedViewControllerIndex:tabIndex animated:YES];
        else
            self.selectedViewControllerIndex = NSNotFound;
    }
    
    [controller removeFromParentViewController];
    
    return YES;
}

- (void)tabBar:(ECTabBar *)tabBar didMoveTabControl:(UIControl *)tabControl fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    id obj = [orderedChildViewControllers objectAtIndex:fromIndex];
    [orderedChildViewControllers removeObjectAtIndex:fromIndex];
    [orderedChildViewControllers insertObject:obj atIndex:toIndex];
    
    if (selectedViewControllerIndex == fromIndex)
        selectedViewControllerIndex = toIndex;
    else if (selectedViewControllerIndex > fromIndex)
        selectedViewControllerIndex -= selectedViewControllerIndex > toIndex ? 0 : 1;
    else if (selectedViewControllerIndex >= toIndex)
        selectedViewControllerIndex += selectedViewControllerIndex > fromIndex ? 0 : 1;
}

@end
