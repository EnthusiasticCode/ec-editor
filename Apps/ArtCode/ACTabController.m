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

@property (nonatomic, strong) NSMutableArray *history;
@property (nonatomic, strong) UIViewController<ACNavigable> *viewController;

+ (ACTab *)tabWithURL:(NSURL *)url viewController:(UIViewController<ACNavigable> *)controller;

@end

@implementation ACTabController {
    /// Dictionary of tab titles -> ACTab.
    NSMutableDictionary *tabs;
}

#pragma mark - Properties

@synthesize delegate;
@synthesize contentScrollView;
@synthesize tabBar, tabBarEnabled;
@synthesize swipeGestureRecognizer;

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

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!tabBar)
        tabBar = [[ECTabBar alloc] initWithFrame:CGRectMake(0, 45, self.view.bounds.size.width, 44)];
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
        contentScrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    contentScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    contentScrollView.pagingEnabled = YES;
    contentScrollView.showsVerticalScrollIndicator = NO;
    contentScrollView.showsHorizontalScrollIndicator = NO;
    contentScrollView.panGestureRecognizer.minimumNumberOfTouches = 3;
    contentScrollView.panGestureRecognizer.maximumNumberOfTouches = 3;
    
    
    // TODO use controller method to add tab that will also add child controller
    [tabBar addTabButtonWithTitle:@"One" animated:NO];
    [tabBar addTabButtonWithTitle:@"Two" animated:NO];
    [tabBar addTabButtonWithTitle:@"Three" animated:NO];
    [tabBar addTabButtonWithTitle:@"Four" animated:NO];
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
    // TODO
}

#pragma mark -

- (void)toggleTabBar:(id)sender
{
    if (!tabBarEnabled && tabBar.superview == nil)
        return;
    
    CGRect contentScrollViewFrame = contentScrollView.frame;
    CGRect tabBarFrame = CGRectMake(0, 45, contentScrollViewFrame.size.width, 44);
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

#pragma mark - Tab Navigation Methods

@synthesize currentTab;

- (NSArray *)tabTitles
{
    return [tabs allKeys];
}

- (NSString *)addTabWithURL:(NSURL *)url title:(NSString *)title animated:(BOOL)animated
{
    // TODO warn if no delegate?
    // TODO assert url != nil?
    
    // Create a proper title
    if (title == nil)
    {
        title = [url lastPathComponent];
    }
    else if ([tabs objectForKey:title] != nil)
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
            } while ([tabs objectForKey:newTitle] != nil);
            title = newTitle;
        }
    }
    
    // Create new tab entry
    if (!tabs)
        tabs = [NSMutableDictionary new];
    ACTab *tab = [ACTab tabWithURL:url viewController:[delegate tabController:self viewControllerForURL:url]];
    [tabs setObject:tab forKey:title];
    
    // Account for tab gesture recognizer
    if ([tab.viewController.view isKindOfClass:[UIScrollView class]])
    {
        UIScrollView *scrollView = (UIScrollView *)tab.viewController.view;
        [scrollView.panGestureRecognizer requireGestureRecognizerToFail:swipeGestureRecognizer];
    }
    
    // Add new tab in the tab bar
    [tabBar addTabButtonWithTitle:title animated:animated];
    
    // Position new tab controller's view
    CGRect tabFrame = contentScrollView.bounds;
    if ([tabs count] > 1)
    {
        contentScrollView.contentSize = CGSizeMake(tabFrame.size.width * [tabs count], tabFrame.size.height);
        tabFrame.origin.x = tabFrame.size.width * ([tabs count] - 1);
    }
    tab.viewController.view.frame = tabFrame;
    [self.view addSubview:tab.viewController.view];
    [contentScrollView scrollRectToVisible:tabFrame animated:animated];
    
    return title;
}

@end

@implementation ACTab

@synthesize history, viewController;

+ (ACTab *)tabWithURL:(NSURL *)url viewController:(UIViewController<ACNavigable> *)controller
{
    ACTab *result = [ACTab new];
    result.viewController = controller;
    result.history = [NSMutableArray arrayWithObject:url];
    return result;
}

@end
