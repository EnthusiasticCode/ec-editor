//
//  editAppDelegate.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "editAppDelegate.h"
#import "ECCarpetView.h"

@implementation editAppDelegate
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ECCarpetView * carpet = [[ECCarpetView alloc] initWithFrame:[window bounds]];
    [carpet addPanelWithName:@"MyPanel" size:0.3 position:-1];
    [window addSubview:carpet];
    return YES;
}

- (void)dealloc {
    [window release];
    [super dealloc];
}

@end
