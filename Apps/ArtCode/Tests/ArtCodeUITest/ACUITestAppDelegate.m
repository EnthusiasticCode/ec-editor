//
//  ACUITestAppDelegate.m
//  ArtCodeUITest
//
//  Created by Nicola Peduzzi on 16/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACUITestAppDelegate.h"

#import "ACTopBarController.h"

#import <ECUIKit/ECTabController.h>
#import <ECUIKit/ECTabBar.h>

#import "ACTopBarToolbar.h"
#import "ACTopBarTitleControl.h"



@implementation ACUITestAppDelegate

@synthesize window = _window;
@synthesize topBarController = _topBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Top bar
    [[ACTopBarToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearanceWhenContainedIn:[ACTopBarToolbar class], nil] setBackgroundImage:[[UIImage imageNamed:@"topBar_NormalButton_Default"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    // Top bar Title control
    [[ACTopBarTitleControl appearance] setBackgroundImage:[[UIImage imageNamed:@"topBar_TitleButton_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateNormal];
    [[ACTopBarTitleControl appearance] setBackgroundImage:[[UIImage imageNamed:@"topBar_TitleButton_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateSelected];
    // Tab bar
    [[ECTabBarButton appearance] setBackgroundImage:[[UIImage imageNamed:@"tabBar_TabBackground"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 0, 10)] forState:UIControlStateNormal];
    [[ECTabBarButtonCloseButton appearance] setImage:[UIImage imageNamed:@"tabBar_TabCloseButton"] forState:UIControlStateNormal];
//    [[UILabel appearanceWhenContainedIn:[ECTabBarButton class], nil] setFont:[UIFont systemFontOfSize:10]];
    
    // Bottom ui tab bar
    [[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:@"UITabBar_Background"]];
    
    //
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    self.topBarController = [[ACTopBarController alloc] initWithNibName:@"ACUITestViewController" bundle:nil];
    self.topBarController.title = @"Tab title";
    
    ECTabController *tabController = [[ECTabController alloc] init];
    tabController.tabBar.tabControlInsets = UIEdgeInsetsMake(2, 3, 0, 3);
    
    self.window.rootViewController = tabController;
    [tabController addChildViewController:self.topBarController];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
