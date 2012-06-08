//
//  TabController.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 29/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//


#import "TabController.h"
#import "UIView+ReuseIdentifier.h"
#import "BezelAlert.h"

#define TABBAR_HEIGHT 40

/// A scroll view that can perform custom code blocks on common overloaded operations.
@interface CustomizableScrollView : UIScrollView

@property (nonatomic, copy) void (^layoutSubviewsBlock)(UIScrollView *view);

@end

@implementation CustomizableScrollView

@synthesize layoutSubviewsBlock;

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  if (layoutSubviewsBlock)
    layoutSubviewsBlock(self);
}

@end

@interface TabController ()

- (void)_layoutChildViews;
- (void)_loadSelectedAndAdiacentTabViews;
- (void)_scrollToSelectedViewControllerAnimated:(BOOL)animated;

@end

@implementation TabController {
  NSMutableArray *_orderedChildViewControllers;
  CustomizableScrollView *_contentScrollView;
  BOOL _keepCurrentPageCentered;
}

#pragma mark - Properties

@synthesize tabBar = _tabBar, tabBarVisible = _tabBarVisible;
@synthesize contentScrollView = _contentScrollView, tabPageMargin;
@synthesize selectedViewControllerIndex = _selectedViewControllerIndex;

- (TabBar *)tabBar
{
  if (_tabBar == nil)
  {
    // Creating tab bar
    _tabBar = [[TabBar alloc] initWithFrame:CGRectMake(0, 0, 300, TABBAR_HEIGHT)];
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
  
  _tabBarVisible = value;
  
  if (self.isViewLoaded)
  {
    if (_tabBarVisible)
      [self.view addSubview:self.tabBar];
    if (animated)
    {
      [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self _layoutChildViews]; 
      } completion:^(BOOL finished) {
        if (finished && !_tabBarVisible)
          [self.tabBar removeFromSuperview];
      }];
    }
    else
    {
      [self _layoutChildViews];
      if (!_tabBarVisible)
        [self.tabBar removeFromSuperview];
    }
  }
}

- (UIView *)contentScrollView
{
  if (_contentScrollView == nil)
  {
    // Creating the content view
    _contentScrollView = [[CustomizableScrollView alloc] init];
    _contentScrollView.delegate = self;
    _contentScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _contentScrollView.backgroundColor = [UIColor clearColor];
    _contentScrollView.pagingEnabled = YES;
    _contentScrollView.showsVerticalScrollIndicator = NO;
    _contentScrollView.showsHorizontalScrollIndicator = NO;
    _contentScrollView.panGestureRecognizer.minimumNumberOfTouches = 3;
    _contentScrollView.panGestureRecognizer.maximumNumberOfTouches = 3;
    
    // Custom layout
    __weak TabController *this = self;
    _contentScrollView.layoutSubviewsBlock = ^(UIScrollView *scrollView) {
      CGRect bounds = scrollView.bounds;
      NSUInteger tabControllersCount = [this->_orderedChildViewControllers count];
      
      // Will keep the page centered in case of device rotation
      if (this->_keepCurrentPageCentered)
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
      for (UIViewController *tabController in this->_orderedChildViewControllers)
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
  tabPageMargin = margin;
  
  [self _layoutChildViews];
  [self.contentScrollView setNeedsLayout];
}

- (NSArray *)childViewControllers
{
  return _orderedChildViewControllers;
}

- (UIViewController *)selectedViewController
{
  if (_selectedViewControllerIndex == NSNotFound)
    return nil;
  
  return [_orderedChildViewControllers objectAtIndex:_selectedViewControllerIndex];
}

- (void)setSelectedViewControllerIndex:(NSUInteger)index
{
  [self setSelectedViewControllerIndex:index animated:NO];
}

- (void)setSelectedViewControllerIndex:(NSUInteger)index animated:(BOOL)animated
{ 
  [self.tabBar setSelectedTabIndex:index animated:animated];
}

#pragma mark - Controller initialization

static void init(TabController *self)
{
  self->_selectedViewControllerIndex = NSNotFound;
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
  
  [self _layoutChildViews];
  [self _loadSelectedAndAdiacentTabViews];
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
  
  if (_selectedViewControllerIndex == NSNotFound && [_orderedChildViewControllers count] > 0) {
    _selectedViewControllerIndex = 0;
  }
  [self _scrollToSelectedViewControllerAnimated:animated];
}

// TODO: all messages automatically forwarded to child view controllers should be managed manually

#pragma mark Handling rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  // Makes the current tab view to be centered in the scroll view during device orientation
  _keepCurrentPageCentered = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  _keepCurrentPageCentered = NO;
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
  if (_orderedChildViewControllers == nil)
    _orderedChildViewControllers = [NSMutableArray new];
  [_orderedChildViewControllers addObject:childController];
  
  // RAC Add tab button
  [self.tabBar addTabWithTitle:childController.title animated:animated];
  [[[RACAble(childController, title) distinctUntilChanged] injectObjectWeakly:childController] subscribeNext:^(RACTuple *tuple) {
    if (tuple.first != [RACTupleNil tupleNil] && tuple.second) {
      [self.tabBar setTitle:tuple.first forTabAtIndex:[_orderedChildViewControllers indexOfObject:tuple.second]];
    }
  }];
  
  // Set selection
  [self setSelectedViewControllerIndex:([_orderedChildViewControllers count] - 1) animated:animated];
  
  [childController didMoveToParentViewController:self];
}

- (void)removeChildViewController:(UIViewController *)childController animated:(BOOL)animated {
  NSUInteger controllerIndex = [_orderedChildViewControllers indexOfObject:childController];
  ASSERT(controllerIndex != NSNotFound);
  [self.tabBar removeTabAtIndex:controllerIndex animated:animated];
}

- (void)moveChildViewControllerAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex animated:(BOOL)animated
{
  ASSERT(fromIndex < [_orderedChildViewControllers count]);
  ASSERT(toIndex < [_orderedChildViewControllers count]);
  
  [self.tabBar moveTabAtIndex:fromIndex toIndex:toIndex animated:animated];
  
  [self tabBar:self.tabBar didMoveTabControl:nil fromIndex:fromIndex toIndex:toIndex];
}

#pragma mark - Tab bar delegate methods

- (BOOL)tabBar:(TabBar *)tabBar willSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)index {
  // If view is not loaded just update the selected index
  if (!self.isViewLoaded || self.view.window == nil) {
    _selectedViewControllerIndex = index;
    return YES;
  }
  
  UIViewController *toViewController = nil;
  
  // Get the child view controller to display
  if (index != NSNotFound) {
    ASSERT(index < [_orderedChildViewControllers count]);
    toViewController = [_orderedChildViewControllers objectAtIndex:index];
  }
  
  // Crossfade if non adiacent
  _selectedViewControllerIndex = index;
  [self _scrollToSelectedViewControllerAnimated:NO];
  [UIView transitionWithView:self.contentScrollView duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:nil completion:nil];
  
  return YES;
}

- (BOOL)tabBar:(TabBar *)tabBar willRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex
{
  // If only one tab is open, don't allow it to be closed
  if (tabBar.tabControls.count <= 1) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Tab cannot be closed" image:nil displayImmediatly:YES];
    return NO;
  }
  
  UIViewController *controller = [_orderedChildViewControllers objectAtIndex:tabIndex];
  [controller willMoveToParentViewController:nil];
  
  // Remove from tab controller
  [_orderedChildViewControllers removeObjectAtIndex:tabIndex];
  [controller removeFromParentViewController];
  
  // Remove view if loaded
  if (controller.isViewLoaded)
    [controller.view removeFromSuperview];
  
  return YES;
}

- (void)tabBar:(TabBar *)tabBar didRemoveTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex {
  // Change selection if needed
  if (_selectedViewControllerIndex == tabIndex)
  {
    _selectedViewControllerIndex = -2;
    if (tabIndex > 0)
      tabIndex -= 1;
    if (tabIndex < [_orderedChildViewControllers count])
      [self setSelectedViewControllerIndex:tabIndex animated:YES];
    else
      _selectedViewControllerIndex = NSNotFound;
  }
  else
  {
    [self _scrollToSelectedViewControllerAnimated:YES];
  }
}

- (void)tabBar:(TabBar *)tabBar didMoveTabControl:(UIControl *)tabControl fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
  id obj = [_orderedChildViewControllers objectAtIndex:fromIndex];
  [_orderedChildViewControllers removeObjectAtIndex:fromIndex];
  [_orderedChildViewControllers insertObject:obj atIndex:toIndex];
  
  if (_selectedViewControllerIndex == fromIndex)
    _selectedViewControllerIndex = toIndex;
  else if (_selectedViewControllerIndex > fromIndex)
    _selectedViewControllerIndex -= _selectedViewControllerIndex > toIndex ? 0 : 1;
  else if (_selectedViewControllerIndex >= toIndex)
    _selectedViewControllerIndex += _selectedViewControllerIndex > fromIndex ? 0 : 1;
  
  // Reposition content scroll view to 
  [self _scrollToSelectedViewControllerAnimated:NO];
}

#pragma mark - Scroll view delegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  // Get current tab index
  CGRect pageBounds = self.contentScrollView.bounds;
  NSUInteger tabControllersCount = [_orderedChildViewControllers count];
  NSInteger currentTabIndex = (NSUInteger)roundf(pageBounds.origin.x / pageBounds.size.width);
  if (currentTabIndex < 0)
    currentTabIndex = 0;
  else if (currentTabIndex >= (NSInteger)tabControllersCount)
    currentTabIndex = tabControllersCount - 1;
  
  // Return if already on this tab
  if (currentTabIndex == (NSInteger)_selectedViewControllerIndex)
    return;
  
  // Select tab button
  [self.tabBar setSelectedTabIndex:currentTabIndex animated:YES];
}

#pragma mark - Private methods

- (void)_layoutChildViews
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

- (void)_loadSelectedAndAdiacentTabViews
{
  if (!self.isViewLoaded)
    return;
  
  NSUInteger minLoadableIndex = _selectedViewControllerIndex > 0 ? _selectedViewControllerIndex - 1 : _selectedViewControllerIndex;
  NSUInteger maxLoadableIndex = _selectedViewControllerIndex < [_orderedChildViewControllers count] - 1 ? _selectedViewControllerIndex + 1 : _selectedViewControllerIndex;
  
  [_orderedChildViewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger index, BOOL *stop) {
    // Load view if current or diacent to current
    if (index >= minLoadableIndex && index <= maxLoadableIndex)
    {
      if (viewController.view.superview == nil)
      {
        [self.contentScrollView addSubview:viewController.view];
        viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      }
      else
      {
        [self.contentScrollView setNeedsLayout];
      }
    }
    else if (viewController.isViewLoaded)
    {
      [viewController.view removeFromSuperview];
    }
  }];
}

- (void)_scrollToSelectedViewControllerAnimated:(BOOL)animated {
  [self _loadSelectedAndAdiacentTabViews];
  [self.contentScrollView layoutIfNeeded];
  CGFloat pageWidth = self.contentScrollView.bounds.size.width;
  [self.contentScrollView scrollRectToVisible:CGRectMake(pageWidth * _selectedViewControllerIndex, 0, pageWidth, 1) animated:animated];
}

@end


@implementation UIViewController (TabController)

- (TabController *)tabCollectionController
{
  UIViewController *result = self;
  while (result && ![result isKindOfClass:[TabController class]])
    result = result.parentViewController;
  return (TabController *)result;
}

@end
