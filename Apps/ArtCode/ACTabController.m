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

@interface ACTab : NSObject

@property (nonatomic, weak) UIButton *button;
@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic) NSUInteger historyPoint;
@property (nonatomic, weak) UIViewController<ACURLTarget> *viewController;

@end

@implementation ACTabController {
    NSMutableArray *tabs;
    
    BOOL delegateHasDidShowTabAtIndexWithViewController;
}

#pragma mark - Properties

@synthesize delegate;
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

#pragma mark - Private Methods

- (ACTab *)tabAtIndex:(NSUInteger)tabIndex
{
    // TODO sanity checks
    if (tabIndex == ACTabCurrent)
        tabIndex = currentTabIndex;
    return [tabs objectAtIndex:tabIndex];
}

- (void)loadAndPositionViewControllerForTab:(ACTab *)tab animated:(BOOL)animated
{
    NSURL *url = [tab.history lastObject];
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
    
    // Position new tab controller's view
    tabFrame.origin.x = tabFrame.size.width * tabPage;
    tabController.view.frame = tabFrame;
    tabController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
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
    if (tabIndex == currentTabIndex || tabIndex == ACTabCurrent)
        return;
    
    currentTabIndex = tabIndex;
    
    ACTab *tab = [self tabAtIndex:tabIndex];
    
    // Select tab
    [tabBar setSelectedTabIndex:tabIndex];
    
    // Load and position current tab
    if (tab.viewController == nil)
        [self loadAndPositionViewControllerForTab:tab animated:animated];
    
    // Scroll to tab controller
    if (scroll)
    {
        CGRect tabFrame = tab.viewController.view.frame;
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
        [hiddenTabsIndexes removeIndex:tabIndex - 1];
    }
    if (tabIndex + 1 < [tabs count])
    {
        ACTab *postTab = (ACTab *)[tabs objectAtIndex:tabIndex + 1];
        if (postTab.viewController == nil)
            [self loadAndPositionViewControllerForTab:postTab animated:NO];
        [hiddenTabsIndexes removeIndex:tabIndex + 1];
    }
    
    // Cleanup non used child controllers
    [tabs enumerateObjectsAtIndexes:hiddenTabsIndexes options:0 usingBlock:^(ACTab *t, NSUInteger idx, BOOL *stop) {
        [t.viewController removeFromParentViewController];
        // TODO remove view?
    }];
    
    // Call delegate
    if (delegateHasDidShowTabAtIndexWithViewController)
        [delegate tabController:self didShowTabAtIndex:tabIndex withViewController:tab.viewController];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
        contentScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        contentScrollView.delegate = self;
        [self.view addSubview:contentScrollView];
    }
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
    
    [tabs removeObjectAtIndex:fromIndex];
    [tabs insertObject:tab atIndex:toIndex];
    
    NSUInteger currentFromIndex = MIN(0, currentTabIndex - 1);
    NSRange indexRange = NSMakeRange(currentFromIndex, MIN(3, [tabs count] - currentFromIndex));
    if (toIndex <= currentTabIndex)
    {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:indexRange];
        [tabs enumerateObjectsAtIndexes:indexes options:0 usingBlock:^(ACTab *t, NSUInteger idx, BOOL *stop) {
            [self loadAndPositionViewControllerForTab:t animated:NO];
            // TODO remove oher from parentController
        }];
    }
    else if (toIndex == NSMaxRange(indexRange) - 1)
    {
        [self loadAndPositionViewControllerForTab:tab animated:NO];
    }
}

#pragma mark -

- (void)toggleTabBar:(id)sender
{
    if (!tabBarEnabled && tabBar.superview == nil)
        return;
    
    CGRect contentScrollViewFrame = contentScrollView.frame;
    CGRect tabBarFrame = CGRectMake(0, 0, contentScrollViewFrame.size.width, 44);
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
    [tabBar removeTabAtIndex:tabIndex animated:YES];
    
    // TODO also remove controller
}

#pragma mark - Content ScrollView Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Gets tab page position
    CGRect tabFrame = contentScrollView.bounds;
    NSInteger tabIndex = (NSInteger)roundf(tabFrame.origin.x / tabFrame.size.width);
    
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
    tab.history = [NSMutableArray new];
    
    // Add new tab in the tab bar
    NSUInteger tabIndex = [tabBar addTabButtonWithTitle:title animated:animated];
    tab.button = [tabBar tabAtIndex:tabIndex];
    
    // Insert into tabs collection
    if (!tabs)
        tabs = [NSMutableArray new];
    [tabs insertObject:tab atIndex:tabIndex];
    
    // Increase content view size
    CGRect tabFrame = contentScrollView.bounds;
    contentScrollView.contentSize = CGSizeMake(tabFrame.size.width * [tabs count], 1);
    
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
    [tab.history addObject:url];
    
    // Gets tab page position
    CGRect tabFrame = contentScrollView.bounds;
    NSInteger tabPage = (NSInteger)[tabBar indexOfTab:tab.button];
    NSInteger currentPage = (NSInteger)(tabFrame.origin.x / tabFrame.size.width);
    
    // Create controller if neccessary
    if (abs(tabPage - currentPage) <= 1)
    {
        [self loadAndPositionViewControllerForTab:tab animated:animated];
    }
}

@end


@implementation ACTab

@synthesize button, history, historyPoint, viewController;

@end
