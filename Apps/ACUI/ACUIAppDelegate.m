//
//  ACUIAppDelegate.m
//  ACUI
//
//  Created by Nicola Peduzzi on 09/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACUIAppDelegate.h"
#import "AppStyle.h"
#import "ACNavigationController.h"
#import "ECTabBar.h"
#import "ECJumpBar.h"

@implementation ACUIAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIFont *defaultFont = [UIFont styleFontWithSize:14];
    
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
    
    ACNavigationController *navigationController = (ACNavigationController *)self.window.rootViewController;
    [navigationController performSegueWithIdentifier:@"rootSegue" sender:nil];
    
    // Generic button
    id buttonAppearance = [UIButton appearance];
    [buttonAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor]] forState:UIControlStateNormal];
    [buttonAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleHighlightColor] borderColor:[UIColor styleForegroundColor]] forState:UIControlStateHighlighted];
    [buttonAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleThemeColorOne] borderColor:[UIColor styleForegroundColor]] forState:UIControlStateSelected];
    
    // Generic text field
//    id textFieldAppearance = [UITextField appearance];
    
    // Button inside tabbar
    id buttonInTabBarAppearance = [UIButton appearanceWhenContainedIn:[ECTabBar class], nil];
    [buttonInTabBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleForegroundColor] borderColor:[UIColor styleBackgroundColor]] forState:UIControlStateNormal];
    [buttonInTabBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor colorWithWhite:0.25 alpha:1] borderColor:[UIColor styleBackgroundColor]] forState:UIControlStateHighlighted];
    [buttonInTabBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleBackgroundColor]] forState:UIControlStateSelected];
    [buttonInTabBarAppearance setTitleColor:[UIColor styleBackgroundColor] forState:UIControlStateNormal];
    [buttonInTabBarAppearance setTitleColor:[UIColor styleForegroundColor] forState:UIControlStateSelected];
    
    // Close button of tabs
    id closeButtonInTabBarAppearance = [UIButton appearanceWhenContainedIn:[UIButton class], [ECTabBar class], nil];
    [closeButtonInTabBarAppearance setBackgroundImage:nil forState:UIControlStateNormal];
    [closeButtonInTabBarAppearance setBackgroundImage:nil forState:UIControlStateHighlighted];
    [closeButtonInTabBarAppearance setImage:[UIImage styleCloseImageWithColor:[UIColor styleBackgroundColor] outlineColor:[UIColor styleForegroundColor]] forState:UIControlStateNormal];
    [closeButtonInTabBarAppearance setImage:[UIImage styleCloseImageWithColor:[UIColor styleForegroundColor] outlineColor:[UIColor styleBackgroundColor]] forState:UIControlStateHighlighted];
    
    // Jump bar
    id jumpBarAppearance = [ECJumpBar appearance];
    [jumpBarAppearance setJumpElementMargins:UIEdgeInsetsMake(0, -3, 0, -12)];
    
    id buttonInJumpBarAppearance = [UIButton appearanceWhenContainedIn:[ECJumpBar class], nil];
    [buttonInJumpBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsZero arrowSize:CGSizeMake(10, 30) roundingCorners:UIRectCornerAllCorners] forState:UIControlStateNormal];
    
    // TODO should be in the controller
    UIButton *backButton = [UIButton new];
    [backButton setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsZero arrowSize:CGSizeZero roundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft] forState:UIControlStateNormal];
    [backButton setImage:[UIImage styleDisclosureArrowImageWithOrientation:UIImageOrientationLeft color:[UIColor styleForegroundColor]] forState:UIControlStateNormal];
    backButton.frame = CGRectMake(0, 0, 40, 30);
    navigationController.jumpBar.backElement = backButton;
    
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
