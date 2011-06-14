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
    return [[self.project children] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(NSString *)DefaultIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:(NSString *)DefaultIdentifier];
    }
    cell.textLabel.text = [[[self.project children] objectAtIndex:indexPath.row] name];
    return cell;
}

#pragma mark -

- (void)loadProject:(NSString *)projectRoot
{
    NSString *bundle = [[projectRoot stringByAppendingPathComponent:[projectRoot lastPathComponent]] stringByAppendingPathExtension:@"ecproj"];
    self.project = [[Project alloc] initWithBundle:bundle];
    self.projectRoot = projectRoot;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:(NSString *)FileSegueIdentifier])
    {
        [segue.destinationViewController loadFile:[[self.project children] objectAtIndex:[self.tableView indexPathForSelectedRow].row]];
    }
    [self.rootController prepareForSegue:segue sender:sender];
}

@end
