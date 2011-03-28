//
//  AppController.m
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "ProjectBrowser.h"
#import "ProjectController.h"

@implementation AppController

@synthesize window = window_;
@synthesize contentView = contentView_;
@synthesize navigationBar = navigationBar_;
@synthesize projectBrowser = projectBrowser_;
@synthesize projectController = projectController_;

- (void)dealloc
{
    self.projectController = nil;
    self.projectBrowser = nil;
    self.navigationBar = nil;
    self.contentView = nil;
    self.window = nil;
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self browseProjects];
    [self.window makeKeyAndVisible];
    return YES;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
}

- (BOOL)browseProjects
{
    [self.projectBrowser browseFolder:[self applicationDocumentsDirectory]];
    [self.projectController.view removeFromSuperview];
    [self.contentView addSubview:self.projectBrowser.view];
    self.projectBrowser.view.frame = self.contentView.bounds;
    return YES;
}

- (void)fileBrowser:(id<FileBrowser>)fileBrowser didSelectFileAtPath:(NSURL *)path
{
    if (fileBrowser == self.projectBrowser)
        [self loadProject:path];
}

- (void)loadProject:(NSURL *)projectRoot
{
    [self.projectController browseFolder:projectRoot];
    [self.projectBrowser.view removeFromSuperview];
    [self.contentView addSubview:self.projectController.view];
    self.projectController.view.frame = self.contentView.bounds;
}

@end
