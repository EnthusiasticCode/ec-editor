//
//  editAppDelegate.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "editAppDelegate.h"

@implementation editAppDelegate

@synthesize window, codeViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [window addSubview:codeViewController.view];
    [window makeKeyAndVisible];
    
    return YES;
}

- (void)dealloc
{
    [codeViewController release];
    [window release];
    [super dealloc];
}

@end
