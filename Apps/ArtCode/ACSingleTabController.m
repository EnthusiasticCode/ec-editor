//
//  ACToolbarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACSingleTabController.h"
#import "ACTopBarToolbar.h"
#import "ACTopBarTitleControl.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "ACTab.h"
#import "ACApplication.h"
#import "ACProject.h"

#import "ACProjectTableController.h"
#import "ACFileTableController.h"
#import "ACCodeFileController.h"

#define DEFAULT_TOOLBAR_HEIGHT 44
static const void *tabCurrentURLObservingContext;
static const void *contentViewControllerContext;

@interface ACSingleTabController ()

- (BOOL)_isViewVisible;

/// Position the bar and content.
- (void)_layoutChildViewsAnimated:(BOOL)animated;

/// Will setup the toolbar items.
- (void)_setupDefaultToolbarItemsAnimated:(BOOL)animated;

/// Will setup the title control by enabling it and setting the labels according to the current URL.
- (void)_setupDefaultToolbarTitle;

/// Routing method that resolve an URL to the view controller that can handle it.
- (UIViewController *)_routeViewControllerWithURL:(NSURL *)url;

- (void)_defaultToolbarTitleButtonAction:(id)sender;
- (void)_historyBackAction:(id)sender;
- (void)_historyForwardAction:(id)sender;

@end


@implementation ACSingleTabController

#pragma mark - Properties

@synthesize defaultToolbar = _defaultToolbar, toolbarViewController = _toolbarViewController, toolbarHeight = _toolbarHeight;
@synthesize contentViewController = _contentViewController;
@synthesize tab = _tab;

- (ACTopBarToolbar *)defaultToolbar
{
    if (!_defaultToolbar)
    {
        self.defaultToolbar = [[ACTopBarToolbar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
    }
    return _defaultToolbar;
}

- (void)setDefaultToolbar:(ACTopBarToolbar *)defaultToolbar
{
    if (defaultToolbar == _defaultToolbar)
        return;
    
    [self willChangeValueForKey:@"defaultToolbar"];
    
    if (self._isViewVisible)
    {
        [_defaultToolbar removeFromSuperview];
        [self.view addSubview:defaultToolbar];
        _defaultToolbar = defaultToolbar;
        [self _layoutChildViewsAnimated:NO];
    }
    else
    {
        _defaultToolbar = defaultToolbar;
    }
    
    [_defaultToolbar.titleControl.backgroundButton addTarget:self action:@selector(_defaultToolbarTitleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_defaultToolbar.backButton addTarget:self action:@selector(_historyBackAction:) forControlEvents:UIControlEventTouchUpInside];
    [_defaultToolbar.forwardButton addTarget:self action:@selector(_historyForwardAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [self didChangeValueForKey:@"defaultToolbar"];
}

- (BOOL)isShowingLoadingAnimation
{
    return self.defaultToolbar.titleControl.isLoadingMode;
}

- (void)setShowLoadingAnimation:(BOOL)showLoadingAnimation
{
    self.defaultToolbar.titleControl.loadingMode = showLoadingAnimation;
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
    [self setContentViewController:contentViewController animated:NO];
}

- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated
{
    if (contentViewController == _contentViewController)
        return;
    
    [self willChangeValueForKey:@"contentViewController"];
    
    // Animate view in position
    if (self._isViewVisible)
    {
        [_contentViewController viewWillDisappear:animated];
        [contentViewController viewWillAppear:animated];
        
        if (_contentViewController != nil && animated)
        {
            UIViewController *oldViewController = _contentViewController;
            contentViewController.view.alpha = 0;
            contentViewController.view.frame = CGRectMake(0, self.toolbarHeight, self.view.frame.size.width, self.view.frame.size.height - self.toolbarHeight);
            [self.view addSubview:contentViewController.view];
            [UIView animateWithDuration:0.2 animations:^{
                contentViewController.view.alpha = 1;
                oldViewController.view.alpha = 0;
            } completion:^(BOOL finished) {
                [oldViewController.view removeFromSuperview];
                [oldViewController viewDidDisappear:YES];
                [contentViewController viewDidAppear:YES];
            }];
        }
        else
        {
            contentViewController.view.frame = _contentViewController.view.frame;
            [self.view addSubview:contentViewController.view];
            [_contentViewController.view removeFromSuperview];
            [_contentViewController viewDidDisappear:NO];
            [contentViewController viewDidAppear:NO];
        }
    }
    
    // Remove old view controller
    if (_contentViewController)
    {
        [_contentViewController willMoveToParentViewController:nil];
        [_contentViewController removeFromParentViewController];
        [_contentViewController removeObserver:self forKeyPath:@"toolbarItems" context:&contentViewControllerContext];
        [_contentViewController removeObserver:self forKeyPath:@"loading" context:&contentViewControllerContext];
        [_contentViewController removeObserver:self forKeyPath:@"title" context:&contentViewControllerContext];
        [_contentViewController removeObserver:self forKeyPath:@"editing" context:&contentViewControllerContext];
    }

    // Setup new controller
    if ((_contentViewController = contentViewController))
    {
        [self addChildViewController:_contentViewController];
        [_contentViewController didMoveToParentViewController:self];
        [_contentViewController addObserver:self forKeyPath:@"toolbarItems" options:NSKeyValueObservingOptionNew context:&contentViewControllerContext];
        [_contentViewController addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&contentViewControllerContext];
        [_contentViewController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&contentViewControllerContext];
        [_contentViewController addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&contentViewControllerContext];
    }
    
    [self _setupDefaultToolbarItemsAnimated:animated];
    
    [self didChangeValueForKey:@"contentViewController"];
}

- (UIView *)currentToolbarView
{
    if (_toolbarViewController)
        return _toolbarViewController.view;
    return self.defaultToolbar;
}

- (void)setToolbarViewController:(UIViewController *)toolbarViewController
{
    [self setToolbarViewController:toolbarViewController animated:NO];
}

- (void)setToolbarViewController:(UIViewController *)toolbarViewController animated:(BOOL)animated
{
    if (toolbarViewController == _toolbarViewController)
        return;
    
    [self willChangeValueForKey:@"toolbarViewController"];
    
    UIViewController *oldToolbarViewController = _toolbarViewController;
    
    _toolbarViewController = toolbarViewController;
    if (_toolbarViewController)
        [self addChildViewController:_toolbarViewController];
    [oldToolbarViewController willMoveToParentViewController:nil];
    
    UIView *lastToolbar = oldToolbarViewController ? oldToolbarViewController.view : self.defaultToolbar;
    UIView *toolbarView = _toolbarViewController ? _toolbarViewController.view : self.defaultToolbar;
    CGFloat direction = _toolbarViewController ? 1 : -1;
    toolbarView.frame = lastToolbar.frame;
    toolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    if (self._isViewVisible && animated)
    {
        [self resetToolbarHeightAnimated:animated];
        
        lastToolbar.layer.anchorPointZ = 19;
        [self.view addSubview:toolbarView];
        toolbarView.layer.anchorPointZ = 19;
        toolbarView.layer.transform = CATransform3DMakeRotation(M_PI_2, -1 * direction, 0, 0);
        toolbarView.layer.opacity = 0.4;
        
        [UIView animateWithDuration:0.2 animations:^{
            lastToolbar.layer.transform = CATransform3DMakeRotation(M_PI_2, 1 * direction, 0, 0);
            lastToolbar.layer.opacity = 0.4;
            toolbarView.layer.transform = CATransform3DIdentity;
            toolbarView.layer.opacity = 1;
        } completion:^(BOOL finished) {
            lastToolbar.layer.transform = CATransform3DIdentity;
            [lastToolbar removeFromSuperview];
            
            [_toolbarViewController didMoveToParentViewController:self];
            [oldToolbarViewController removeFromParentViewController];
            
            [self didChangeValueForKey:@"toolbarViewController"];
        }];
    }
    else
    {
        [_toolbarViewController didMoveToParentViewController:self];
        [oldToolbarViewController removeFromParentViewController];
        if (!animated)
        {
            if (oldToolbarViewController.isViewLoaded)
                [oldToolbarViewController.view removeFromSuperview];
            [self.view addSubview:toolbarView];
            [self _layoutChildViewsAnimated:NO];
        }
        [self didChangeValueForKey:@"toolbarViewController"];
    }
}

- (CGFloat)toolbarHeight
{
    if (_toolbarHeight == 0)
        _toolbarHeight = DEFAULT_TOOLBAR_HEIGHT;
    return _toolbarHeight;
}

- (void)setToolbarHeight:(CGFloat)toolbarHeight
{
    [self setToolbarHeight:toolbarHeight animated:NO];
}

- (void)setToolbarHeight:(CGFloat)toolbarHeight animated:(BOOL)animated
{
    if (toolbarHeight == _toolbarHeight 
        || (toolbarHeight != DEFAULT_TOOLBAR_HEIGHT && self.currentToolbarView == self.defaultToolbar))
        return;
    
    _toolbarHeight = toolbarHeight;
    [self _layoutChildViewsAnimated:animated];
}

- (void)resetToolbarHeightAnimated:(BOOL)animated
{
    [self setToolbarHeight:DEFAULT_TOOLBAR_HEIGHT animated:animated];
}

- (NSString *)title
{
    return self.contentViewController.title;
}

- (void)setTitle:(NSString *)title
{
    self.contentViewController.title = title;
}

+ (NSSet *)keyPathsForValuesAffectingTitle
{
    return [NSSet setWithObject:@"contentViewController.title"];
}

#pragma mark Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self.contentViewController setEditing:editing animated:animated];
}

+ (NSSet *)keyPathsForValuesAffectingEditing
{
    return [NSSet setWithObject:@"contentViewController.editing"];
}

#pragma mark Tab

- (void)setTab:(ACTab *)tab
{
    if (tab == _tab)
        return;
    [self willChangeValueForKey:@"tab"];
    
    if (_tab)
    {
        [_tab removeObserver:self forKeyPath:@"currentURL" context:&tabCurrentURLObservingContext];
        [_tab.application removeTabAtIndex:[_tab.application.tabs indexOfObject:_tab]];
    }
    
    _tab = tab;
    
    [_tab addObserver:self forKeyPath:@"currentURL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&tabCurrentURLObservingContext];
    
    [self didChangeValueForKey:@"tab"];
}

#pragma mark - Controller methods

- (void)dealloc
{
    self.tab = nil;
    self.contentViewController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &tabCurrentURLObservingContext)
    {
        self.defaultToolbar.backButton.enabled = self.tab.canMoveBackInHistory;
        self.defaultToolbar.forwardButton.enabled = self.tab.canMoveForwardInHistory;
        [self setContentViewController:[self _routeViewControllerWithURL:self.tab.currentURL] animated:YES];
    }
    else if (context == &contentViewControllerContext)
    {
        if ([keyPath isEqualToString:@"editing"])
            [(UIButton *)self.defaultToolbar.editItem.customView setSelected:_contentViewController.isEditing];
        else if ([keyPath isEqualToString:@"toolbarItems"])
            [self _setupDefaultToolbarItemsAnimated:YES];
        else if ([keyPath isEqualToString:@"title"])
            [self _setupDefaultToolbarTitle];
        else if ([keyPath isEqualToString:@"loading"])
            self.defaultToolbar.titleControl.loadingMode = [object isLoading];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Adding child views
    [self.defaultToolbar removeFromSuperview];
    [self.view addSubview:self.currentToolbarView];
    [self.view addSubview:self.contentViewController.view];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self _layoutChildViewsAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self _setupDefaultToolbarItemsAnimated:NO];
}

#pragma mark - Private methods

- (BOOL)_isViewVisible
{
    return self.isViewLoaded && self.view.window != nil;
}

- (void)_layoutChildViewsAnimated:(BOOL)animated
{
    if (!self.isViewLoaded)
        return;
    
    CGRect contentFrame = self.view.bounds;
    CGRect toolbarFrame = contentFrame;
    toolbarFrame.size.height = self.toolbarHeight;
    contentFrame.origin.y += toolbarFrame.size.height;
    contentFrame.size.height -= toolbarFrame.size.height;
    
    if (animated)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.currentToolbarView.frame = toolbarFrame;
            if (self.contentViewController && self.contentViewController.isViewLoaded)
                self.contentViewController.view.frame = contentFrame;
        }];
    }
    else
    {
        self.currentToolbarView.frame = toolbarFrame;
        if (self.contentViewController && self.contentViewController.isViewLoaded)
            self.contentViewController.view.frame = contentFrame;
    }
}

- (void)_setupDefaultToolbarItemsAnimated:(BOOL)animated
{
    if (!self._isViewVisible)
        return;
    
    self.defaultToolbar.editItem = _contentViewController.editButtonItem;
    [self.defaultToolbar setToolItems:_contentViewController.toolbarItems animated:animated];
}

- (void)_setupDefaultToolbarTitle
{
    if (![_contentViewController respondsToSelector:@selector(singleTabController:setupDefaultToolbarTitleControl:)]
        || ![(UIViewController<ACSingleTabContentController> *)_contentViewController singleTabController:self setupDefaultToolbarTitleControl:self.defaultToolbar.titleControl])
    {
        if ([_contentViewController.title length] > 0)
        {
            [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObject:_contentViewController.title] selectedIndexes:nil];
        }
        else
        {
            NSString *currentPath = [self.tab.currentURL path];
            NSArray *pathComponents = [[currentPath substringFromIndex:MIN([[[ACProject projectsDirectory] path] length] + 1, [currentPath length])] pathComponents];
            NSMutableString *path = [NSMutableString stringWithString:[[pathComponents objectAtIndex:0] stringByDeletingPathExtension]];
            NSInteger lastIndex = [pathComponents count] - 1;
            [pathComponents enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *stop) {
                if (idx == 0 || idx == lastIndex)
                    return;
                [path appendFormat:@"/%@", component];
            }];
            [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObjects:path, [pathComponents lastObject], nil] selectedIndexes:nil];
            // TODO parse URL query to determine images etc...
//            [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObjects:
//                                                               [currentURL.path stringByDeletingLastPathComponent],
//                                                               [currentURL lastPathComponent], nil] 
//                                                selectedIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)]];
        }
    }
    
    self.defaultToolbar.titleControl.backgroundButton.enabled = [(UIViewController<ACSingleTabContentController> *)_contentViewController singleTabController:self shouldEnableTitleControlForDefaultToolbar:self.defaultToolbar];
}

- (UIViewController *)_routeViewControllerWithURL:(NSURL *)url
{
    UIViewController *result = nil;
    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    __block BOOL currentURLIsEqualToProjectsDirectory = NO;
    __block BOOL currentURLExists = NO;
    __block BOOL currentURLIsDirectory = NO;
    [fileCoordinator coordinateReadingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *newURL) {
        currentURLIsEqualToProjectsDirectory = [newURL isEqual:[ACProject projectsDirectory]];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        currentURLExists = [fileManager fileExistsAtPath:[newURL path] isDirectory:&currentURLIsDirectory];
    }];
    if (currentURLIsEqualToProjectsDirectory)
    {
        if ([self.contentViewController isKindOfClass:[ACProjectTableController class]])
            result = self.contentViewController;
        else
            result = [[ACProjectTableController alloc] init];
        ACProjectTableController *projectTableController = (ACProjectTableController *)result;
        projectTableController.projectsDirectory = url;
        projectTableController.tab = self.tab;
    }
    else if (currentURLExists)
    {
#warning TODO route bookmarks and remotes
        if (currentURLIsDirectory)
        {
            if ([self.contentViewController isKindOfClass:[ACFileTableController class]])
                result = self.contentViewController;
            else
                result = [[ACFileTableController alloc] initWithStyle:UITableViewStyleGrouped];
                
            ACFileTableController *fileTableController = (ACFileTableController *)result;
            fileTableController.tab = self.tab;
            [fileTableController setDirectory:url];
//            [self _setupDefaultToolbarTitle];
        }
        else
        {
            if ([self.contentViewController isKindOfClass:[ACCodeFileController class]])
                result = self.contentViewController;
            else
                result = [[ACCodeFileController alloc] init];
            ACCodeFileController *codeFileController = (ACCodeFileController *)result;
            codeFileController.fileURL = url;
            codeFileController.tab = self.tab;
        }
    }
    return result;
}

- (void)_defaultToolbarTitleButtonAction:(id)sender
{
    if ([self.contentViewController respondsToSelector:@selector(singleTabController:titleControlAction:)])
        [(UIViewController<ACSingleTabContentController> *)self.contentViewController singleTabController:self titleControlAction:sender];
}

- (void)_historyBackAction:(id)sender
{
    [self.tab moveBackInHistory];
}

- (void)_historyForwardAction:(id)sender
{
    [self.tab moveForwardInHistory];
}

@end

#pragma mark -

static const char *UIViewControllerLoadingKey = "UIViewControllerLoading";

@implementation UIViewController (ACSingleTabController)

- (ACSingleTabController *)singleTabController
{
    UIViewController *parent = self;
    while (parent && ![parent isKindOfClass:[ACSingleTabController class]])
        parent = parent.parentViewController;
    return (ACSingleTabController *)parent;
}

- (BOOL)singleTabController:(ACSingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(ACTopBarToolbar *)toolbar
{
    return NO;
}

- (BOOL)isLoading
{
    return [objc_getAssociatedObject(self, UIViewControllerLoadingKey) boolValue];
}

- (void)setLoading:(BOOL)loading
{
    if (loading == self.isLoading)
        return;
    
    [self willChangeValueForKey:@"loading"];
    objc_setAssociatedObject(self, UIViewControllerLoadingKey, [NSNumber numberWithBool:loading], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"loading"];
}

@end
