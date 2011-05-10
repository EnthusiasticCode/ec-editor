//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ProjectController.h"
#import "GroupController.h"
#import "Project.h"
#import "Node.h"
#import "FileController.h"
#import "AppController.h"

@implementation ProjectController

@synthesize fileManager = _fileManager;
@synthesize project = _project;
@synthesize projectRoot = _projectRoot;
@synthesize editButton = _editButton;
@synthesize doneButton = _doneButton;
@synthesize tableView = _tableView;

- (NSFileManager *)fileManager
{
    if (!_fileManager)
        _fileManager = [[NSFileManager alloc] init];
    return _fileManager;
}

- (void)dealloc
{
    self.fileManager = nil;
    self.editButton = nil;
    self.doneButton = nil;
    self.project = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButton;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.project nodesInProjectRoot] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
    }
    cell.textLabel.text = [[[self.project nodesInProjectRoot] objectAtIndex:indexPath.row] name];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self loadNode:[[self.project nodesInProjectRoot] objectAtIndex:indexPath.row]];
}

#pragma mark -

- (void)edit:(id)sender
{
    [self.tableView setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)done:(id)sender
{
    [self.tableView setEditing:NO animated:YES];
    self.navigationItem.rightBarButtonItem = self.editButton;
}

- (void)loadProject:(NSString *)projectRoot
{
    NSString *bundle = [[projectRoot stringByAppendingPathComponent:[projectRoot lastPathComponent]] stringByAppendingPathExtension:@"ecproj"];
    self.project = [[[Project alloc] initWithBundle:bundle] autorelease];
    self.title = self.project.name;
    self.projectRoot = projectRoot;
    [self addAllNodesInProjectRoot];
}

- (void)loadNode:(Node *)node
{
    if (![node.type isEqualToString:@"Group"])
        [self loadFile:[(File *)node path]];
    else
    {
        GroupController *groupController = [[[GroupController alloc] init] autorelease];
        groupController.group = node;
        [self.navigationController pushViewController:groupController animated:YES];
    }
}

- (void)loadFile:(NSString *)file
{
    FileController *fileController = ((AppController *)self.navigationController).fileController;
    [fileController loadFile:file];
    [self.navigationController pushViewController:fileController animated:YES];
}

- (void)addNodesAtPath:(NSString *)path toNode:(Node *)node
{
    NSArray *subPaths = [self.fileManager contentsOfDirectoryAtPath:path error:NULL];
    NSMutableDictionary *subNodes = [NSMutableDictionary dictionaryWithCapacity:[subPaths count]];
    for (NSString *subPath in subPaths)
    {
        BOOL isDirectory;
        [self.fileManager fileExistsAtPath:[path stringByAppendingPathComponent:subPath] isDirectory:&isDirectory];
        if (isDirectory)
            [subNodes setObject:[node addNodeWithName:subPath type:@"Group"] forKey:subPath];
        else
            [node addFileWithPath:[path stringByAppendingPathComponent:subPath]];
    }
    for (NSString *subPath in [subNodes allKeys])
        [self addNodesAtPath:[path stringByAppendingPathComponent:subPath] toNode:[subNodes objectForKey:subPath]];
}

- (void)addAllNodesInProjectRoot
{
    NSArray *paths = [self.fileManager contentsOfDirectoryAtPath:self.projectRoot error:NULL];
    NSMutableDictionary *nodes = [NSMutableDictionary dictionaryWithCapacity:[paths count]];
    for (NSString *path in paths)
    {
        BOOL isDirectory;
        [self.fileManager fileExistsAtPath:[self.projectRoot stringByAppendingPathComponent:path] isDirectory:&isDirectory];
        if (isDirectory)
            [nodes setObject:[self.project addNodeWithName:path type:@"Group"] forKey:path];
        else
            [self.project addFileWithPath:[self.projectRoot stringByAppendingPathComponent:path]];
    }
    for (NSString *path in [nodes allKeys])
        [self addNodesAtPath:[self.projectRoot stringByAppendingPathComponent:path] toNode:[nodes objectForKey:path]];
}

@end
