//
//  AppController.m
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "RootController.h"

@implementation AppController

@synthesize window = window_;

- (void)dealloc
{
    self.window = nil;
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [(RootController *)self.topViewController browseFolder:[self applicationDocumentsDirectory]];
    [self.window makeKeyAndVisible];
    return YES;
}

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
