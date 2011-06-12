//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "FilesController.h"
#import "Project.h"
#import "Node.h"
#import "File.h"
#import "FileController.h"
#import "RootController.h"

static const NSString *DefaultIdentifier = @"Default";

static const NSString *FileSegueIdentifier = @"File";

@implementation FilesController

@synthesize rootController = _rootController;
@synthesize fileManager = _fileManager;
@synthesize project = _project;
@synthesize projectRoot = _projectRoot;
@synthesize tableView = _tableView;

- (NSFileManager *)fileManager
{
    if (!_fileManager)
        _fileManager = [[NSFileManager alloc] init];
    return _fileManager;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.project.rootNode.children count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(NSString *)DefaultIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:(NSString *)DefaultIdentifier];
    }
    cell.textLabel.text = [[self.project.rootNode.children objectAtIndex:indexPath.row] name];
    return cell;
}

#pragma mark -

- (void)loadProject:(NSString *)projectRoot
{
    NSString *bundle = [[projectRoot stringByAppendingPathComponent:[projectRoot lastPathComponent]] stringByAppendingPathExtension:@"ecproj"];
    self.project = [[Project alloc] initWithBundle:bundle];
    self.projectRoot = projectRoot;
    [self addAllNodesInProjectRoot];
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
            [subNodes setObject:[node addNodeWithName:subPath type:NodeTypeFolder] forKey:subPath];
        else
            [node addFileWithPath:[path stringByAppendingPathComponent:subPath]];
    }
    for (NSString *subPath in [subNodes allKeys])
        [self addNodesAtPath:[path stringByAppendingPathComponent:subPath] toNode:[subNodes objectForKey:subPath]];
}

- (void)addAllNodesInProjectRoot
{
    [self addNodesAtPath:self.projectRoot toNode:self.project.rootNode];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:(NSString *)FileSegueIdentifier])
    {
        [segue.destinationViewController loadFile:[[self.project.rootNode children] objectAtIndex:[self.tableView indexPathForSelectedRow].row]];
    }
    [self.rootController prepareForSegue:segue sender:sender];
}

@end
