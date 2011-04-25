//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "ProjectController.h"
#import "FileController.h"
#import "AppController.h"
#import "Project.h"

@implementation ProjectController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize project = _project;
@synthesize editButton = _editButton;
@synthesize doneButton = _doneButton;
@synthesize tableView = _tableView;

- (void)dealloc
{
    self.tableView = nil;
    self.editButton = nil;
    self.doneButton = nil;
    self.project = nil;
    self.managedObjectContext = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButton;
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (NSUInteger)numberOfAreasInTableView:(ECItemView *)itemView
{
    return;
}

- (NSString *)itemView:(ECItemView *)itemView titleForHeaderInArea:(NSUInteger)area
{
    return [[self.files allKeys] objectAtIndex:area];
}

- (ECItemViewCell *)itemView:(ECItemView *)itemView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSUInteger counter = 0;
    ++counter;
    ECItemViewCell *file = [self.tableView dequeueReusableCell];
    if (!file)
    {
        file = [[[ECItemViewCell alloc] init] autorelease];
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.tag = 1;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.frame = UIEdgeInsetsInsetRect(file.bounds, UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0));
        label.backgroundColor = [UIColor greenColor];
        [file addSubview:label];
    }
    ((UILabel *)[file viewWithTag:1]).text = [[[self.files allValues] objectAtIndex:indexPath.area] objectAtIndex:indexPath.item];
    return file;
}

- (NSUInteger)itemView:(ECItemView *)itemView numberOfGroupsInArea:(NSUInteger)area
{
    return ([[[self.files allValues] objectAtIndex:area] count] > 0);
}

- (NSUInteger)itemView:(ECItemView *)itemView numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [[[self.files allValues] objectAtIndex:area] count];
}

- (void)itemView:(ECItemView *)itemView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    if (!indexPath)
        return;
    NSString *subfolder = [[self.files allKeys] objectAtIndex:indexPath.area];
    NSString *file = [[[self.files allValues] objectAtIndex:indexPath.area] objectAtIndex:indexPath.item];
    [self loadFile:[self.folder stringByAppendingPathComponent:[subfolder stringByAppendingPathComponent:file]]];
}

- (BOOL)itemView:(ECItemView *)itemView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)itemView:(ECItemView *)itemView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSString *file = [[[[self.files allValues] objectAtIndex:sourceIndexPath.area] objectAtIndex:sourceIndexPath.item] retain];
    [[[self.files allValues] objectAtIndex:sourceIndexPath.area] removeObjectAtIndex:sourceIndexPath.item];
    [[[self.files allValues] objectAtIndex:destinationIndexPath.area] insertObject:file atIndex:destinationIndexPath.item];
    [file release];
}

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
    self.folder = projectRoot;
    self.project = [Project projectWithRootDirectory:projectRoot];
    self.title = self.project.name;
    self.codeIndex = [[[ECCodeIndex alloc] init] autorelease];
    self.extensionsToShow = [[self.codeIndex extensionToLanguageMap] allKeys];
}

- (void)loadFile:(NSString *)file
{
    ECCodeUnit *codeUnit = [self.codeIndex unitForFile:file];
    FileController *fileController = ((AppController *)self.navigationController).fileController;
    [fileController loadFile:file withCodeUnit:codeUnit];
    [self.navigationController pushViewController:fileController animated:YES];
}

@end
