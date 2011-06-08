//
//  ProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Project, Node, File;

@interface ProjectController : UITableViewController
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) NSString *projectRoot;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneButton;
- (IBAction)edit:(id)sender;
- (IBAction)done:(id)sender;
- (void)loadProject:(NSString *)projectRoot;
- (void)loadNode:(Node *)node;
- (void)loadFile:(File *)file;
- (void)addNodesAtPath:(NSString *)path toNode:(Node *)node;
- (void)addAllNodesInProjectRoot;
@end
