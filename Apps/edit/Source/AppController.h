//
//  AppController.h
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileBrowserDelegate.h"
@class ProjectBrowser;
@class ProjectController;

@interface AppController : NSObject <UIApplicationDelegate, FileBrowserDelegate>
@property (nonatomic, retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet ProjectBrowser *projectBrowser;
@property (nonatomic, retain) IBOutlet ProjectController *projectController;
- (NSURL *)applicationDocumentsDirectory;
- (BOOL)browseProjects;
- (void)loadProject:(NSURL *)projectRoot;
@end
