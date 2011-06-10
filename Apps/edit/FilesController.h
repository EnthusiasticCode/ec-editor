//
//  ProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Project, Node, File, RootController;

@interface FilesController : UITableViewController
@property (nonatomic, weak) RootController *rootController;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) NSString *projectRoot;
- (void)loadProject:(NSString *)projectRoot;
- (void)addNodesAtPath:(NSString *)path toNode:(Node *)node;
- (void)addAllNodesInProjectRoot;
@end
