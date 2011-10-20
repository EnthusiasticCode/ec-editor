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

#import "ACTab.h"
#import "ACApplication.h"

#import "ACProjectTableController.h"
#import "ACFileTableController.h"
#import "ACCodeFileController.h"

#define DEFAULT_TOOLBAR_HEIGHT 44
static void *tabCurrentURLObservingContext;

@interface ACSingleTabController () {
@private
    NSMutableArray *toolbars;
}

- (void)_layoutChildViewsAnimated:(BOOL)animated;
- (void)_setupDefaultToolbarAnimated:(BOOL)animated;
- (UIViewController *)_viewControllerWithURL:(NSURL *)url;

@end


@implementation ACSingleTabController

#pragma mark - Properties

@synthesize defaultToolbar = _defaultToolbar, contentViewController = _contentViewController;
@synthesize toolbarHeight = _toolbarHeight;
@synthesize tab = _tab;

- (void)setDefaultToolbar:(ACTopBarToolbar *)defaultToolbar
{
    if (defaultToolbar == _defaultToolbar)
        return;
    
    [self willChangeValueForKey:@"defaultToolbar"];
    
    if (self.isViewLoaded)
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
    
    [self didChangeValueForKey:@"defaultToolbar"];
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
    if (self.isViewLoaded)
    {
        [_contentViewController viewWillDisappear:animated];
        [contentViewController viewWillAppear:animated];
        
        if (_contentViewController != nil && animated)
        {
            [UIView transitionFromView:_contentViewController.view toView:contentViewController.view duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
                [_contentViewController.view removeFromSuperview];
                [_contentViewController viewDidDisappear:YES];
                [contentViewController viewDidAppear:YES];
            }];
        }
        else
        {
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
    }

    // Setup new controller
    if ((_contentViewController = contentViewController))
    {
        [self addChildViewController:_contentViewController];
        [_contentViewController didMoveToParentViewController:self];
    }
    
    [self _layoutChildViewsAnimated:animated];
    [self _setupDefaultToolbarAnimated:animated];
    
    [self didChangeValueForKey:@"contentViewController"];
}

- (UIView *)currentToolbarView
{
    if (toolbars && [toolbars count])
        return [toolbars lastObject];
    return self.defaultToolbar;
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
    [_tab removeObserver:self forKeyPath:@"currentURL" context:&tabCurrentURLObservingContext];
    _tab = tab;
    [_tab addObserver:self forKeyPath:@"currentURL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&tabCurrentURLObservingContext];
    [self didChangeValueForKey:@"tab"];
}

#pragma mark - Controller methods

- (void)dealloc
{
    [self.tab removeObserver:self forKeyPath:@"currentURL" context:&tabCurrentURLObservingContext];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &tabCurrentURLObservingContext)
    {
        self.contentViewController = [self _viewControllerWithURL:self.tab.currentURL];
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
    UIView *currentToolbar = self.currentToolbarView;
    if (currentToolbar != self.defaultToolbar)
    {
        [self.defaultToolbar removeFromSuperview];
        [self.view addSubview:currentToolbar];
    }
    [self.view addSubview:self.contentViewController.view];
    
    // Layout and setup
    [self _setupDefaultToolbarAnimated:NO];
    [self _layoutChildViewsAnimated:NO];
}


#pragma mark - Toolbars control

- (void)pushToolbarView:(UIView *)toolbarView animated:(BOOL)animated
{
    ECASSERT(toolbarView != nil);
    
    UIView *lastToolbar = self.currentToolbarView;
    toolbarView.frame = lastToolbar.frame;
    toolbarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    
    if (!toolbars)
        toolbars = [NSMutableArray new];
    [toolbars addObject:toolbarView];
    
    if (self.isViewLoaded)
    {
        [self resetToolbarHeightAnimated:animated];
        
        if (animated)
        {
            lastToolbar.layer.anchorPointZ = 19;
            [self.view addSubview:toolbarView];
            toolbarView.frame = lastToolbar.frame;
            toolbarView.layer.anchorPointZ = 19;
            toolbarView.layer.transform = CATransform3DMakeRotation(M_PI_2, -1, 0, 0);
            toolbarView.layer.opacity = 0.4;
            
            [UIView animateWithDuration:0.2 animations:^{
                lastToolbar.layer.transform = CATransform3DMakeRotation(M_PI_2, 1, 0, 0);
                lastToolbar.layer.opacity = 0.4;
                toolbarView.layer.transform = CATransform3DIdentity;
                toolbarView.layer.opacity = 1;
            } completion:^(BOOL finished) {
                lastToolbar.layer.transform = CATransform3DIdentity;
                [lastToolbar removeFromSuperview];
            }];
        }
        else
        {
            [lastToolbar removeFromSuperview];
            [self.view addSubview:toolbarView];
            [self _layoutChildViewsAnimated:NO];
        }
    }
}

- (void)popToolbarViewAnimated:(BOOL)animated
{
    if (![toolbars count])
        return;
    
    if (self.isViewLoaded)
    {
        [self resetToolbarHeightAnimated:animated];
        
        UIView *currentToolbar = [toolbars lastObject];
        UIView *lastToolbar = self.defaultToolbar;
        if ([toolbars count] > 1)
            lastToolbar = [toolbars objectAtIndex:[toolbars count] - 2];
        if (animated)
        {
            currentToolbar.layer.anchorPointZ = 19;
            [self.view addSubview:lastToolbar];
            lastToolbar.frame = currentToolbar.frame;
            lastToolbar.layer.anchorPointZ = 19;
            lastToolbar.layer.transform = CATransform3DMakeRotation(M_PI_2, 1, 0, 0);
            lastToolbar.layer.opacity = 0.4;
            
            [UIView animateWithDuration:0.2 animations:^{
                currentToolbar.layer.transform = CATransform3DMakeRotation(M_PI_2, -1, 0, 0);
                currentToolbar.layer.opacity = 0.4;
                lastToolbar.layer.transform = CATransform3DIdentity;
                lastToolbar.layer.opacity = 1;
            } completion:^(BOOL finished) {
                currentToolbar.layer.transform = CATransform3DIdentity;
                [currentToolbar removeFromSuperview];
            }];
        }
        else
        {
            [currentToolbar removeFromSuperview];
            [self.view addSubview:lastToolbar];
        }
        
        [self _layoutChildViewsAnimated:NO];
    }
    
    [toolbars removeLastObject];
}

#pragma mark - Private methods

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

- (void)_setupDefaultToolbarAnimated:(BOOL)animated
{
    if (!self.isViewLoaded)
        return;
    
    [self.defaultToolbar.titleControl setTitle:_contentViewController.title forState:UIControlStateNormal];
    self.defaultToolbar.editItem = _contentViewController.editButtonItem;
    [self.defaultToolbar setToolItems:_contentViewController.toolbarItems animated:animated];
}

- (UIViewController *)_viewControllerWithURL:(NSURL *)url
{
    UIViewController *result = nil;
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    __block BOOL currentURLIsEqualToProjectsDirectory = NO;
    __block BOOL currentURLExists = NO;
    __block BOOL currentURLIsDirectory = NO;
    [fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingResolvesSymbolicLink | NSFileCoordinatorReadingWithoutChanges error:NULL byAccessor:^(NSURL *newURL) {
        currentURLIsEqualToProjectsDirectory = [newURL isEqual:[self.tab.application projectsDirectory]];
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
        if (currentURLIsDirectory)
        {
            if ([self.contentViewController isKindOfClass:[ACFileTableController class]])
                result = self.contentViewController;
            else
                result = [[ACFileTableController alloc] init];
            ACFileTableController *fileTableController = (ACFileTableController *)result;
            fileTableController.directory = url;
            fileTableController.tab = self.tab;
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

@end

#pragma mark -

@implementation UIViewController (ACSingleTabController)

- (ACSingleTabController *)singleTabController
{
    UIViewController *parent = self;
    while (parent && ![parent isKindOfClass:[ACSingleTabController class]])
        parent = parent.parentViewController;
    return (ACSingleTabController *)parent;
}

@end
