//
//  ECTabController.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 29/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


#import "ECTabController.h"
#import "UIView+ReuseIdentifier.h"
#import "ECCustomizableScrollView.h"

#define TABBAR_HEIGHT 40

static void *childViewControllerTitleContext;

@interface ECTabController () {
    NSMutableArray *orderedChildViewControllers;
    
    BOOL keepCurrentPageCentered;
}

@property (nonatomic, readonly, strong) ECCustomizableScrollView *contentScrollView;

- (void)layoutChildViews;
- (void)loadSelectedAndAdiacentTabViews;
- (void)scrollToSelectedViewControllerAnimated:(BOOL)animated;

@end

@implementation ECTabController

#pragma mark - Properties

@synthesize tabBar = _tabBar, tabBarVisible = _tabBarVisible;
@synthesize contentScrollView = _contentScrollView, tabPageMargin;
@synthesize selectedViewControllerIndex;

- (ECTabBar *)tabBar
{
    if (_tabBar == nil)
    {
        // Creating tab bar
        _tabBar = [[ECTabBar alloc] initWithFrame:CGRectMake(0, 0, 300, TABBAR_HEIGHT)];
        _tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _tabBar.delegate = self;
    }
    return _tabBar;
}

- (void)setTabBarVisible:(BOOL)tabBarVisible
{
    [self setTabBarVisible:tabBarVisible animated:NO];
}

- (void)setTabBarVisible:(BOOL)value animated:(BOOL)animated
{
    if (value == _tabBarVisible)
        return;
    
    [self willChangeValueForKey:@"showTabBar"];
    _tabBarVisible = value;
    
    if (self.isViewLoaded)
    {
        if (_tabBarVisible)
            [self.view addSubview:self.tabBar];
        if (animated)
        {
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
                [self layoutChildViews]; 
            } completion:^(BOOL finished) {
                if (finished && !_tabBarVisible)
                    [self.tabBar removeFromSuperview];
            }];
        }
        else
        {
            [self layoutChildViews];
            if (!_tabBarVisible)
                [self.tabBar removeFromSuperview];
        }
    }
    
    [self didChangeValueForKey:@"showTabBar"];
}

- (UIView *)contentScrollView
{
    if (_contentScrollView == nil)
    {
        // Creating the content view
        _contentScrollView = [[ECCustomizableScrollView alloc] init];
        _contentScrollView.delegate = self;
        _contentScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _contentScrollView.backgroundColor = [UIColor clearColor];
        _contentScrollView.pagingEnabled = YES;
        _contentScrollView.showsVerticalScrollIndicator = NO;
        _contentScrollView.showsHorizontalScrollIndicator = NO;
        _contentScrollView.panGestureRecognizer.minimumNumberOfTouches = 3;
        _contentScrollView.panGestureRecognizer.maximumNumberOfTouches = 3;
        
        // Custom layout
        __weak ECTabController *this = self;
        _contentScrollView.layoutSubviewsBlock = ^(UIScrollView *scrollView) {
            CGRect bounds = scrollView.bounds;
            NSUInteger tabControllersCount = [this->orderedChildViewControllers count];
            
            // Will keep the page centered in case of device rotation
            if (this->keepCurrentPageCentered)
            {
                NSUInteger currentPage = roundf(scrollView.contentOffset.x * tabControllersCount / scrollView.contentSize.width);
                scrollView.contentOffset = CGPointMake(currentPage * bounds.size.width, 0);
            }
            
            // Adjust content size
            scrollView.contentSize = CGSizeMake(bounds.size.width * tabControllersCount, 1);
            
            // Layout tab pages
            CGRect pageFrame = bounds;
            pageFrame.origin.x = this->tabPageMargin / 2;
            pageFrame.size.width -= this->tabPageMargin;
            for (UIViewController *tabController in this->orderedChildViewControllers)
            {
                if (tabController.isViewLoaded)
                {
                    tabController.view.frame = pageFrame;
                }
                pageFrame.origin.x += bounds.size.width;
            }
        };
    }
    return _contentScrollView;
}

- (void)setTabPageMargin:(CGFloat)margin
{
    [self willChangeValueForKey:@"tabPageMargin"];
    
    tabPageMargin = margin;
    
    [self layoutChildViews];
    [self.contentScrollView setNeedsLayout];
    
    [self didChangeValueForKey:@"tabPageMargin"];
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

- (void)setSelectedViewControllerIndex:(NSInteger)index
{
    [self setSelectedViewControllerIndex:index animated:NO];
}

- (void)setSelectedViewControllerIndex:(NSInteger)index animated:(BOOL)animated
{ 
    [self.tabBar setSelectedTabIndex:index animated:animated];
}

#pragma mark - Controller initialization

static void init(ECTabController *self)
{
    self->selectedViewControllerIndex = NSNotFound;
    self->_tabBarVisible = YES;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &childViewControllerTitleContext)
    {
        // Change title to tab button relative to observed child view controller.
        NSUInteger tabIndex = [orderedChildViewControllers indexOfObject:object];
        if (tabIndex != NSNotFound)
        {
            [self.tabBar setTitle:[object title] forTabAtIndex:tabIndex];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.isTabBarVisible)
        [self.view addSubview:self.tabBar];
    [self.view addSubview:self.contentScrollView];
    
    [self layoutChildViews];
    [self loadSelectedAndAdiacentTabViews];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _tabBar = nil;
    _contentScrollView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (selectedViewControllerIndex == NSNotFound && [orderedChildViewControllers count] > 0) {
        selectedViewControllerIndex = 0;
    }
    [self scrollToSelectedViewControllerAnimated:animated];
}

// TODO: all messages automatically forwarded to child view controllers should be managed manually

#pragma mark Handling rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Makes the current tab view to be centered in the scroll view during device orientation
    keepCurrentPageCentered = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    keepCurrentPageCentered = NO;
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
    [self.tabBar addTabWithTitle:childController.title animated:animated];
    [childController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:&childViewControllerTitleContext];
    
    // Set selection
    if (selectedViewControllerIndex == NSNotFound)
        [self setSelectedViewControllerIndex:([orderedChildViewControllers count] - 1) animated:animated];
    // Or load adiacent views
    else if (abs(selectedViewControllerIndex - ([orderedChildViewControllers count] - 1)) <= 1)
        [self loadSelectedAndAdiacentTabViews];
    
    [childController didMoveToParentViewController:self];
}

- (void)removeChildViewControllerAtIndex:(NSUInteger)controllerIndex animated:(BOOL)animated
{
    ECASSERT(controllerIndex < [orderedChildViewControllers count]);
    [self.tabBar removeTabAtIndex:controllerIndex animated:animated];
}

- (void)moveChildViewControllerAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated
{
    ECASSERT(fromIndex < [orderedChildViewControllers count]);
    ECASSERT(toIndex < [orderedChildViewControllers count]);
    
    [self.tabBar moveTabAtIndex:fromIndex toIndex:toIndex animated:animated];
    
    [self tabBar:self.tabBar didMoveTabControl:nil fromIndex:fromIndex toIndex:toIndex];
}

#pragma mark - Tab bar delegate methods

- (BOOL)tabBar:(ECTabBar *)tabBar willSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)index
{
    if (!self.isViewLoaded || self.view.window == nil)
    {
        selectedViewControllerIndex = index;
        return YES;
    }
    
    UIViewController *toViewController = nil;
    if (index != NSNotFound)
    {
        ECASSERT(index < [orderedChildViewControllers count]);
        toViewController = [orderedChildViewControllers objectAtIndex:index];
    }
    
    if (abs(selectedViewControllerIndex - (NSInteger)index) <= 1)
    {
        // Scroll if adiacent tab
        selectedViewControllerIndex = index;
        [self scrollToSelectedViewControllerAnimated:YES];
    }
    else
    {
        // Crossfade if non adiacent
        selectedViewControllerIndex = index;
        [self scrollToSelectedViewControllerAnimated:NO];
        [UIView transitionWithView:self.contentScrollView duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:nil];
    }
    
    return YES;
}

- (BOOL)tabBar:(ECTabBar *)tabBar willRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex
{ 
    UIViewController *controller = [orderedChildViewControllers objectAtIndex:tabIndex];
    [controller removeObserver:self forKeyPath:@"title"];
    [controller willMoveToParentViewController:nil];
    
    // Remove from tab controller
    [orderedChildViewControllers removeObject:controller];
    [controller removeFromParentViewController];

    // Change selection if needed
    if (self.selectedViewControllerIndex == tabIndex)
    {
        selectedViewControllerIndex = -2;
        if (tabIndex > 0)
            tabIndex -= 1;
        if (tabIndex < [orderedChildViewControllers count])
            [self setSelectedViewControllerIndex:tabIndex animated:YES];
        else
            self.selectedViewControllerIndex = NSNotFound;
    }
    else
    {
        [self scrollToSelectedViewControllerAnimated:YES];
    }
    
    // Remove view if loaded
    if (controller.isViewLoaded)
        [controller.view removeFromSuperview];
    
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
    
    // Reposition content scroll view to 
    [self scrollToSelectedViewControllerAnimated:NO];
}

#pragma mark - Scroll view delegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    // Get current tab index
    CGRect pageBounds = self.contentScrollView.bounds;
    NSUInteger tabControllersCount = [orderedChildViewControllers count];
    NSInteger currentTabIndex = (NSInteger)roundf(pageBounds.origin.x / pageBounds.size.width);
    if (currentTabIndex < 0)
        currentTabIndex = 0;
    else if (currentTabIndex >= tabControllersCount)
        currentTabIndex = tabControllersCount - 1;
    
    // Return if already on this tab
    if (currentTabIndex == selectedViewControllerIndex)
        return;
    
    // Select tab button
    [self.tabBar setSelectedTabIndex:currentTabIndex animated:YES];
}

#pragma mark - Private methods

- (void)layoutChildViews
{
    if (!self.isViewLoaded)
        return;
    
    CGRect bounds = self.view.bounds;
    
    // Layout tab bar
    if (self.tabBar.superview != nil)
        self.tabBar.frame = CGRectMake(0, self.isTabBarVisible ? 0 : -TABBAR_HEIGHT, bounds.size.width, TABBAR_HEIGHT);;
    
    // Creating the content view
    CGFloat tabBarActualHeight = self.isTabBarVisible ? TABBAR_HEIGHT : 0;
    self.contentScrollView.frame = CGRectMake(-tabPageMargin / 2, tabBarActualHeight, bounds.size.width + tabPageMargin, bounds.size.height - tabBarActualHeight);
}

- (void)loadSelectedAndAdiacentTabViews
{
    if (!self.isViewLoaded)
        return;
    
    NSUInteger minLoadableIndex = selectedViewControllerIndex > 0 ? selectedViewControllerIndex - 1 : selectedViewControllerIndex;
    NSUInteger maxLoadableIndex = selectedViewControllerIndex < [orderedChildViewControllers count] - 1 ? selectedViewControllerIndex + 1 : selectedViewControllerIndex;
    
    [orderedChildViewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger index, BOOL *stop) {
        // Load view if current or diacent to current
        if (index >= minLoadableIndex && index <= maxLoadableIndex)
        {
            if (viewController.view.superview == nil)
            {
                [viewController viewWillAppear:NO];
                [self.contentScrollView addSubview:viewController.view];
                viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                [viewController viewDidAppear:NO];
            }
            else
            {
                [self.contentScrollView setNeedsLayout];
            }
        }
        else if (viewController.isViewLoaded)
        {
            [viewController viewWillDisappear:NO];
            [viewController.view removeFromSuperview];
            [viewController viewDidDisappear:NO];
        }
    }];
}

- (void)scrollToSelectedViewControllerAnimated:(BOOL)animated
{
    [self loadSelectedAndAdiacentTabViews];
    [self.contentScrollView layoutIfNeeded];
    CGFloat pageWidth = self.contentScrollView.bounds.size.width;
    [self.contentScrollView scrollRectToVisible:CGRectMake(pageWidth * selectedViewControllerIndex, 0, pageWidth, 1) animated:animated];
}

@end


@implementation UIViewController (ECTabController)

- (ECTabController *)tabCollectionController
{
    UIViewController *result = self;
    while (result && ![result isKindOfClass:[ECTabController class]])
        result = result.parentViewController;
    return result;
}

@end
