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

#import "ACProject.h"
#import "ACProjectItem.h"
#import "ACProjectFileSystemItem.h"
#import "ACProjectFileBookmark.h"
#import "ACProjectRemote.h"

#import "ProjectBrowserController.h"
#import "FileBrowserController.h"
#import "BookmarkBrowserController.h"
#import "CodeFileController.h"
#import "RemotesListController.h"
#import "RemoteBrowserController.h"
#import "UIImage+AppStyle.h"

#define DEFAULT_TOOLBAR_HEIGHT 44
static const void *tabCurrentURLObservingContext;
static const void *contentViewControllerContext;
static const void *loadingObservingContext;

@interface SingleTabController ()

- (BOOL)_isViewVisible;

/// Position the bar and content.
- (void)_layoutChildViewsAnimated:(BOOL)animated;

/// Will setup the toolbar items.
- (void)_setupDefaultToolbarItemsAnimated:(BOOL)animated;

/// Routing method that resolve the ArtCodeTab current location to the view controller that can handle it.
- (UIViewController *)_routeViewControllerForTab:(ArtCodeTab *)tab;

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
    self.defaultToolbar.accessibilityIdentifier = @"default toolbar";
    self.defaultToolbar.titleControl.accessibilityHint = L(@"Open quick navigation browsers");
  }
  return _defaultToolbar;
}

- (void)setDefaultToolbar:(TopBarToolbar *)defaultToolbar
{
  if (defaultToolbar == _defaultToolbar)
    return;
  
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
    [_contentViewController removeObserver:self forKeyPath:@"title" context:&contentViewControllerContext];
    [_contentViewController removeObserver:self forKeyPath:@"editing" context:&contentViewControllerContext];
    
    [_contentViewController removeObserver:self forKeyPath:@"loading" context:&loadingObservingContext];
  }
  
  // Setup new controller
  if ((_contentViewController = contentViewController))
  {
    [_contentViewController addObserver:self forKeyPath:@"toolbarItems" options:NSKeyValueObservingOptionNew context:&contentViewControllerContext];
    [_contentViewController addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&contentViewControllerContext];
    [_contentViewController addObserver:self forKeyPath:@"editing" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&contentViewControllerContext];
    
    [_contentViewController addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&loadingObservingContext];
  }
  
  [self _setupDefaultToolbarItemsAnimated:animated];
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
  
  self.loading = YES;
  
  if (self.artCodeTab)
  {
    [self.artCodeTab removeObserver:self forKeyPath:@"currentURL" context:&tabCurrentURLObservingContext];
    [self.artCodeTab removeObserver:self forKeyPath:@"loading" context:&loadingObservingContext];
    [ArtCodeTab removeTab:self.artCodeTab];
  }
  
  [super setArtCodeTab:tab];
  
  [self.artCodeTab addObserver:self forKeyPath:@"currentURL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&tabCurrentURLObservingContext];
  [self.artCodeTab addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&loadingObservingContext];
  
  // The artcodetab in this controller will be set when the app starts, this method makes sure that the project is loaded
  [tab reloadCurrentStatusWithCompletionHandler:^(BOOL success) {
    [self updateDefaultToolbarTitle];
    self.contentViewController.artCodeTab = self.artCodeTab;
    self.loading = NO;
  }];
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
    [self setContentViewController:[self _routeViewControllerForTab:self.artCodeTab] animated:YES];
  }
  else if (context == &contentViewControllerContext)
  {
    if ([keyPath isEqualToString:@"editing"])
      [(UIButton *)self.defaultToolbar.editItem.customView setSelected:_contentViewController.isEditing];
    else if ([keyPath isEqualToString:@"toolbarItems"])
      [self _setupDefaultToolbarItemsAnimated:YES];
    else if ([keyPath isEqualToString:@"title"])
      [self updateDefaultToolbarTitle];
  }
  else if (context == &loadingObservingContext)
  {
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
      NSURL *url = self.artCodeTab.currentURL;
      if ([url isArtCodeURL])
      {
        ACProjectItem *item = self.artCodeTab.currentItem;
        switch (item.type)
        {
          case ACPRemote:
            url = [(ACProjectRemote *)item URL];
            break;
            
          case ACPFileBookmark:
            item = (ACProjectItem *)[(ACProjectFileBookmark *)item file];
            
          default:
          {
            // If project root set color and project name 
            if ([(ACProjectFileSystemItem *)item parentFolder] == nil)
            {
              [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObjects:[UIImage styleProjectLabelImageWithSize:CGSizeMake(12, 22) color:self.artCodeTab.currentProject.labelColor], self.artCodeTab.currentProject.name, nil] selectedIndexes:nil];
            }
            // or path and file name for items
            else
            {
              NSString *path = [(ACProjectFileSystemItem *)item pathInProject];
              [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObjects:[path stringByDeletingLastPathComponent], [path lastPathComponent], nil] selectedIndexes:nil];
            }
            // Mark url as handled
            url = nil;
            break;
          }
        }
      }
      
      // If URL has not been handled jet
      if (url)
      {
        [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%@://", url.scheme], url.host, url.path, nil] selectedIndexes:[NSIndexSet indexSetWithIndex:1]];
      }
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

- (UIViewController *)_routeViewControllerForTab:(ArtCodeTab *)tab
{
  NSURL *currentURL = tab.currentURL;
  UIViewController *result = nil;
  
  // ArtCode URLs routing
  if ([currentURL isArtCodeURL])
  {
    // Projects list
    if ([currentURL isArtCodeProjectsList])
    {
      if ([self.contentViewController isKindOfClass:[ProjectBrowserController class]])
        result = self.contentViewController;
      else
        result = [ProjectBrowserController new];
    }
    // Project's bookmarks list
    else if ([currentURL isArtCodeProjectBookmarksList])
    {
      if ([self.contentViewController isKindOfClass:[BookmarkBrowserController class]])
        result = self.contentViewController;
      else
        result = [BookmarkBrowserController new];
    }
    // Project's remotes list
    else if ([currentURL isArtCodeProjectRemotesList])
    {
      if ([self.contentViewController isKindOfClass:[RemotesListController class]])
        result = self.contentViewController;
      else
        result = [RemotesListController new];
    }
    // Project's item
    else
    {
      switch (tab.currentItem.type) {   
        case ACPFile:
        case ACPFileBookmark:
        {
          if ([self.contentViewController isKindOfClass:[CodeFileController class]])
            result = self.contentViewController;
          else
            result = [CodeFileController new];
          break;
        }
          
        case ACPRemote:
        {
          if ([self.contentViewController isKindOfClass:[RemoteBrowserController class]])
            result = self.contentViewController;
          else
            result = [RemoteBrowserController new];
          break;
        }
          
        default:
        {
          if ([self.contentViewController isKindOfClass:[FileBrowserController class]])
            result = self.contentViewController;
          else
            result = [FileBrowserController new];
          break;
        }
      }
    }
    
    // Set the tab explicitly since result might not have a parent view controller yet
    result.artCodeTab = self.artCodeTab;
  }
  else 
  {
    ASSERT(NO); // Unknown URL
  }
  
  // Update title if controller didn't change
  if (result == self.contentViewController)
  {
    [self updateDefaultToolbarTitle];
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
  
  objc_setAssociatedObject(self, UIViewControllerLoadingKey, [NSNumber numberWithBool:loading], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
