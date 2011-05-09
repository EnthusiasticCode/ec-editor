//
//  ProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Project;

@interface ProjectController : UITableViewController
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
- (IBAction)edit:(id)sender;
- (IBAction)done:(id)sender;
- (void)loadProject:(NSString *)projectRoot;
- (void)loadFile:(NSString *)file;
@end
