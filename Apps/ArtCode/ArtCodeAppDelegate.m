//
//  ArtCodeAppDelegate.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import "ArtCodeAppDelegate.h"

#import "CodeView.h"

#import "AppStyle.h"

#import "SingleTabController.h"

#import "TabBar.h"
#import "TopBarToolbar.h"
#import "TopBarTitleControl.h"
#import "CodeFileSearchBarController.h"
#import "SearchableTableBrowserController.h"
#import "PopoverButton.h"
#import "NewProjectImportController.h"

#import "ArtCodeTabSet.h"
#import "ArtCodeTabPageViewController.h"

#import "ArtCodeDatastore.h"


@implementation ArtCodeAppDelegate {
  ArtCodeTabPageViewController *_tabPageController;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  UIFont *defaultFont = [UIFont styleFontWithSize:14];
  
  ////////////////////////////////////////////////////////////////////////////
  // Generic text field
  id textFieldAppearance = UITextField.appearance;
  [textFieldAppearance setTextColor:UIColor.styleForegroundColor];
  [(UITextField *)textFieldAppearance setFont:defaultFont];
  
  ////////////////////////////////////////////////////////////////////////////
  // Generic popover
  [ImagePopoverBackgroundView.appearance setBackgroundImage:[[UIImage imageNamed:@"popover_background"] resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)]];
  [ImagePopoverBackgroundView.appearance setBackgroundInsets:UIEdgeInsetsMake(-9, -9, -9, -9)];
  [ImagePopoverBackgroundView.appearance setUpArrowImage:[UIImage imageNamed:@"popover_arrow"]];
  [ImagePopoverBackgroundView.appearance setArrowInsets:UIEdgeInsetsMake(1, 1, 1, 1)];
  [ImagePopoverBackgroundView.appearance setArrowLimitsInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
  
  ////////////////////////////////////////////////////////////////////////////
  // Button in generic navigation controller
  [PopoverButton.appearance setBackgroundImage:[UIImage stylePopoverButtonBackgroundImage] forState:UIControlStateNormal];
  
  ////////////////////////////////////////////////////////////////////////////
  // UI Bars
  [UINavigationBar.appearance setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forBarMetrics:UIBarMetricsDefault];
  [UINavigationBar.appearance setTitleTextAttributes:@{UITextAttributeTextColor: UIColor.whiteColor, UITextAttributeTextShadowColor: UIColor.blackColor, UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)]}];
  
  [UIToolbar.appearance setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
  
  [UISearchBar.appearance setBackgroundImage:[UIImage imageNamed:@"topBar_Secondary_Background"]];
  
  [UIBarButtonItem.appearance setBackButtonBackgroundImage:[UIImage styleBackButtonBackgroundImage] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  [UIBarButtonItem.appearance setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateSelected] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  
  ////////////////////////////////////////////////////////////////////////////
  // Tab Bar    
  id buttonInTabBarAppearance = TabBarButton.appearance;
  [buttonInTabBarAppearance setBackgroundImage:[[UIImage imageNamed:@"tabBar_TabBackground_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateNormal];
  [buttonInTabBarAppearance setBackgroundImage:[[UIImage imageNamed:@"tabBar_TabBackground_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateSelected];
  [buttonInTabBarAppearance setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
  [buttonInTabBarAppearance setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
  [buttonInTabBarAppearance setTitleShadowColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateNormal];
  
  [TabBarButtonCloseButton.appearance setImage:[UIImage imageNamed:@"tabBar_TabCloseButton"] forState:UIControlStateNormal];
  
  ////////////////////////////////////////////////////////////////////////////
  // Top bar
  [TopBarToolbar.appearance setBackgroundImage:[UIImage imageNamed:@"topBar_Background"]];
  
  id TopBarTitleControlAppearance = TopBarTitleControl.appearance;
  [TopBarTitleControlAppearance setBackgroundImage:[[UIImage imageNamed:@"topBar_TitleButton_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateNormal];
  [TopBarTitleControlAppearance setBackgroundImage:[[UIImage imageNamed:@"topBar_TitleButton_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateSelected];
  [TopBarTitleControlAppearance setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forState:UIControlStateDisabled];
  [TopBarTitleControlAppearance setGapBetweenFragments:3];
  [TopBarTitleControlAppearance setContentInsets:UIEdgeInsetsMake(3, 10, 3, 10)];
  [TopBarTitleControlAppearance setSelectedTitleFragmentsTint:UIColor.whiteColor];
  [TopBarTitleControlAppearance setSecondaryTitleFragmentsTint:[UIColor colorWithWhite:0.7 alpha:1]];
  [TopBarTitleControlAppearance setSelectedFragmentFont:[UIFont boldSystemFontOfSize:20]];
  [TopBarTitleControlAppearance setSecondaryFragmentFont:[UIFont systemFontOfSize:14]];
  
  [TopBarToolButton.appearance setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal];
  [TopBarToolButton.appearance setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateSelected] forState:UIControlStateSelected];
  [[TopBarToolButton appearanceWhenContainedIn:CodeFileSearchBarView.class, nil] setBackgroundImage:[[UIImage imageNamed:@"searchBar_Button_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forState:UIControlStateNormal];
  
  ////////////////////////////////////////////////////////////////////////////
  // Browsers bottom tool bar
  [BottomToolBarButton.appearance setBackgroundImage:[[UIImage imageNamed:@"bottomToolBar_Button"] resizableImageWithCapInsets:UIEdgeInsetsMake(7, 7, 7, 7)] forState:UIControlStateNormal];
  
  ////////////////////////////////////////////////////////////////////////////
  // Code view elements
  [(CodeFlashView *)CodeFlashView.appearance setBackgroundColor:UIColor.yellowColor];
  
  // Setup data store
  [[ArtCodeDatastore defaultDatastore] setUp];
  
  ////////////////////////////////////////////////////////////////////////////
  // Creating main tab controllers
  _tabPageController = [[ArtCodeTabPageViewController alloc] init];
  _tabPageController.definesPresentationContext = YES;
  _tabPageController.artCodeTabSet = ArtCodeTabSet.defaultSet;
  
  ////////////////////////////////////////////////////////////////////////////
  // Setup window
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = _tabPageController;
  
  // Start the application
  [self.window makeKeyAndVisible];
  
  // Open the file if needed to account for open with...
  if (launchOptions[UIApplicationLaunchOptionsURLKey]) {
    return [self application:[UIApplication sharedApplication] openURL:launchOptions[UIApplicationLaunchOptionsURLKey] sourceApplication:launchOptions[UIApplicationLaunchOptionsSourceApplicationKey] annotation:launchOptions[UIApplicationLaunchOptionsAnnotationKey]];
  }
  
  return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  // Handles open with... by creating a new project from the opened file and opening a new tab with that project.
  // TODO: account for opening a non-archive type
  NewProjectImportController *projectImportController = [[NewProjectImportController alloc] init];
  [projectImportController createProjectFromZipAtURL:url completionHandler:^(RCIODirectory *projectDirectory) {
    if (projectDirectory) {
      [NSFileManager.defaultManager removeItemAtURL:url error:NULL];
#warning TODO: should set the location to point to the newly added project
      ArtCodeTab *tab = [ArtCodeTabSet.defaultSet addNewTabWithLocationType:ArtCodeLocationTypeDirectory remote:nil data:nil];
      [_tabPageController.tabBar setSelectedTabIndex:[tab.tabSet.tabs indexOfObject:tab]];
    }
  }];
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
  [ArtCodeDatastore.defaultDatastore tearDown];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
  [ArtCodeDatastore.defaultDatastore setUp];
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
