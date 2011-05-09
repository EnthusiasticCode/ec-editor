//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <ECUIKit/ECItemViewElement.h>
#import "ProjectController.h"
#import "Project.h"
#import "FileController.h"
#import "AppController.h"
#import "File.h"

@implementation ProjectController

@synthesize project = _project;
@synthesize editButton = _editButton;
@synthesize doneButton = _doneButton;
@synthesize tableView = _tableView;

- (void)dealloc
{
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

- (void)itemView:(ECItemView *)itemView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self loadFile:[[[self.project nodesInProjectRoot] objectAtIndex:indexPath.row] path]];
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
}

- (void)loadFile:(NSString *)file
{
    FileController *fileController = ((AppController *)self.navigationController).fileController;
    [fileController loadFile:file];
    [self.navigationController pushViewController:fileController animated:YES];
}

@end
