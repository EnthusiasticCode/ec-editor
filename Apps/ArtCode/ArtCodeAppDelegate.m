//
//  ArtCodeAppDelegate.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import "ArtCodeAppDelegate.h"

#import "CodeView.h"
#import "UIControl+BlockAction.h"

#import "AppStyle.h"
#import "TabController.h"

#import "SingleTabController.h"

#import "TabBar.h"
#import "TopBarToolbar.h"
#import "TopBarTitleControl.h"
#import "CodeFileSearchBarController.h"
#import "SearchableTableBrowserController.h"
#import "PopoverButton.h"

#import "ArtCodeTab.h"


@implementation ArtCodeAppDelegate

@synthesize window = _window;
@synthesize tabController = _tabController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  UIFont *defaultFont = [UIFont styleFontWithSize:14];
  
  ////////////////////////////////////////////////////////////////////////////
  // Generic text field
  id textFieldAppearance = [UITextField appearance];
  [textFieldAppearance setTextColor:[UIColor styleForegroundColor]];
  [(UITextField *)textFieldAppearance setFont:defaultFont];
  
  ////////////////////////////////////////////////////////////////////////////
  // Generic popover
  id popoverAppearance = [ShapePopoverBackgroundView appearance];
  //    [popoverAppearance setBackgroundColor:[UIColor colorWithRed:57.0/255.0 green:58.0/255.0 blue:62.0/255.0 alpha:1.0]];
  [(ShapePopoverBackgroundView *)popoverAppearance setBackgroundColor:[UIColor colorWithRed:67.0/255.0 green:68.0/255.0 blue:72.0/255.0 alpha:1.0]];
  [(ShapePopoverBackgroundView *)popoverAppearance setStrokeColor:[UIColor colorWithWhite:0.34 alpha:1]];
  [popoverAppearance setShadowOpacity:0.7];
  [popoverAppearance setShadowRadius:4];
  [popoverAppearance setShadowOffsetForArrowDirectionUpToAutoOrient:CGSizeMake(0, 1)];
  
  ////////////////////////////////////////////////////////////////////////////
  // Button in generic navigation controller
  [[PopoverButton appearance] setBackgroundImage:[UIImage stylePopoverButtonBackgroundImage] forState:UIControlStateNormal];
  
  ////////////////////////////////////////////////////////////////////////////
  // UI Bars
  [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forBarMetrics:UIBarMetricsDefault];
  [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIColor blackColor], UITextAttributeTextShadowColor, [NSValue valueWithUIOffset:UIOffsetMake(0, -1)], UITextAttributeTextShadowOffset, nil]];
  
  [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
  
  [[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"topBar_Secondary_Background"]];
  
  [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage styleBackButtonBackgroundImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  [[UIBarButtonItem appearance] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateSelected] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  
  ////////////////////////////////////////////////////////////////////////////
  // Tab Bar    
  id buttonInTabBarAppearance = [TabBarButton appearance];
  [buttonInTabBarAppearance setBackgroundImage:[[UIImage imageNamed:@"tabBar_TabBackground_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateNormal];
  [buttonInTabBarAppearance setBackgroundImage:[[UIImage imageNamed:@"tabBar_TabBackground_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateSelected];
  [buttonInTabBarAppearance setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
  [buttonInTabBarAppearance setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
  [buttonInTabBarAppearance setTitleShadowColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateNormal];
  
  [[TabBarButtonCloseButton appearance] setImage:[UIImage imageNamed:@"tabBar_TabCloseButton"] forState:UIControlStateNormal];
  
  ////////////////////////////////////////////////////////////////////////////
  // Top bar
  [[TopBarToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"topBar_Background"]];
  
  id TopBarTitleControlAppearance = [TopBarTitleControl appearance];
  [TopBarTitleControlAppearance setBackgroundImage:[[UIImage imageNamed:@"topBar_TitleButton_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateNormal];
  [TopBarTitleControlAppearance setBackgroundImage:[[UIImage imageNamed:@"topBar_TitleButton_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateSelected];
  [TopBarTitleControlAppearance setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forState:UIControlStateDisabled];
  [TopBarTitleControlAppearance setGapBetweenFragments:3];
  [TopBarTitleControlAppearance setContentInsets:UIEdgeInsetsMake(3, 10, 3, 10)];
  [TopBarTitleControlAppearance setSelectedTitleFragmentsTint:[UIColor whiteColor]];
  [TopBarTitleControlAppearance setSecondaryTitleFragmentsTint:[UIColor colorWithWhite:0.7 alpha:1]];
  [TopBarTitleControlAppearance setSelectedFragmentFont:[UIFont boldSystemFontOfSize:20]];
  [TopBarTitleControlAppearance setSecondaryFragmentFont:[UIFont systemFontOfSize:14]];
  
  [[TopBarToolButton appearance] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal];
  [[TopBarToolButton appearance] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateSelected] forState:UIControlStateSelected];
  [[TopBarToolButton appearanceWhenContainedIn:[CodeFileSearchBarView class], nil] setBackgroundImage:[[UIImage imageNamed:@"searchBar_Button_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forState:UIControlStateNormal];
  
  ////////////////////////////////////////////////////////////////////////////
  // Browsers bottom tool bar
  [[BottomToolBarButton appearance] setBackgroundImage:[[UIImage imageNamed:@"bottomToolBar_Button"] resizableImageWithCapInsets:UIEdgeInsetsMake(7, 7, 7, 7)] forState:UIControlStateNormal];
  
  ////////////////////////////////////////////////////////////////////////////
  // Code view elements
  [(CodeFlashView *)[CodeFlashView appearance] setBackgroundColor:[UIColor yellowColor]];
  
  ////////////////////////////////////////////////////////////////////////////
  // Creating main tab controllers
  self.tabController = [[TabController alloc] init];
  self.tabController.tabBar.backgroundColor = [UIColor blackColor];
  self.tabController.tabBar.tabControlInsets = UIEdgeInsetsMake(2, 3, 0, 3);
  self.tabController.definesPresentationContext = YES;
  // Add tab button
  UIButton *addTabButton = [UIButton new];
  [addTabButton setImage:[UIImage imageNamed:@"tabBar_TabAddButton"] forState:UIControlStateNormal];
  [addTabButton setActionBlock:^(id sender) {
    // Duplicate current tab
    SingleTabController *singleTabController = [[SingleTabController alloc] init];
    singleTabController.artCodeTab = [ArtCodeTab duplicateTab:self.tabController.selectedViewController.artCodeTab];
    [self.tabController addChildViewController:singleTabController animated:YES];
  } forControlEvent:UIControlEventTouchUpInside];
  self.tabController.tabBar.additionalControls = [NSArray arrayWithObject:addTabButton];
  self.tabController.contentScrollView.accessibilityIdentifier = @"tabs scrollview";
  
  ////////////////////////////////////////////////////////////////////////////
  // Setup window
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = self.tabController;
  
  ////////////////////////////////////////////////////////////////////////////
  // Resume tabs
  for (ArtCodeTab *tab in [ArtCodeTab allTabs])
  {
    SingleTabController *singleTabController = [[SingleTabController alloc] init];
    singleTabController.artCodeTab = tab;
    [self.tabController addChildViewController:singleTabController];
  }
  [self.tabController setSelectedViewControllerIndex:[ArtCodeTab currentTabIndex]];
  [RACAbleSelf(tabController.selectedViewControllerIndex) subscribeNext:^(NSNumber *x) {
    [ArtCodeTab setCurrentTabIndex:x.unsignedIntegerValue];
  }];
//  [self.tabController setTabBarVisible:NO];
  
  // Start the application
  [self.window makeKeyAndVisible];
  
  // Open the file if needed
  if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey]) {
    return [self application:[UIApplication sharedApplication] openURL:[launchOptions objectForKey:UIApplicationLaunchOptionsURLKey] sourceApplication:[launchOptions objectForKey:UIApplicationLaunchOptionsSourceApplicationKey] annotation:[launchOptions objectForKey:UIApplicationLaunchOptionsAnnotationKey]];
  }
  
  return YES;
}

#import "NewProjectImportController.h"

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  NewProjectImportController *projectImportController = [[NewProjectImportController alloc] init];
  [projectImportController performSelector:@selector(_createProjectFromZipAtURL:) withObject:url];
  return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
  
}

- (void)applicationWillResignActive:(UIApplication *)application {
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  /*
   Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application {
  /*
   Called when the application is about to terminate.
   Save data if appropriate.
   See also applicationDidEnterBackground:.
   */
}

@end
