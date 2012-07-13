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

#import "ProjectBrowserController.h"
#import "FileBrowserController.h"
#import "BookmarkBrowserController.h"
#import "CodeFileController.h"
#import "RemotesListController.h"
#import "RemoteBrowserController.h"
#import "DocSetBrowserController.h"

#import "UIImage+AppStyle.h"

#define DEFAULT_TOOLBAR_HEIGHT 44

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

  _contentViewController = contentViewController;

  [self didChangeValueForKey:@"contentViewController"];
}

+ (BOOL)automaticallyNotifiesObserversOfContentViewController {
  return NO;
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
  return self.contentViewController.title ?: self.defaultToolbar.titleControl.title;
}

- (void)setTitle:(NSString *)title
{
  self.contentViewController.title = title;
}

+ (NSSet *)keyPathsForValuesAffectingTitle
{
  return [NSSet setWithObjects:@"contentViewController.title", @"defaultToolbar.titleControl.titleFragments", nil];
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

#pragma mark - Controller methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  
  // RAC
  __weak SingleTabController *this = self;
  
  // Loading mode react to tab loading signal
  [self rac_bind:RAC_KEYPATH_SELF(self.defaultToolbar.titleControl.loadingMode) to:[[RACAbleSelf(self.artCodeTab.loading) merge:RACAbleSelf(self.contentViewController.loading)] where:^BOOL(id x) {
    return x != nil;
  }]];

  // Back and forward buttons to tab history
  [self rac_bind:RAC_KEYPATH_SELF(self.defaultToolbar.backButton.enabled) to:RACAbleSelf(self.artCodeTab.canMoveBackInHistory)];
  [self rac_bind:RAC_KEYPATH_SELF(self.defaultToolbar.forwardButton.enabled) to:RACAbleSelf(self.artCodeTab.canMoveForwardInHistory)];
  
  // Changing current tab URL re-route the content view controller
  [RACAbleSelf(self.artCodeTab.currentURL) subscribeNext:^(id x) {
    if (!x)
      return;
    [this setContentViewController:[this _routeViewControllerForTab:this.artCodeTab] animated:YES];
  }];
    
  // Content view controller binds
  [RACAbleSelf(self.contentViewController.editing) subscribeNext:^(id x) {
    [(UIButton *)this.defaultToolbar.editItem.customView setSelected:[x boolValue]];
  }];
  
  [RACAbleSelf(self.contentViewController.toolbarItems) subscribeNext:^(id x) {
    [this _setupDefaultToolbarItemsAnimated:YES];
  }];
  
  // Update tool bar title when project changes
  [[self rac_whenAny:[NSArray arrayWithObjects:RAC_KEYPATH_SELF(self.artCodeTab.currentProject.labelColor), RAC_KEYPATH_SELF(self.artCodeTab.currentProject.name), RAC_KEYPATH_SELF(self.contentViewController.title), nil] reduce:^id(RACTuple *xs) {
    return nil;
  }] subscribeNext:^(id x) {
    [this updateDefaultToolbarTitle];
  }];
  
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.defaultToolbar = [[TopBarToolbar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
  self.defaultToolbar.accessibilityIdentifier = @"default toolbar";
  self.defaultToolbar.titleControl.accessibilityHint = L(@"Open quick navigation browsers");
  self.defaultToolbar.titleControl.accessibilityIdentifier = @"title control";
  
  // Adding child views
  [self.defaultToolbar removeFromSuperview];
  [self.view addSubview:self.currentToolbarView];
  [self.view addSubview:self.contentViewController.view];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self _layoutChildViewsAnimated:NO];
  //
  [self updateDefaultToolbarTitle];
  self.defaultToolbar.titleControl.loadingMode = self.artCodeTab.isLoading;
  self.defaultToolbar.backButton.enabled = self.artCodeTab.canMoveBackInHistory;
  self.defaultToolbar.forwardButton.enabled = self.artCodeTab.canMoveForwardInHistory;
}

- (void)viewDidAppear:(BOOL)animated
{
  [self _setupDefaultToolbarItemsAnimated:NO];
}

#pragma mark - Public methods

- (void)updateDefaultToolbarTitle
{
  if (![self.contentViewController respondsToSelector:@selector(singleTabController:setupDefaultToolbarTitleControl:)]
      || ![(UIViewController<SingleTabContentController> *)self.contentViewController singleTabController:self setupDefaultToolbarTitleControl:self.defaultToolbar.titleControl])
  {
    if ([self.contentViewController.title length] > 0)
    {
      [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObject:self.contentViewController.title] selectedIndexes:nil];
    }
    else
    {
      NSURL *url = self.artCodeTab.currentURL;
//      if ([url isArtCodeURL])
//      {
//        ACProjectItem *item = self.artCodeTab.currentItem;
//        switch (item.type)
//        {
//          case ACPRemote:
//            url = [(ArtCodeRemote *)item URL];
//            break;
//            
//          case ACPFileBookmark:
//            item = (ACProjectItem *)[(ArtCodeBookmark *)item file];
//            
//          default:
//          {
//            // If project root set color and project name 
//            if ([(ACProjectFileSystemItem *)item parentFolder] == nil)
//            {
//              [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObjects:[UIImage styleProjectLabelImageWithSize:CGSizeMake(12, 22) color:self.artCodeTab.currentProject.labelColor], self.artCodeTab.currentProject.name, nil] selectedIndexes:nil];
//            }
//            // or path and file name for items
//            else
//            {
//              NSString *path = [(ACProjectFileSystemItem *)item pathInProject];
//              [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObjects:[path stringByDeletingLastPathComponent], [path lastPathComponent], nil] selectedIndexes:nil];
//            }
//            // Mark url as handled
//            url = nil;
//            break;
//          }
//        }
//      }
//      
      // If URL has not been handled jet
      if (url)
      {
        [self.defaultToolbar.titleControl setTitleFragments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%@://", url.scheme], url.host, url.path, nil] selectedIndexes:[NSIndexSet indexSetWithIndex:1]];
      }
    }
  }
  
  self.defaultToolbar.titleControl.backgroundButton.enabled = [(UIViewController<SingleTabContentController> *)self.contentViewController singleTabController:self shouldEnableTitleControlForDefaultToolbar:self.defaultToolbar];
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
  
  self.defaultToolbar.editItem = self.contentViewController.editButtonItem;
  [self.defaultToolbar setToolItems:self.contentViewController.toolbarItems animated:animated];
}

- (UIViewController *)_routeViewControllerForTab:(ArtCodeTab *)tab
{
  NSURL *currentURL = tab.currentURL;
  UIViewController *result = nil;
  
  // ArtCode URLs routing
  if ([currentURL isArtCodeURL])
  {
    Class controllerClass = nil;
    
    switch (currentURL.artCodeType) {
      case ArtCodeURLTypeProjectsList:
      {
        controllerClass = [ProjectBrowserController class];
        break;
      }
      case ArtCodeURLTypeBookmarksList:
      case ArtCodeURLTypeBookmark:
      {
        controllerClass = [BookmarkBrowserController class];
        break;
      }
      case ArtCodeURLTypeRemotesList:
      case ArtCodeURLTypeRemote:
      {
        controllerClass = [RemotesListController class];
        break;
      }
      case ArtCodeURLTypeTextFile:
      {
        controllerClass = [CodeFileController class];
        break;
      }
      case ArtCodeURLTypeProject:
      case ArtCodeURLTypeDirectory:
      case ArtCodeURLTypeFile:
      {
        controllerClass = [FileBrowserController class];
        break;
      }
    }
    if ([self.contentViewController isKindOfClass:controllerClass]) {
      result = self.contentViewController;
    } else {
      result = [controllerClass new];
    }
  } else if ([currentURL.scheme isEqualToString:@"docset"]) {
    if ([self.contentViewController isKindOfClass:[DocSetBrowserController class]])
      result = self.contentViewController;
    else
      result = [DocSetBrowserController new];
  } else {
    ASSERT(NO); // Unknown URL
  }
  
  // Set the tab explicitly since result might not have a parent view controller yet
  result.artCodeTab = self.artCodeTab;

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
