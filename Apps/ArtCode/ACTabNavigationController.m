//
//  ACTabNavigationController.m
//  tab
//
//  Created by Nicola Peduzzi on 7/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppStyle.h"
#import "ACTabNavigationController.h"
#import "ECSwipeGestureRecognizer.h"
#import "UIView+ReuseIdentifier.h"

/// Category on tab controller to assign it's parent;
@interface ACTabController (ParentCategory)

- (void)setParentTabNavigationController:(ACTabNavigationController *)parent;
- (void)setTabButton:(UIControl *)control;

@end


typedef void (^ScrollViewBlock)(UIScrollView *scrollView);

/// Custom scroll view to manage it's layout with a block
@interface ACTabPagingScrollView : UIScrollView
@property (nonatomic, copy) ScrollViewBlock customLayoutSubviews;
@end


//
@implementation ACTabNavigationController {
    NSMutableArray *tabControllers;
    
    NSMutableArray *tabTitles;
    BOOL tabBarVisible;
    
    ACTabPagingScrollView *contentScrollView;
    BOOL keepCurrentPageCentered;
    
    struct {
        unsigned int hasWillChangeCurrentTabControllerFromTabController : 1;
        unsigned int hasDidChangeCurrentTabControllerFromTabController : 1;
        unsigned int hasWillAddTabController : 1;
        unsigned int hasDidAddTabController : 1;
        unsigned int hasWillRemoveTabController : 1;
        unsigned int hasDidRemoveTabController : 1;
        unsigned int hasChangedURLForCurrentTabController : 1;
        unsigned int informDidAddAfterTabBarAnimation : 1;
    } delegateFlags;
}

#pragma mark - Properties

@synthesize delegate;
@synthesize tabBarEnabled;
@synthesize tabBar, contentScrollView;
@synthesize swipeGestureRecognizer;
@synthesize tabControllers, currentTabController;
@synthesize tabPageMargin;
@synthesize makeAddedTabCurrent;

- (void)setDelegate:(id<ACTabNavigationControllerDelegate>)aDelegate
{
    delegate = aDelegate;
    
    delegateFlags.hasWillChangeCurrentTabControllerFromTabController = [delegate respondsToSelector:@selector(tabNavigationController:willChangeCurrentTabController:fromTabController:)];
    delegateFlags.hasDidChangeCurrentTabControllerFromTabController = [delegate respondsToSelector:@selector(tabNavigationController:didChangeCurrentTabController:fromTabController:)];
    delegateFlags.hasWillAddTabController = [delegate respondsToSelector:@selector(tabNavigationController:willAddTabController:)];
    delegateFlags.hasDidAddTabController = [delegate respondsToSelector:@selector(tabNavigationController:didAddTabController:)];
    delegateFlags.hasWillRemoveTabController = [delegate respondsToSelector:@selector(tabNavigationController:willRemoveTabController:)];
    delegateFlags.hasDidRemoveTabController = [delegate respondsToSelector:@selector(tabNavigationController:didRemoveTabController:)];
    delegateFlags.hasChangedURLForCurrentTabController = [delegate respondsToSelector:@selector(tabNavigationController:changedURLForTabController:)];
}

- (NSUInteger)tabCount
{
    return [tabControllers count];
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

- (void)setCurrentTabController:(ACTabController *)tabController
{
    [self setCurrentTabController:tabController animated:NO];
}

- (void)setTabPageMargin:(CGFloat)margin
{
    tabPageMargin = margin;
    
    CGRect contentScrollViewFrame = self.view.bounds;
    contentScrollViewFrame.origin.x -= tabPageMargin / 2;
    contentScrollViewFrame.size.width += tabPageMargin;
    if (tabBarVisible)
    {
        contentScrollViewFrame.origin.y += tabBar.bounds.size.height;
        contentScrollViewFrame.size.height -= tabBar.bounds.size.height;
    }
    contentScrollView.frame = contentScrollViewFrame;
}

#pragma mark - Private Methods

- (NSString *)titleForTabController:(ACTabController *)controller
{
    // Retrieve all tabs titles
    if ([tabTitles count] == 0)
    {
        if (tabTitles == nil)
            tabTitles = [NSMutableArray new];
        for (UIButton *tabButton in tabBar.tabControls)
        {
            NSString *title = [tabButton titleForState:UIControlStateNormal];
            ECASSERT(title != nil);
            [tabTitles addObject:title];
        }
    }
    
    NSString *title = nil;
    
    // Generate and validate title
    NSURL *url = controller.currentURL;
    if (url != nil && url.lastPathComponent != nil)
    {
        title = url.lastPathComponent;
        if (![tabTitles containsObject:title])
            return title;
        if ([url.pathComponents count] > 1)
            title = [NSString stringWithFormat:@"%@ - %@", title, [url.pathComponents objectAtIndex:[url.pathComponents count] - 2]];
    }
    else
    {
        title = @"Tab";
    }
    
    // Valiate title
    NSUInteger i = 0;
    NSString *newTitle = title;
    while ([tabTitles containsObject:newTitle])
    {
        newTitle = [title stringByAppendingFormat:@" (%u)", ++i];
    }
    title = newTitle;
    
    return title;
}

/// Utility function that loads the current tab view controller as well as the previous and next if present.
/// The function also unload any other view in the content scroll view that is not one of the one described.
/// If onlyIfThisLoadable is not nil, the function will execute the loading phase only if the given 
/// tab controller is the current or close to it.
static void loadCurrentAndAdiacentTabViews(ACTabNavigationController *self, ACTabController *onlyIfThisLoadable)
{
    NSInteger currentTabIndex = [self->tabControllers indexOfObject:self->currentTabController];
    
    NSUInteger minLoadableIndex = currentTabIndex > 0 ? currentTabIndex - 1 : currentTabIndex;
    NSUInteger maxLoadableIndex = currentTabIndex < [self->tabControllers count] - 1 ? currentTabIndex + 1 : currentTabIndex;
    
    if (onlyIfThisLoadable != nil)
    {
        ECASSERT([self->tabControllers containsObject:onlyIfThisLoadable]);
        
        NSUInteger filterIndex = [self->tabControllers indexOfObject:onlyIfThisLoadable];
        if (filterIndex < minLoadableIndex || filterIndex > maxLoadableIndex)
            return;
    }
    
    [self->tabControllers enumerateObjectsUsingBlock:^(ACTabController *tabController, NSUInteger index, BOOL *stop) {
        if (tabController.isTabViewControllerLoaded)
        {
            // Load view if current or diacent to current
            if (index >= minLoadableIndex && index <= maxLoadableIndex)
            {
                if (tabController.tabViewController.view.superview == nil)
                {
                    [self->contentScrollView addSubview:tabController.tabViewController.view];
                    // Enabling tab swipe gesture recognizer to win over nested scrollviews pan
                    UIView *addedView = tabController.tabViewController.view;
                    do {
                        if ([addedView isKindOfClass:[UIScrollView class]])
                        {
                            UIScrollView *addedScrollviewView = (UIScrollView *)addedView;
                            [addedScrollviewView.panGestureRecognizer requireGestureRecognizerToFail:self->swipeGestureRecognizer];
                            break;
                        }
                        addedView = [addedView.subviews objectAtIndex:0];
                        // TODO Fix, this will check only the view and descending of the first subview. may also crash. could need protocol like tabNavigationControllerWillAddView:
                    } while (addedView);
                }
                else
                {
                    [self->contentScrollView setNeedsLayout];
                }
            }
            else if (tabController.tabViewController.isViewLoaded)
            {
                [tabController.tabViewController.view removeFromSuperview];
            }
        }
    }];
}

#pragma mark - Controller lifecycle

- (BOOL)isEditing
{
    return currentTabController.tabViewController.isEditing;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [currentTabController.tabViewController setEditing:editing animated:animated];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    tabTitles = nil;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Makes the current tab view to be centered in the scroll view during device orientation
    keepCurrentPageCentered = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    keepCurrentPageCentered = NO;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    ////////////////////////////////////////////////////////////////////////////
    // Tab bar
    if (!tabBar)
        tabBar = [[ECTabBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    tabBar.delegate = self;
    tabBar.backgroundColor = [UIColor styleForegroundColor];
    tabBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    ////////////////////////////////////////////////////////////////////////////
    // Additional tab bar buttons
    UIButton *addTabButton = [UIButton new];
    [addTabButton addTarget:self action:@selector(duplicateCurrentTab:) forControlEvents:UIControlEventTouchUpInside];
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
        [self.view addSubview:contentScrollView];
    }
    
    __weak ACTabNavigationController *this = self;
    contentScrollView.customLayoutSubviews = ^(UIScrollView *scrollView) {
        CGRect bounds = scrollView.bounds;
        NSUInteger tabControllersCount = [this->tabControllers count];
        
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
        for (ACTabController *tabController in this->tabControllers)
        {
            if (tabController.isTabViewControllerLoaded 
                && tabController.tabViewController.isViewLoaded)
            {
                tabController.tabViewController.view.frame = pageFrame;
            }
            pageFrame.origin.x += bounds.size.width;
        }
    };
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
    [self setTabBar:nil];
    [self setContentScrollView:nil];
    tabTitles = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Tab Bar Actions

- (void)duplicateCurrentTab:(id)sender
{
    if (currentTabController == nil)
        return;
    
    [self addTabController:[currentTabController copy] animated:YES];
}

- (void)toggleTabBar:(id)sender
{
    if (!tabBarEnabled && tabBar.superview == nil)
        return;
    
    CGRect contentScrollViewFrame = self.view.bounds;
    contentScrollViewFrame.origin.x -= tabPageMargin / 2;
    contentScrollViewFrame.size.width += tabPageMargin;
    CGRect tabBarFrame = CGRectMake(0, 0, contentScrollViewFrame.size.width - tabPageMargin, 44);
    if (tabBarVisible)
    {
        tabBarVisible = NO;
        
        tabBarFrame.size.height = 0;
        
        tabBar.clipsToBounds = YES;
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            tabBar.frame = tabBarFrame;
            contentScrollView.frame = contentScrollViewFrame;
        } completion:^(BOOL finished) {
            if (finished)
            {
                [tabBar removeFromSuperview];
                tabBar.clipsToBounds = NO;
            }
        }];
    }
    else
    {
        tabBarVisible = YES;
        
        contentScrollViewFrame.origin.y += tabBarFrame.size.height;
        contentScrollViewFrame.size.height -= tabBarFrame.size.height;
        
        tabBarFrame.size.height = 0;
        tabBar.frame = tabBarFrame;
        tabBarFrame.size.height = 44;
        
        [self.view addSubview:tabBar];
        tabBar.clipsToBounds = YES;
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            tabBar.frame = tabBarFrame;
            contentScrollView.frame = contentScrollViewFrame;
        } completion:^(BOOL finished) {
            if (finished)
            {
                tabBar.clipsToBounds = NO;
            }
        }];
    }
}

#pragma mark - Managing Tabs

- (void)setCurrentTabController:(ACTabController *)tabController animated:(BOOL)animated
{
    ECASSERT(tabControllers != nil);
    ECASSERT([tabControllers indexOfObject:tabController] != NSNotFound);
    
    if (tabController == currentTabController)
        return;
    
    if (delegateFlags.hasWillChangeCurrentTabControllerFromTabController
        && ![delegate tabNavigationController:self willChangeCurrentTabController:tabController fromTabController:currentTabController])
        return;
    
    ACTabController *fromTabController = currentTabController;
    currentTabController = tabController;
    NSUInteger tabIndex = [tabControllers indexOfObject:tabController];
    
    // NOTE This method will trigger a recursive call, but it will end because
    // the current tab controller has already been modified.
    [tabBar setSelectedTabControl:tabController.tabButton animated:animated];
    
    // Load current view/adiacent views
    loadCurrentAndAdiacentTabViews(self, nil);
    [contentScrollView layoutIfNeeded];
    
    CGFloat pageWidth = contentScrollView.bounds.size.width;
    if (!animated)
    {
        // NOTE The scrolling callback will try to set the current tab to the one already selected returning immediatly
        [contentScrollView scrollRectToVisible:CGRectMake(pageWidth * tabIndex, 0, pageWidth, 1) animated:NO];
        
        if (delegateFlags.hasDidChangeCurrentTabControllerFromTabController)
            [delegate tabNavigationController:self didChangeCurrentTabController:currentTabController fromTabController:fromTabController];
    }
    else
    {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
            [contentScrollView scrollRectToVisible:CGRectMake(pageWidth * tabIndex, 0, pageWidth, 1) animated:NO];
        } completion:^(BOOL finished) {
            if (delegateFlags.hasDidChangeCurrentTabControllerFromTabController)
                [delegate tabNavigationController:self didChangeCurrentTabController:currentTabController fromTabController:fromTabController];
        }];
    }
}

- (ACTabController *)tabControllerAtPosition:(NSInteger)position
{
    if (position >= [tabControllers count])
        return nil;
    
    return [tabControllers objectAtIndex:position];
}

#pragma mark - Adding and Removing Tabs

- (void)addTabController:(ACTabController *)tabController animated:(BOOL)animated
{
    ECASSERT(tabController != nil);
    
    if (!tabControllers)
        tabControllers = [NSMutableArray new];
    
    if (delegateFlags.hasWillAddTabController
        && ![delegate tabNavigationController:self willAddTabController:tabController])
        return;
    
    [tabControllers addObject:tabController];
    tabController.parentTabNavigationController = self;
    tabController.delegate = self;
    
    // Creating tab view controller
    [self addChildViewController:tabController.tabViewController];
    
    // Creating and assigning tab button
    NSString *title = [self titleForTabController:tabController];
    tabController.tabButton = [tabBar addTabWithTitle:title animated:animated];
    [tabTitles addObject:title];
    
    // Set current if no other current controller
    if (currentTabController == nil || (makeAddedTabCurrent && !animated))
    {
        [self setCurrentTabController:tabController animated:NO];
    }
    else
    {
        loadCurrentAndAdiacentTabViews(self, tabController);
        [contentScrollView layoutIfNeeded];
    }
    
    // Inform delegate of added controller immediatly if no animation
    if (!animated)
    {
        delegateFlags.informDidAddAfterTabBarAnimation = NO;
        if (delegateFlags.hasDidAddTabController)
            [delegate tabNavigationController:self didAddTabController:tabController];
    }
    else
    {
        // Let the tab bar didAdd delegate callback call the local delegate
        delegateFlags.informDidAddAfterTabBarAnimation = YES;
    }
}

- (ACTabController *)addTabControllerWithDataSorce:(id<ACTabControllerDataSource>)datasource initialURL:(NSURL *)initialURL animated:(BOOL)animated
{
    ECASSERT(datasource != nil);
    ECASSERT(initialURL != nil);
    
    ACTabController *tabController = [[ACTabController alloc] initWithDataSource:datasource URL:initialURL];
    
    [self addTabController:tabController animated:animated];
    
    return tabController;
}

- (void)removeTabController:(ACTabController *)tabController animated:(BOOL)animated
{
    ECASSERT(tabController != nil);
    ECASSERT([tabControllers containsObject:tabController]);
    
    if (delegateFlags.hasWillRemoveTabController
        && ![delegate tabNavigationController:self willRemoveTabController:tabController])
        return;
    
    NSUInteger tabIndex = [tabControllers indexOfObject:tabController];
    [tabControllers removeObject:tabController];
    
    if ([tabController.tabViewController isViewLoaded])
        [tabController.tabViewController.view removeFromSuperview];
    [tabController.tabViewController removeFromParentViewController];
    
    [tabTitles removeObject:[(UIButton *)tabController.tabButton titleForState:UIControlStateNormal]];
    [tabBar removeTabControl:tabController.tabButton animated:animated];
    
    // Change current tab controller if neccessary
    if (tabController == currentTabController)
    {
        if (tabIndex >= [tabControllers count])
            tabIndex--;
        [self setCurrentTabController:[tabControllers objectAtIndex:tabIndex] animated:animated];
    }
    else
    {
        NSUInteger currentTabIndex = [tabControllers indexOfObject:currentTabController];
        CGSize pageSize = contentScrollView.bounds.size;
        [contentScrollView scrollRectToVisible:CGRectMake(pageSize.width * currentTabIndex, 0, pageSize.width, 1) animated:NO];
    }
}

#pragma mark - Tab Bar Delegate Methods

// TODO tabbar did add method and call didAddTabController

- (UIControl *)tabBar:(ECTabBar *)bar controlForTabWithTitle:(NSString *)title atIndex:(NSUInteger)tabIndex
{
    {
        static NSString *tabButtonIdentifier = @"tabButton";
        
        UIButton *tabButton = (UIButton *)[bar dequeueReusableTabControlWithIdentifier:tabButtonIdentifier];
        if (!tabButton)
        {
            tabButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
            tabButton.reuseIdentifier = tabButtonIdentifier;
            tabButton.titleLabel.lineBreakMode = UILineBreakModeMiddleTruncation;
            tabButton.titleLabel.font = [UIFont styleFontWithSize:14];
            
            UIButton *closeButton = [UIButton new];
            closeButton.frame = CGRectMake(65, 0, 35, 40);
            closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
            [closeButton addTarget:self action:@selector(closeTabButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            [tabButton addSubview:closeButton];
        }
        
        [tabButton setTitle:title forState:UIControlStateNormal];
        
        return tabButton;
    }
}

- (BOOL)tabBar:(ECTabBar *)tabBar willSelectTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex
{
    ACTabController *tabController = [self tabControllerAtPosition:tabIndex];
    [self setCurrentTabController:tabController animated:YES];
    return YES;
}

- (void)tabBar:(ECTabBar *)tabBar didAddTabControl:(UIControl *)tabControl atIndex:(NSUInteger)tabIndex
{
    ECASSERT(tabIndex == [tabControllers count] - 1);
    
    // NOTE this delegate method is invoked from a call in addTabController:animated:
    // and will proceed only if that method has animated = YES;
    if (delegateFlags.informDidAddAfterTabBarAnimation)
    {
        ACTabController *addedTabController = [tabControllers objectAtIndex:tabIndex];
        
        if (makeAddedTabCurrent)
            [self setCurrentTabController:addedTabController animated:YES];
            
        if (delegateFlags.hasDidAddTabController)
            [delegate tabNavigationController:self didAddTabController:addedTabController];
    }
}

- (void)tabBar:(ECTabBar *)tabBar didMoveTabControl:(UIControl *)tabControl fromIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    ECASSERT(fromIndex < [tabControllers count]);
    ECASSERT(toIndex < [tabControllers count]);
    
    ACTabController *tabController = [tabControllers objectAtIndex:fromIndex];
    [tabControllers removeObjectAtIndex:fromIndex];
    [tabControllers insertObject:tabController atIndex:toIndex];
    
    NSUInteger currentTabIndex = [tabControllers indexOfObject:currentTabController];
    CGSize pageSize = contentScrollView.bounds.size;
    [contentScrollView scrollRectToVisible:CGRectMake(pageSize.width * currentTabIndex, 0, pageSize.width, 1) animated:NO];
}

#pragma mark -

- (void)closeTabButtonAction:(id)sender
{
    NSUInteger tabIndex = [tabBar.tabControls indexOfObject:[sender superview]];
    ACTabController *tabController = [self tabControllerAtPosition:tabIndex];
    [self removeTabController:tabController animated:YES];
}

#pragma mark - Tab Controller Delegate Methods

- (void)tabController:(ACTabController *)tabController didChangeURL:(NSURL *)url previousViewController:(UIViewController *)previousVewController
{
    // Substitute view controller
    if (previousVewController != tabController.tabViewController)
    {
        // Add new controller and view
        [self addChildViewController:tabController.tabViewController];
        
        if (tabController == currentTabController)
        {
            // TODO this transition should be applied even if the view controller is not changed?
            [UIView transitionFromView:previousVewController.view toView:tabController.tabViewController.view duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
                [previousVewController removeFromParentViewController];

                loadCurrentAndAdiacentTabViews(self, nil);
                
                if (delegateFlags.hasDidChangeCurrentTabControllerFromTabController)
                    [delegate tabNavigationController:self didChangeCurrentTabController:currentTabController fromTabController:currentTabController];
            }];
        }
        else
        {
            // Remove old controller
            if ([previousVewController isViewLoaded])
                [previousVewController.view removeFromSuperview];
            [previousVewController removeFromParentViewController];
            
            loadCurrentAndAdiacentTabViews(self, tabController);
        }
    }
    
    // Change tab title only if it has an url, otherwise keep previous title
    if (url != nil && url.lastPathComponent != nil)
    {
        UIButton *tabButton = (UIButton *)tabController.tabButton;
        [tabTitles removeObject:[tabButton titleForState:UIControlStateNormal]];
        NSString *title = [self titleForTabController:tabController];
        [tabButton setTitle:title forState:UIControlStateNormal];
    }
    
    // Forward to delegate
    if (delegateFlags.hasChangedURLForCurrentTabController)
        [delegate tabNavigationController:self changedURLForTabController:tabController];
}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Get current tab index
    CGRect pageBounds = contentScrollView.bounds;
    NSUInteger tabControllersCount = [tabControllers count];
    NSInteger currentTabIndex = (NSInteger)roundf(pageBounds.origin.x / pageBounds.size.width);
    if (currentTabIndex < 0)
        currentTabIndex = 0;
    else if (currentTabIndex >= tabControllersCount)
        currentTabIndex = tabControllersCount - 1;
    
    // Return if already on this tab
    if (currentTabIndex == [tabControllers indexOfObject:currentTabController])
        return;
    
    // Set selected tab
    // NOTE tabBar setSelectedTabControl will eventually call setCurrentTabController
    // but at that point currentTabController is already set to the one requested
    // by the tabBar, making the method return.
    ACTabController *fromTabController = currentTabController;
    currentTabController = [tabControllers objectAtIndex:currentTabIndex];
    [tabBar setSelectedTabControl:currentTabController.tabButton animated:YES];
    
    // Load/Unload needed views
    loadCurrentAndAdiacentTabViews(self, nil);
    
    // Informing the delegate
    if (delegateFlags.hasDidChangeCurrentTabControllerFromTabController)
        [delegate tabNavigationController:self didChangeCurrentTabController:currentTabController fromTabController:fromTabController];
}

@end

#pragma mark -

@implementation ACTabController (ParentCategory)

- (void)setParentTabNavigationController:(ACTabNavigationController *)parent
{
    parentTabNavigationController = parent;
}

- (void)setTabButton:(UIControl *)control
{
    tabButton = control;
}

@end

#pragma mark -

@implementation ACTabPagingScrollView

@synthesize customLayoutSubviews;

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    customLayoutSubviews(self);
}

@end
