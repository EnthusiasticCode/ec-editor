//
//  ProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileBrowser.h"
@class FileMapController;
@class FileViewController;
@class ECCodeView;
@class ECCodeIndex;
@class Project;

@interface ProjectController : UIViewController <FileBrowser, FileBrowserDelegate>
@property (nonatomic, retain) IBOutlet FileMapController *fileMapController;
@property (nonatomic, retain) IBOutlet FileViewController *fileViewController;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) ECCodeIndex *codeIndex;

- (void)loadProject:(NSURL *)projectRoot;
- (void)loadFile:(NSURL *)file;
@end
