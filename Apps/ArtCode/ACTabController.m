//
//  ACTabController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTabController.h"
#import "AppStyle.h"

#import "ECSwipeGestureRecognizer.h"

/// ACTab represent a tab with it's history. 
@interface ACTab : NSObject

@property (nonatomic, weak) UIButton *button;
@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic) NSUInteger historyPoint;
@property (nonatomic, weak) UIViewController<ACURLTarget> *viewController;

- (void)pushToHistory:(NSURL *)url;
- (void)popHistory;
- (NSURL *)historyPointURL;

@end


/// Customized UIScrollView to layout subviews as pages based on their tag.
@interface ACTabPagingScrollView : UIScrollView

@property (nonatomic) NSUInteger pageCount;
@property (nonatomic) BOOL keepCurrentPageCentered;
@property (nonatomic) CGFloat pageMargin;

@end


@implementation ACTabController {
    NSMutableArray *tabs;
    
    BOOL delegateHasDidShowTabAtIndexWithViewController;
}

#pragma mark - Properties

@synthesize delegate;
@synthesize tabPageMargin;
@synthesize contentScrollView;
@synthesize tabBar, tabBarEnabled;
@synthesize swipeGestureRecognizer;
@synthesize tabs, currentTabIndex;

- (void)setDelegate:(id<ACTabControllerDelegate>)aDelegate
{
    delegate = aDelegate;
    delegateHasDidShowTabAtIndexWithViewController = [delegate respondsToSelector:@selector(tabController:didShowTabAtIndex:withViewController:)];
}

- (void)setTabBarEnabled:(BOOL)enabled
{
    if (enabled == tabBarEnabled)
        return;
    
    tabBarEnabled = enabled;
    
    // TODO instead of disable, show message that you need to choose a project to enable tabs
    swipeGestureRecognizer.enabled = enabled;
    
    if (!tabBarEnabled)
        [self toggleTabBar:nil];
}

- (void)setTabPageMargin:(CGFloat)margin
{
    tabPageMargin = margin;
    
    CGRect contentScrollViewFrame = self.view.bounds;
    contentScrollViewFrame.origin.x -= tabPageMargin / 2;
    contentScrollViewFrame.size.width += tabPageMargin;
    contentScrollView.frame = contentScrollViewFrame;
    
    [(ACTabPagingScrollView *)contentScrollView setPageMargin:margin];
}

#pragma mark - Private Methods

- (ACTab *)tabAtIndex:(NSUInteger)tabIndex
{
    ECASSERT(tabIndex == ACTabCurrent || tabIndex >= 0 && tabIndex < [tabs count]);
    if (tabIndex == ACTabCurrent)
        tabIndex = currentTabIndex;
    return [tabs objectAtIndex:tabIndex];
}

- (void)loadAndPositionViewControllerForTab:(ACTab *)tab animated:(BOOL)animated
{
    NSURL *url = [tab historyPointURL];
    if (url == nil)
        return;
    
    // Gets tab page position
    CGRect tabFrame = contentScrollView.bounds;
    NSInteger tabPage = (NSInteger)[tabBar indexOfTab:tab.button];
    NSInteger currentPage = (NSInteger)(tabFrame.origin.x / tabFrame.size.width);
    
    // Load new controller
    UIViewController<ACURLTarget> *oldController = tab.viewController;
    UIViewController<ACURLTarget> *tabController = [delegate tabController:self viewControllerForURL:url previousViewController:oldController];
    
    // Assign to tab and navigate
    tab.viewController = tabController;
    [tab.viewController openURL:url];
    
    // Set view tag used by custom paging scrollview to layout pages
    tabController.view.tag = tabPage;
    [contentScrollView setNeedsLayout];
    
    // Transition if neccessary
    if (oldController != tabController)
    {
        // TODO check if this also remove the view
        [oldController removeFromParentViewController];
        [self addChildViewController:tabController];
        
        // Account for tab gesture recognizer
        if ([tabController.view isKindOfClass:[UIScrollView class]])
        {
            UIScrollView *scrollView = (UIScrollView *)tabController.view;
            [scrollView.panGestureRecognizer requireGestureRecognizerToFail:swipeGestureRecognizer];
        }
        
        // Transition controllers' view
        if (animated && tabPage == currentPage)
        {
            [UIView transitionFromView:oldController.view toView:tabController.view duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
                [oldController.view removeFromSuperview];
            }];
        }
        else
        {
            [oldController.view removeFromSuperview];
            [contentScrollView addSubview:tabController.view];
        }
    }
}

- (void)setCurrentTabIndex:(NSUInteger)tabIndex scroll:(BOOL)scroll animated:(BOOL)animated
{
    if (tabIndex == currentTabIndex || tabIndex == ACTabCurrent || tabIndex >= [tabs count])
        return;
    
    currentTabIndex = tabIndex;
    
    ACTab *tab = [self tabAtIndex:tabIndex];
    
    // Select tab
    [tabBar setSelectedTabIndex:tabIndex];
    
    // Load and position current tab
    if (tab.viewController == nil)
        [self loadAndPositionViewControllerForTab:tab animated:animated];
    else
        tab.viewController.view.tag = tabIndex;
    
    // Scroll to tab controller
    if (scroll)
    {
        CGRect tabFrame = contentScrollView.bounds;
        tabFrame.origin.x = tabIndex * tabFrame.size.width;
        [contentScrollView scrollRectToVisible:tabFrame animated:animated];
    }
    
    // Load and position adiacent tabs controllers
    NSMutableIndexSet *hiddenTabsIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [tabs count])];
    [hiddenTabsIndexes removeIndex:tabIndex];
    if (tabIndex > 0)
    {
        ACTab *prevTab = (ACTab *)[tabs objectAtIndex:tabIndex - 1];
        if (prevTab.viewController == nil)
            [self loadAndPositionViewControllerForTab:prevTab animated:NO];
        else
            prevTab.viewController.view.tag = tabIndex - 1;
        [hiddenTabsIndexes removeIndex:tabIndex - 1];
    }
    if (tabIndex + 1 < [tabs count])
    {
        ACTab *postTab = (ACTab *)[tabs objectAtIndex:tabIndex + 1];
        if (postTab.viewController == nil)
            [self loadAndPositionViewControllerForTab:postTab animated:NO];
        else
            postTab.viewController.view.tag = tabIndex + 1;
        [hiddenTabsIndexes removeIndex:tabIndex + 1];
    }
    
    // Cleanup non used child controllers
    [tabs enumerateObjectsAtIndexes:hiddenTabsIndexes options:0 usingBlock:^(ACTab *t, NSUInteger idx, BOOL *stop) {
        [t.viewController.view removeFromSuperview];
        [t.viewController removeFromParentViewController];
    }];
    
    // Call delegate
    if (delegateHasDidShowTabAtIndexWithViewController)
        [delegate tabController:self didShowTabAtIndex:tabIndex withViewController:tab.viewController];
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    if (!tabBar)
        tabBar = [[ECTabBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    tabBar.delegate = self;
    tabBar.alwaysBounceHorizontal = YES;
    tabBar.backgroundColor = [UIColor styleForegroundColor];
    tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    ////////////////////////////////////////////////////////////////////////////
    // Additional buttons
    UIButton *addTabButton = [UIButton new];
    [addTabButton setImage:[UIImage styleAddImageWithColor:[UIColor styleBackgroundColor] shadowColor:nil] forState:UIControlStateNormal];
    addTabButton.adjustsImageWhenHighlighted = NO;
    
    UIButton *closeTabBarButton = [UIButton new];
    [closeTabBarButton addTarget:self action:@selector(toggleTabBar:) forControlEvents:UIControlEventTouchUpInside];
    [closeTabBarButton setImage:[UIImage styleDisclosureArrowImageWithOrientation:UIImageOrientationUp color:[UIColor styleBackgroundColor]] forState:UIControlStateNormal];
    closeTabBarButton.adjustsImageWhenHighlighted = NO;
    
    tabBar.additionalControls = [NSArray arrayWithObjects:addTabButton, closeTabBarButton, nil];
    
    ////////////////////////////////////////////////////////////////////////////
    // Tab Bar gesture recognizer
    if (!swipeGestureRecognizer)
        swipeGestureRecognizer = [[ECSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleTabBar:)];
    swipeGestureRecognizer.numberOfTouchesRequired = 3;
    swipeGestureRecognizer.numberOfTouchesRequiredImmediatlyOrFailAfterInterval = .05;
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    swipeGestureRecognizer.enabled = tabBarEnabled;
    
    ////////////////////////////////////////////////////////////////////////////
    // Content scroll view
    if (!contentScrollView)
    {
        CGRect contentScrollViewFrame = self.view.bounds;
        contentScrollViewFrame.origin.x -= tabPageMargin / 2;
        contentScrollViewFrame.size.width += tabPageMargin;
        contentScrollView = [[ACTabPagingScrollView alloc] initWithFrame:contentScrollViewFrame];
        contentScrollView.delegate = self;
        [(ACTabPagingScrollView *)contentScrollView setPageMargin:tabPageMargin];
        [self.view addSubview:contentScrollView];
    }
    contentScrollView.backgroundColor = [UIColor styleForegroundColor];
    contentScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentScrollView.pagingEnabled = YES;
    contentScrollView.showsVerticalScrollIndicator = NO;
    contentScrollView.showsHorizontalScrollIndicator = NO;
    contentScrollView.panGestureRecognizer.minimumNumberOfTouches = 3;
    contentScrollView.panGestureRecognizer.maximumNumberOfTouches = 3;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    tabBar = nil;
    swipeGestureRecognizer = nil;
    contentScrollView = nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [(ACTabPagingScrollView *)contentScrollView setKeepCurrentPageCentered:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [(ACTabPagingScrollView *)contentScrollView setKeepCurrentPageCentered:NO];
}

- (BOOL)isEditing
{
    ACTab *tab = [self tabAtIndex:currentTabIndex];
    return tab.viewController.isEditing;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    // Forward editing calls to current tab controller
    ACTab *tab = [self tabAtIndex:currentTabIndex];
    [tab.viewController setEditing:editing animated:animated];
}

#pragma mark - TabBar Methods

- (BOOL)tabBar:(ECTabBar *)tabBar shouldAddTabButton:(UIButton *)tabButton atIndex:(NSUInteger)tabIndex
{    
    UIButton *closeButton = [UIButton new];
    CGRect frame = tabButton.bounds;
    frame.origin.x = frame.size.width - 35;
    frame.size.width = 35;
    closeButton.frame = frame;
    [closeButton addTarget:self action:@selector(closeTabButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [tabButton addSubview:closeButton];
    
    // TODO no appearance proxy for this?
    [tabButton.titleLabel setFont:[UIFont styleFontWithSize:14]];
    return YES;
}

- (void)tabBar:(ECTabBar *)bar didSelectTabAtIndex:(NSUInteger)index
{
    // TODO assert index in tabs range
    [self setCurrentTabIndex:index animated:NO];
}

- (void)tabBar:(ECTabBar *)tabBar didMoveTabButton:(UIButton *)tabButton fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    ACTab *tab = [tabs objectAtIndex:fromIndex];
    ACTab *currentTab = [self tabAtIndex:ACTabCurrent];
    
    [tabs removeObjectAtIndex:fromIndex];
    [tabs insertObject:tab atIndex:toIndex];
    
    [self setCurrentTabIndex:[tabs indexOfObject:currentTab]];
}

#pragma mark -

- (void)toggleTabBar:(id)sender
{
    if (!tabBarEnabled && tabBar.superview == nil)
        return;
    
    CGRect contentScrollViewFrame = contentScrollView.frame;
    CGRect tabBarFrame = CGRectMake(0, 0, contentScrollViewFrame.size.width - tabPageMargin, 44);
    if (tabBar.superview != nil)
    {
        contentScrollViewFrame.size.height += tabBarFrame.size.height;
        contentScrollViewFrame.origin.y -= tabBarFrame.size.height;
        tabBarFrame.size.height = 0;
        [UIView animateWithDuration:.1 animations:^(void) {
            // TODO fix layout problems of tab buttons during animation?
            tabBar.frame = tabBarFrame;
            contentScrollView.frame = contentScrollViewFrame;
        } completion:^(BOOL finished) {
            [tabBar removeFromSuperview];
        }];
    }
    else
    {
        tabBarFrame.size.height = 0;
        tabBar.frame = tabBarFrame;
        tabBarFrame.size.height = 44;
        
        [self.view addSubview:tabBar];
        contentScrollViewFrame.size.height -= tabBarFrame.size.height;
        contentScrollViewFrame.origin.y += tabBarFrame.size.height;
        [UIView animateWithDuration:.1 animations:^(void) {
            tabBar.frame = tabBarFrame;
            contentScrollView.frame = contentScrollViewFrame;
        }];
    }
}

- (void)closeTabButtonAction:(id)sender
{
    NSUInteger tabIndex = [tabBar indexOfTab:(UIButton *)[sender superview]];
    [self removeTabAtIndex:tabIndex animated:YES];
}

#pragma mark - Content ScrollView Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Gets tab page position
    CGRect tabFrame = contentScrollView.bounds;
    NSInteger tabIndex = (NSInteger)roundf(tabFrame.origin.x / tabFrame.size.width);
    if (tabIndex < 0 || tabIndex == currentTabIndex)
        return;
    
    [self setCurrentTabIndex:tabIndex scroll:NO animated:YES];
}

#pragma mark - Tab Navigation Methods

- (void)setCurrentTabIndex:(NSUInteger)tabIndex
{
    [self setCurrentTabIndex:tabIndex scroll:YES animated:NO];
}

- (void)setCurrentTabIndex:(NSUInteger)tabIndex animated:(BOOL)animated
{
    [self setCurrentTabIndex:tabIndex scroll:YES animated:animated];
}

- (NSUInteger)indexOfTabWithTitle:(NSString *)title
{
    __block NSUInteger result = NSNotFound;
    [tabs enumerateObjectsUsingBlock:^(ACTab *tab, NSUInteger idx, BOOL *stop) {
        if ([title isEqualToString:[tab.button titleForState:UIControlStateNormal]])
        {
            result = idx;
            *stop = YES;
        }
    }];
    return result;
}

- (NSUInteger)addTabWithURL:(NSURL *)url title:(NSString *)title animated:(BOOL)animated
{
    // TODO warn if no delegate?
    // TODO assert url != nil?
    
    // Create a proper title
    if (title == nil)
        title = [url lastPathComponent];
    
    NSArray *tabTitles = [tabBar allTabTitles];
    if ([tabTitles containsObject:title])
    {
        if ([url.pathComponents count] > 1)
        {
            title = [title stringByAppendingFormat:@" - %@", [url.pathComponents objectAtIndex:[url.pathComponents count] - 2]];
        }
        else
        {
            NSString *newTitle;
            NSUInteger i = 1;
            do {
                newTitle = [title stringByAppendingFormat:@" (%u)", i];
            } while ([tabTitles containsObject:newTitle]);
            title = newTitle;
        }
    }
    
    // Create new tab entry
    ACTab *tab = [ACTab new];
    
    // Add new tab in the tab bar
    NSUInteger tabIndex = [tabBar addTabButtonWithTitle:title animated:animated];
    tab.button = [tabBar tabAtIndex:tabIndex];
    
    // Insert into tabs collection
    if (!tabs)
        tabs = [NSMutableArray new];
    [tabs insertObject:tab atIndex:tabIndex];
    
    // Set count of pages in content scroll view
    [(ACTabPagingScrollView *)contentScrollView setPageCount:[tabs count]];
    
    // Push url
    [self pushURL:url toTabAtIndex:tabIndex animated:animated];
    
    // Make current if no tab
    if ([tabs count] == 1)
    {
        currentTabIndex = tabIndex + 1;
        [self setCurrentTabIndex:tabIndex animated:animated];
    }
    
    return tabIndex;
}

- (void)pushURL:(NSURL *)url toTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated
{
    ACTab *tab = [self tabAtIndex:tabIndex];
    if (tab == nil)
        return;
    
    // Push history url
    [tab pushToHistory:url];
    
    // Create controller if neccessary
    if (tabIndex == ACTabCurrent || abs((NSInteger)tabIndex - (NSInteger)currentTabIndex) <= 1)
    {
        [self loadAndPositionViewControllerForTab:tab animated:animated];
    }
}

- (void)setHistoryPoint:(NSUInteger)index forTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated
{
    ACTab *tab = [self tabAtIndex:tabIndex];
    if (tab == nil)
        return;
    
    if (index >= [tab.history count])
        index = NSNotFound;
    
    if (tab.historyPoint == index)
        return;
    
    tab.historyPoint = index;
    
    // Update controller if neccessary
    if (tabIndex == ACTabCurrent || abs((NSInteger)tabIndex - (NSInteger)currentTabIndex) <= 1)
    {
        [self loadAndPositionViewControllerForTab:tab animated:animated];
    }    
}

- (void)popURLFromTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated
{
    ACTab *tab = [self tabAtIndex:tabIndex];
    if (tab == nil)
        return;
    
    [tab popHistory];
    
    if (tabIndex == ACTabCurrent || abs((NSInteger)tabIndex - (NSInteger)currentTabIndex) <= 1)
    {
        [self loadAndPositionViewControllerForTab:tab animated:animated];
    }
}

- (void)removeTabAtIndex:(NSUInteger)tabIndex animated:(BOOL)animated
{
    // Will not remove all tabs
    if ([tabs count] == 1)
        return;
    
    ACTab *currentTab = [self tabAtIndex:ACTabCurrent];
    ACTab *tab = [self tabAtIndex:tabIndex];
    if (tab == nil)
        return;
    
    [tabBar removeTabAtIndex:tabIndex animated:animated];
    [tabs removeObject:tab];
    [(ACTabPagingScrollView *)contentScrollView setPageCount:[tabs count]];
    
    if (tabIndex == ACTabCurrent || tabIndex == currentTabIndex)
    {
        NSUInteger newCurrentTabIndex = currentTabIndex >= [tabs count] ? currentTabIndex - 1 : currentTabIndex;
        if (animated)
        {
            [UIView animateWithDuration:0.10 animations:^(void) {
                tab.viewController.view.alpha = 0; 
            } completion:^(BOOL finished) {
                [tab.viewController.view removeFromSuperview];
                [tab.viewController removeFromParentViewController];
                currentTabIndex += 1;
                [self setCurrentTabIndex:newCurrentTabIndex scroll:NO animated:YES];
            }];
        }
        else
        {
            [tab.viewController.view removeFromSuperview];
            [tab.viewController removeFromParentViewController];
            currentTabIndex += 1;
            [self setCurrentTabIndex:newCurrentTabIndex];
        }
    }
    else
    {
        [tab.viewController.view removeFromSuperview];
        [tab.viewController removeFromParentViewController];
        
        if ([tabs indexOfObject:currentTab] != currentTabIndex)
            [self setCurrentTabIndex:[tabs indexOfObject:currentTab] scroll:NO animated:NO];
        else if (tabIndex - currentTabIndex == 1 && tabIndex < [tabs count])
            [self loadAndPositionViewControllerForTab:[tabs objectAtIndex:tabIndex] animated:NO];
    }
}

@end


@implementation ACTab

@synthesize button, history, historyPoint, viewController;

- (void)pushToHistory:(NSURL *)url
{
    if (history == nil)
    {
        history = [NSMutableArray new];
        historyPoint = NSNotFound;
    }
    
    if (historyPoint != NSNotFound && historyPoint < [history count] - 1)
    {
        [history removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(historyPoint + 1, [history count] - historyPoint - 1)]];
    }
    
    [history addObject:url];
}

- (void)popHistory
{
    // Will not pop if only one item in the history
    if ([history count] == 1)
        return;
    
    if (historyPoint == NSNotFound)
    {
        [history removeLastObject];
    }
    else if (historyPoint > 0)
    {
        [history removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(historyPoint, [history count] - historyPoint)]];
        historyPoint = historyPoint - 1;
    }
}

- (NSURL *)historyPointURL
{
    if (historyPoint == NSNotFound)
        return [history lastObject];
    else
        return [history objectAtIndex:historyPoint];
}

@end


@implementation ACTabPagingScrollView
@synthesize pageCount, keepCurrentPageCentered, pageMargin;

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = self.bounds;
    
    if (keepCurrentPageCentered)
    {
        NSUInteger currentPage = roundf(self.contentOffset.x * pageCount / self.contentSize.width);
        self.contentOffset = CGPointMake(currentPage * bounds.size.width, 0);
    }
    
    self.contentSize = CGSizeMake(bounds.size.width * pageCount, 1);
    
    bounds.size.width -= pageMargin;
    for (UIView *view in self.subviews)
    {
        bounds.origin.x = (bounds.size.width + pageMargin) * view.tag + pageMargin / 2;
        view.frame = bounds;
    }
}

@end
