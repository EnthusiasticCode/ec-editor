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

static void *ECTabControllerChildViewControllerContext;

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
    [UIView animateWithDuration:animated ? 0.20 : 0 animations:^{
        toViewController.view.alpha = 1;
        fromViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [fromViewController.view removeFromSuperview];
    }];
    
    selectedViewControllerIndex = index;
    
    [self.tabBar setSelectedTabIndex:index animated:animated];
}

#pragma mark - Controller initialization

static void init(ECTabController *self)
{
    self->selectedViewControllerIndex = NSNotFound;
    [self addObserver:self forKeyPath:@"childViewControllers" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:ECTabControllerChildViewControllerContext];
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

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"childViewControllers" context:ECTabControllerChildViewControllerContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ECTabControllerChildViewControllerContext)
    {
        if (orderedChildViewControllers == nil)
            orderedChildViewControllers = [NSMutableArray new];
        
        NSInteger kind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
        if (kind == NSKeyValueChangeInsertion)
        {
            NSIndexSet *changedValues = [change objectForKey:NSKeyValueChangeIndexesKey];
            NSArray *newChildViewController = [change objectForKey:NSKeyValueChangeNewKey];
            [newChildViewController enumerateObjectsAtIndexes:changedValues options:0 usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
                // Adding to ordered array of controllers
                [orderedChildViewControllers addObject:controller];
                
                // Add tab button
                [self.tabBar addTabWithTitle:controller.navigationItem.title animated:YES];
                
                // Set selection
                if (self.selectedViewControllerIndex == NSNotFound)
                    [self setSelectedViewControllerIndex:[orderedChildViewControllers count] - 1 animated:YES];
            }];
        }
        else if (kind == NSKeyValueChangeRemoval)
        {
            NSIndexSet *changedValues = [change objectForKey:NSKeyValueChangeIndexesKey];
            NSArray *oldChildViewController = [change objectForKey:NSKeyValueChangeOldKey];
            [oldChildViewController enumerateObjectsAtIndexes:changedValues options:0 usingBlock:^(UIViewController *controller, NSUInteger idx, BOOL *stop) {
                NSUInteger controllerIndex = [orderedChildViewControllers indexOfObject:controller];
                [orderedChildViewControllers removeObject:controller];
                
                // Remove from tab bar
                [self.tabBar removeTabControlAtIndex:controllerIndex animated:YES];
                
                // Change selection if needed
                if (self.selectedViewControllerIndex == controllerIndex)
                {
                    if (controllerIndex > 0)
                        controllerIndex -= 1;
                    if (controllerIndex < [orderedChildViewControllers count])
                        [self setSelectedViewControllerIndex:controllerIndex animated:YES];
                    else
                        self.selectedViewControllerIndex = NSNotFound;
                }
            }];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
    
    UIViewController *controller = [orderedChildViewControllers objectAtIndex:controllerIndex];
    [controller willMoveToParentViewController:nil];
    
    [orderedChildViewControllers removeObject:controller];
    
    // Remove from tab bar
    [self.tabBar removeTabControlAtIndex:controllerIndex animated:animated];
    
    // Change selection if needed
    if (self.selectedViewControllerIndex == controllerIndex)
    {
        if (controllerIndex > 0)
            controllerIndex -= 1;
        if (controllerIndex < [orderedChildViewControllers count])
            [self setSelectedViewControllerIndex:controllerIndex animated:animated];
        else
            self.selectedViewControllerIndex = NSNotFound;
    }
    
    [controller removeFromParentViewController];
}

- (void)moveChildViewControllerAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated
{
    ECASSERT(fromIndex < [orderedChildViewControllers count]);
    ECASSERT(toIndex < [orderedChildViewControllers count]);
    
    id obj = [orderedChildViewControllers objectAtIndex:fromIndex];
    [orderedChildViewControllers removeObjectAtIndex:fromIndex];
    [orderedChildViewControllers insertObject:obj atIndex:toIndex];
    
    [self.tabBar moveTabControlAtIndex:fromIndex toIndex:toIndex animated:animated];
    // TODO animation
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

- (void)tabBar:(ECTabBar *)tabBar didSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex
{
    [self setSelectedViewControllerIndex:tabIndex animated:YES];
}

@end
