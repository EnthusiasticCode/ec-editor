//
//  AppController.m
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import "RootViewController.h"
#import "ProjectController.h"

@implementation AppController

@synthesize window = window_;
@synthesize contentView = contentView_;
@synthesize toolbar = toolbar_;
@synthesize browseRootToolbarButton = browseRootToolbarButton_;
@synthesize rootToolbarTitle = rootToolbarTitle_;
@synthesize browseProjectToolbarButton = browseProjectToolbarButton_;
@synthesize projectToolbarTitle = projectToolbarTitle_;
@synthesize fileToolbarTitle = fileToolbarTitle_;
@synthesize rootViewController = rootViewController_;
@synthesize projectController = projectController_;

- (void)dealloc
{
    self.projectController = nil;
    self.rootViewController = nil;
    self.fileToolbarTitle = nil;
    self.projectToolbarTitle = nil;
    self.browseProjectToolbarButton = nil;
    self.rootToolbarTitle = nil;
    self.browseRootToolbarButton = nil;
    self.toolbar = nil;
    self.contentView = nil;
    self.window = nil;
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self browseRoot:self];
    [self.window makeKeyAndVisible];
    return YES;
}

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)setupToolbarWithFarLeftButton:(UIBarButtonItem *)farLeftButton leftButton:(UIBarButtonItem *)leftButton centerLabel:(UIBarButtonItem *)centerLabel rightButton:(UIBarButtonItem *)rightButton farRightButton:(UIBarButtonItem *)farRightButton
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:7];
    UIBarButtonItem *flexibleSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
    if (farLeftButton)
        [items addObject:farLeftButton];
    if (leftButton)
        [items addObject:leftButton];
    [items addObject:flexibleSpace];
    if (centerLabel)
        [items addObject:centerLabel];
    [items addObject:flexibleSpace];
    if (rightButton)
        [items addObject:rightButton];
    if (farLeftButton)
        [items addObject:farLeftButton];
    [self.toolbar setItems:items animated:YES];
}

- (IBAction)browseRoot:(id)sender
{
    [self.rootViewController browseFolder:[self applicationDocumentsDirectory]];
    [self setupToolbarWithFarLeftButton:nil leftButton:nil centerLabel:self.rootToolbarTitle rightButton:nil farRightButton:nil];
    [self.projectController.view removeFromSuperview];
    [self.contentView addSubview:self.rootViewController.view];
    self.rootViewController.view.frame = self.contentView.bounds;
}

- (void)fileBrowser:(id<FileBrowser>)fileBrowser didSelectFileAtPath:(NSString *)path
{
    if (fileBrowser == self.rootViewController)
    {
        [self loadProject:path];
    }
    if (fileBrowser == self.projectController)
    {
        [self loadFile:path];
    }
}

- (void)loadProject:(NSString *)projectRoot
{
    [self.projectController browseFolder:projectRoot];
    self.projectToolbarTitle.title = [projectRoot lastPathComponent];
    self.browseProjectToolbarButton.title = [projectRoot lastPathComponent];
    [self setupToolbarWithFarLeftButton:self.browseRootToolbarButton leftButton:nil centerLabel:self.projectToolbarTitle rightButton:nil farRightButton:nil];
    [self.rootViewController.view removeFromSuperview];
    [self.contentView addSubview:self.projectController.view];
    self.projectController.view.frame = self.contentView.bounds;
}

- (IBAction)browseProject:(id)sender
{
    [self loadProject:self.projectController.folder];
}

- (void)loadFile:(NSString *)file
{
    [self.projectController loadFile:file];
    self.fileToolbarTitle.title = [file lastPathComponent];
    [self setupToolbarWithFarLeftButton:self.browseProjectToolbarButton leftButton:nil centerLabel:self.fileToolbarTitle rightButton:nil farRightButton:nil];
}

@end
