//
//  ArtCodeAppDelegate.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ArtCodeAppDelegate.h"

#import "AppStyle.h"
#import "ACNavigationController.h"
#import "ACTopBarView.h"
#import "ACToolPanelController.h"
#import "ECTabBar.h"
#import "ECJumpBar.h"
#import "ACToolFiltersView.h"

#import "ACProjectTableController.h"
#import "ACFileTableController.h"

#import "ACState.h"

@implementation ArtCodeAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[ACState sharedState] loadState];
    ACNavigationController *navigationController = (ACNavigationController *)self.window.rootViewController;
    UIFont *defaultFont = [UIFont styleFontWithSize:14];
    
    ////////////////////////////////////////////////////////////////////////////
    // Generic text field
    id textFieldAppearance = [UITextField appearance];
    [textFieldAppearance setTextColor:[UIColor styleForegroundColor]];
    [textFieldAppearance setFont:defaultFont];
    
    ////////////////////////////////////////////////////////////////////////////
    // Button in top bar
    id buttonInTopBarAppearance = [UIButton appearanceWhenContainedIn:[ACTopBarView class], nil];
    [buttonInTopBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor]] forState:UIControlStateNormal];
    [buttonInTopBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleHighlightColor] borderColor:[UIColor styleForegroundColor]] forState:UIControlStateHighlighted];
    [buttonInTopBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleThemeColorOne] borderColor:[UIColor styleForegroundColor]] forState:UIControlStateSelected];
    [buttonInTopBarAppearance setTitleColor:[UIColor styleForegroundColor] forState:UIControlStateNormal];
    [buttonInTopBarAppearance setTitleShadowColor:[UIColor styleForegroundShadowColor] forState:UIControlStateNormal];
    
    ////////////////////////////////////////////////////////////////////////////
    // Jump bar
    id jumpBarAppearance = [ECJumpBar appearance];
    [jumpBarAppearance setJumpElementMargins:UIEdgeInsetsMake(0, -3, 0, -12)];
    [jumpBarAppearance setTextElementInsets:UIEdgeInsetsMake(0, 3, 0, 7)];
    
    id buttonInJumpBarAppearance = [UIButton appearanceWhenContainedIn:[ECJumpBar class], [ACTopBarView class], nil];
    [buttonInJumpBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsZero arrowSize:CGSizeMake(10, 30) roundingCorners:UIRectCornerAllCorners] forState:UIControlStateNormal];
    [buttonInJumpBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleHighlightColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsZero arrowSize:CGSizeMake(10, 30) roundingCorners:UIRectCornerAllCorners] forState:UIControlStateHighlighted];

    ////////////////////////////////////////////////////////////////////////////
    // Tab button
    id buttonInTabBarAppearance = [UIButton appearanceWhenContainedIn:[ECTabBar class], nil];
    [buttonInTabBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleForegroundColor] borderColor:[UIColor styleBackgroundColor]] forState:UIControlStateNormal];
    [buttonInTabBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor colorWithWhite:0.25 alpha:1] borderColor:[UIColor styleBackgroundColor]] forState:UIControlStateHighlighted];
    [buttonInTabBarAppearance setBackgroundImage:[UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleBackgroundColor]] forState:UIControlStateSelected];
    [buttonInTabBarAppearance setTitleColor:[UIColor styleBackgroundColor] forState:UIControlStateNormal];
    [buttonInTabBarAppearance setTitleColor:[UIColor styleForegroundColor] forState:UIControlStateSelected];
    
    ////////////////////////////////////////////////////////////////////////////
    // Close button of tabs
    id closeButtonInTabBarAppearance = [UIButton appearanceWhenContainedIn:[UIButton class], [ECTabBar class], nil];
    [closeButtonInTabBarAppearance setBackgroundImage:nil forState:UIControlStateNormal];
    [closeButtonInTabBarAppearance setBackgroundImage:nil forState:UIControlStateHighlighted];
    [closeButtonInTabBarAppearance setImage:[UIImage styleCloseImageWithColor:[UIColor styleBackgroundColor] outlineColor:[UIColor styleForegroundColor]] forState:UIControlStateNormal];
    [closeButtonInTabBarAppearance setImage:[UIImage styleCloseImageWithColor:[UIColor styleForegroundColor] outlineColor:[UIColor styleBackgroundColor]] forState:UIControlStateHighlighted];
    
    ////////////////////////////////////////////////////////////////////////////
    // Adding tool panel
    UIStoryboard *toolPanelsStoryboard = [UIStoryboard storyboardWithName:@"ToolPanelStoryboard" bundle:[NSBundle mainBundle]];
    ACToolPanelController *toolPanelController = [toolPanelsStoryboard instantiateInitialViewController];
    [toolPanelController addToolWithController:[toolPanelsStoryboard instantiateViewControllerWithIdentifier:@"HistoryTool"]
                                      tabImage:[UIImage imageNamed:@"toolPanelHistoryIcon.png"] 
                              selectedTabImage:[UIImage imageNamed:@"toolPanelHistoryActiveIcon.png"]];
    [toolPanelController addToolWithController:[toolPanelsStoryboard instantiateViewControllerWithIdentifier:@"BookmarksTool"]
                                      tabImage:[UIImage imageNamed:@"toolPanelStarIcon.png"] 
                              selectedTabImage:[UIImage imageNamed:@"toolPanelStarActiveIcon.png"]];
    [toolPanelController addToolWithController:[toolPanelsStoryboard instantiateViewControllerWithIdentifier:@"SnippetsTool"]
                                      tabImage:[UIImage imageNamed:@"toolPanelSnippetsIcon.png"] 
                              selectedTabImage:[UIImage imageNamed:@"toolPanelSnippetsActiveIcon.png"]];
    [toolPanelController addToolWithController:[toolPanelsStoryboard instantiateViewControllerWithIdentifier:@"SymbolsTool"]
                                      tabImage:[UIImage imageNamed:@"toolPanelSymbolsIcon.png"] 
                              selectedTabImage:[UIImage imageNamed:@"toolPanelSymbolsActiveIcon.png"]];
    [toolPanelController addToolWithController:[toolPanelsStoryboard instantiateViewControllerWithIdentifier:@"NavigatorTool"]
                                      tabImage:[UIImage imageNamed:@"toolPanelNavigatorIcon.png"] 
                              selectedTabImage:[UIImage imageNamed:@"toolPanelNavigatorActiveIcon.png"]];
    //
    navigationController.toolPanelController = toolPanelController;
    navigationController.toolPanelOnRight = YES;
    
    ////////////////////////////////////////////////////////////////////////////
    // Tools
    UIImage *toolFilterElementBackgorundImage = [UIImage styleBackgroundImageWithColor:[UIColor styleForegroundColor] borderColor:[UIColor styleBackgroundColor] insets:UIEdgeInsetsMake(7, 7, 7, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners];
    id buttonInToolFiltersView = [UIButton appearanceWhenContainedIn:[ACToolFiltersView class], nil];
    [buttonInToolFiltersView setBackgroundImage:toolFilterElementBackgorundImage forState:UIControlStateNormal];
    
    id textFieldInToolFiltersView = [UITextField appearanceWhenContainedIn:[ACToolFiltersView class], nil];
    [textFieldInToolFiltersView setTextColor:[UIColor styleBackgroundColor]];
    [textFieldInToolFiltersView setBackground:toolFilterElementBackgorundImage];
    
    ////////////////////////////////////////////////////////////////////////////
    [window makeKeyAndVisible];
    navigationController.delegate = self;
    [navigationController.tabController addTabWithURL:[NSURL URLWithString:@"artcode:projects"] title:@"Projects" animated:NO];
    [navigationController.tabController addTabWithURL:[NSURL URLWithString:@"artcode:files"] title:@"Projects" animated:NO];
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
    [[ACState sharedState] saveState];
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

#pragma mark - Navigation Controller Delegate Methods

- (UIViewController<ACToolTarget> *)navigationController:(ACNavigationController *)navigationController viewControllerForURL:(NSURL *)url previousViewController:(UIViewController<ACToolTarget> *)previousViewController
{
    Class controllerClass = nil;
    // TODO url switch logic
    if ([url.absoluteString isEqualToString:@"artcode:projects"])
        controllerClass = [ACProjectTableController class];
    else
        controllerClass = [ACFileTableController class];
    
    if ([previousViewController isKindOfClass:controllerClass])
        return previousViewController;
    else
        return [[controllerClass alloc] init]; // TODO initWithNibName:name of class
}

@end
