//
//  AppController.m
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "RootController.h"
#import "ProjectController.h"

@implementation AppController

@synthesize window = window_;
@synthesize rootController = rootController_;
@synthesize projectController = projectController_;
@synthesize fileController = fileController_;

- (void)dealloc
{
    self.rootController = nil;
    self.projectController = nil;
    self.fileController = nil;
    self.window = nil;
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self.rootController browseFolder:[self applicationDocumentsDirectory]];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.projectController saveContext];
}

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
