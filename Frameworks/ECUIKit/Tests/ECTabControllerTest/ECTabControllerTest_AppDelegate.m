//
//  ECTabControllerTest_AppDelegate.m
//  ECTabControllerTest
//
//  Created by Nicola Peduzzi on 29/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTabControllerTest_AppDelegate.h"

#import "ECGridViewController.h"

@implementation ECTabControllerTest_AppDelegate

@synthesize window = _window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    ECGridViewController *controller = [ECGridViewController new];
    
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
