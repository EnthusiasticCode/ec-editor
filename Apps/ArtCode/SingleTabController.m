//
//  ToolbarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SingleTabController.h"
#import "TopBarToolbar.h"
#import "TopBarTitleControl.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"

#import "ProjectBrowserController.h"
#import "FileBrowserController.h"
#import "BookmarkBrowserController.h"
#import "CodeFileController.h"

#define DEFAULT_TOOLBAR_HEIGHT 44
static const void *tabCurrentURLObservingContext;
static const void *contentViewControllerContext;

@interface SingleTabController ()

- (BOOL)_isViewVisible;

/// Position the bar and content.
- (void)_layoutChildViewsAnimated:(BOOL)animated;

/// Will setup the toolbar items.
- (void)_setupDefaultToolbarItemsAnimated:(BOOL)animated;

/// Routing method that resolve an URL to the view controller that can handle it.
- (UIViewController *)_routeViewControllerWithURL:(NSURL *)url;

- (void)_defaultToolbarTitleButtonAction:(id)sender;
- (void)_historyBackAction:(id)sender;
- (void)_historyForwardAction:(id)sender;

@end


@implementation SingleTabController

#pragma mark - Properties

@synthesize defaultToolbar = _defaultToolbar, toolbarViewController = _toolbarViewController, toolbarHeight = _toolbarHeight;
@synthesize contentViewController = _contentViewController;


- (TopBarToolbar *)defaultToolbar
{
    if (!_defaultToolbar)
    {
        self.defaultToolbar = [[TopBarToolbar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
    }
    return _defaultToolbar;
}

- (void)setDefaultToolbar:(TopBarToolbar *)defaultToolbar
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
    
    [_contentViewController willMoveToParentViewController:nil];
    [_contentViewController removeFromParentViewController];
    if (contentViewController)
    {
        [self addChildViewController:contentViewController];
        [contentViewController didMoveToParentViewController:self];
    }
    
    // Animate view in position
    if (self._isViewVisible)
    {
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
            if (_contentViewController)
                contentViewController.view.frame = _contentViewController.view.frame;
            [self.view addSubview:contentViewController.view];
            [_contentViewController.view removeFromSuperview];
        }
    }
    
    // Remove old view controller
    if (_contentViewController)
    {
        [_contentViewController removeObserver:self forKeyPath:@"toolbarItems" context:&contentViewControllerContext];
        [_contentViewController removeObserver:self forKeyPath:@"loading" context:&contentViewControllerContext];
        [_contentViewController removeObserver:self forKeyPath:@"title" context:&contentViewControllerContext];
        [_contentViewController removeObserver:self forKeyPath:@"editing" context:&contentViewControllerContext];
    }

    // Setup new controller
    if ((_contentViewController = contentViewController))
    {
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

- (void)setArtCodeTab:(ArtCodeTab *)tab
{
    if (tab == self.artCodeTab)
        return;
    
    if (self.artCodeTab)
    {
        [self.artCodeTab removeObserver:self forKeyPath:@"currentURL" context:&tabCurrentURLObservingContext];
        [ArtCodeTab removeTab:self.artCodeTab];
    }
    
    [super setArtCodeTab:tab];

    [self.artCodeTab addObserver:self forKeyPath:@"currentURL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&tabCurrentURLObservingContext];
}

#pragma mark - Controller methods

- (void)dealloc
{
    self.artCodeTab = nil;
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
        self.defaultToolbar.backButton.enabled = self.artCodeTab.canMoveBackInHistory;
        self.defaultToolbar.forwardButton.enabled = self.artCodeTab.canMoveForwardInHistory;
        [self setContentViewController:[self _routeViewControllerWithURL:self.artCodeTab.currentURL] animated:YES];
    }
    else if (context == &contentViewControllerContext)
    {
        if ([keyPath isEqualToString:@"editing"])
            [(UIButton *)self.defaultToolbar.editItem.customView setSelected:_contentViewController.isEditing];
        else if ([keyPath isEqualToString:@"toolbarItems"])
            [self _setupDefaultToolbarItemsAnimated:YES];
        else if ([keyPath isEqualToString:@"title"])
            [self updateDefaultToolbarTitle];
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

#pragma mark - Public methods

- (void)updateDefaultToolbarTitle
{
    if (![_contentViewController respondsToSelector:@selector(singleTabController:setupDefaultToolbarTitleControl:)]
        || ![(UIViewController<SingleTabContentController> *)_contentViewController singleTabController:self setupDefaultToolbarTitleControl:self.defaultToolbar.titleControl])
    {
        if ([_contentViewController.title length] > 0)
        {
            [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObject:_contentViewController.title] selectedIndexes:nil];
        }
        else
        {
            NSArray *pathComponents = [[ArtCodeURL pathRelativeToProjectsDirectory:self.artCodeTab.currentURL] pathComponents];
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
    
    self.defaultToolbar.titleControl.backgroundButton.enabled = [(UIViewController<SingleTabContentController> *)_contentViewController singleTabController:self shouldEnableTitleControlForDefaultToolbar:self.defaultToolbar];
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

- (UIViewController *)_routeViewControllerWithURL:(NSURL *)url
{
    UIViewController *result = nil;
//    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    __block BOOL currentURLIsEqualToProjectsDirectory = NO;
    __block BOOL currentURLExists = NO;
    __block BOOL currentURLIsDirectory = NO;
#warning calling file coordinator from main thread deadlocks uidocument
//    [fileCoordinator coordinateReadingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *newURL) {
        currentURLIsEqualToProjectsDirectory = [url isEqual:[ArtCodeURL projectsDirectory]];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        currentURLExists = [fileManager fileExistsAtPath:[url path] isDirectory:&currentURLIsDirectory];
//    }];
    if (currentURLIsEqualToProjectsDirectory)
    {
        if ([self.contentViewController isKindOfClass:[ProjectBrowserController class]])
            result = self.contentViewController;
        else
            result = [[ProjectBrowserController alloc] init];
        ProjectBrowserController *projectTableController = (ProjectBrowserController *)result;
        projectTableController.projectsDirectory = url;
    }
    else if (currentURLExists)
    {
        // TODO route bookmarks and remotes
        if (currentURLIsDirectory)
        {
            if ([url isBookmarksVariant])
            {
                if ([self.contentViewController isKindOfClass:[BookmarkBrowserController class]])
                    result = self.contentViewController;
                else
                    result = [BookmarkBrowserController new];
            }
            else
            {
                if ([self.contentViewController isKindOfClass:[FileBrowserController class]])
                    result = self.contentViewController;
                else
                    result = [[FileBrowserController alloc] init];
                    
                FileBrowserController *fileTableController = (FileBrowserController *)result;
                [fileTableController setDirectory:url];
                if (result == self.contentViewController)
                    [self updateDefaultToolbarTitle];
            }
        }
        else
        {
            if ([self.contentViewController isKindOfClass:[CodeFileController class]])
                result = self.contentViewController;
            else
                result = [[CodeFileController alloc] init];
            CodeFileController *codeFileController = (CodeFileController *)result;
            codeFileController.fileURL = url;
        }
    }
    return result;
}

- (void)_defaultToolbarTitleButtonAction:(id)sender
{
    if ([self.contentViewController respondsToSelector:@selector(singleTabController:titleControlAction:)])
        [(UIViewController<SingleTabContentController> *)self.contentViewController singleTabController:self titleControlAction:sender];
}

- (void)_historyBackAction:(id)sender
{
    [self.artCodeTab moveBackInHistory];
}

- (void)_historyForwardAction:(id)sender
{
    [self.artCodeTab moveForwardInHistory];
}

@end

#pragma mark -

static const char *UIViewControllerLoadingKey = "UIViewControllerLoading";

@implementation UIViewController (SingleTabController)

- (SingleTabController *)singleTabController
{
    UIViewController *parent = self;
    while (parent && ![parent isKindOfClass:[SingleTabController class]])
        parent = parent.parentViewController;
    return (SingleTabController *)parent;
}

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar
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
