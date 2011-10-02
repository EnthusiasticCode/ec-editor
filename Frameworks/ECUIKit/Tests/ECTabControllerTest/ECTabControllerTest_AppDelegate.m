//
//  ECTabControllerTest_AppDelegate.m
//  ECTabControllerTest
//
//  Created by Nicola Peduzzi on 29/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTabControllerTest_AppDelegate.h"



@implementation ECTabControllerTest_AppDelegate

@synthesize window = _window;
@synthesize tabController = _tabController;

- (void)removeSelectedTabAction:(id)sender
{
    [self.tabController removeChildViewControllerAtIndex:self.tabController.selectedViewControllerIndex animated:YES];
}

- (void)addTabAction:(id)sender
{
    NSUInteger tabId = [self.tabController.childViewControllers count];
    
    UIViewController *tabTwo = [UIViewController new];
    tabTwo.view.backgroundColor = [UIColor whiteColor];
    tabTwo.navigationItem.title = [NSString stringWithFormat:@"Tab %u", tabId];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:[NSString stringWithFormat:@"Close tab %u", tabId] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(removeSelectedTabAction:) forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(20, 20, 100, 44)];
    [tabTwo.view addSubview:button];
    
    [self.tabController addChildViewController:tabTwo];
}

- (void)toggleTabBarAction:(id)sender
{
    [self.tabController setShowTabBar:!self.tabController.showTabBar animated:YES];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.tabController = [[ECTabController alloc] init];
    self.tabController.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    UIViewController *tabOne = [UIViewController new];
    tabOne.view.backgroundColor = [UIColor whiteColor];
    tabOne.navigationItem.title = @"Main";
    
    UIButton *addTabButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [addTabButton setTitle:@"Add tab" forState:UIControlStateNormal];
    [addTabButton addTarget:self action:@selector(addTabAction:) forControlEvents:UIControlEventTouchUpInside];
    [addTabButton setFrame:CGRectMake(20, 20, 100, 44)];
    [tabOne.view addSubview:addTabButton];
    
    UIButton *toggleTabBarButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [toggleTabBarButton setTitle:@"Toggle tab bar" forState:UIControlStateNormal];
    [toggleTabBarButton addTarget:self action:@selector(toggleTabBarAction:) forControlEvents:UIControlEventTouchUpInside];
    [toggleTabBarButton setFrame:CGRectMake(140, 20, 100, 44)];
    [tabOne.view addSubview:toggleTabBarButton];
    
    [self.tabController addChildViewController:tabOne];    
    [self addTabAction:nil];
    
    self.tabController.tabPageMargin = 20;
    
    self.window.rootViewController = self.tabController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
