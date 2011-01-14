//
//  editAppDelegate.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "editAppDelegate.h"
#import "OUIEditableFrame.h"

@implementation editAppDelegate


@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [window makeKeyAndVisible];
    return YES;
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end
