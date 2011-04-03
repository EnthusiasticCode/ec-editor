//
//  AppController.h
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileBrowserDelegate.h"
@class RootViewController;
@class ProjectController;

@interface AppController : NSObject <UIApplicationDelegate, FileBrowserDelegate, UINavigationBarDelegate>
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *browseRootToolbarButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *rootToolbarTitle;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *browseProjectToolbarButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *projectToolbarTitle;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *fileToolbarTitle;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
@property (nonatomic, retain) IBOutlet ProjectController *projectController;
- (IBAction)browseProject:(id)sender;
- (IBAction)browseRoot:(id)sender;
- (NSString *)applicationDocumentsDirectory;
- (void)setupToolbarWithFarLeftButton:(UIBarButtonItem *)farLeftButton leftButton:(UIBarButtonItem *)leftButton centerLabel:(UIBarButtonItem *)centerLabel rightButton:(UIBarButtonItem *)rightButton farRightButton:(UIBarButtonItem *)farRightButton;
- (void)loadProject:(NSString *)projectRoot;
- (void)loadFile:(NSString *)file;
@end
