//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectController.h"
#import "FileController.h"
#import "AppController.h"
#import "Project.h"
#import <ECCodeIndexing/ECCodeIndex.h>
#import <ECCodeIndexing/ECCodeUnit.h>
#import <ECFoundation/NSFileManager(ECAdditions).h>

@interface ProjectController ()
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSString *folder;
- (NSArray *)filesInSubfolder:(NSString *)subfolder;
@end

@implementation ProjectController

@synthesize extensionsToShow = extensionsToShow_;
@synthesize project = project_;
@synthesize codeIndex = codeIndex_;
@synthesize editButton = editButton_;
@synthesize doneButton = doneButton_;
@synthesize tableView = tableView_;
@synthesize fileManager = fileManager_;
@synthesize folder = folder_;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)dealloc
{
    self.folder = nil;
    self.fileManager = nil;
    self.tableView = nil;
    self.editButton = nil;
    self.doneButton = nil;
    self.extensionsToShow = nil;
    self.project = nil;
    self.codeIndex = nil;
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
    // Return YES for supported orientations
	return YES;
}

- (NSArray *)contentsOfFolder
{
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
    return [self.fileManager subpathsOfDirectoryAtPath:self.folder withExtensions:nil options:options skipFiles:YES skipDirectories:NO error:(NSError **)NULL];
}

- (NSArray *)filesInSubfolder:(NSString *)subfolder
{
    NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
    return [self.fileManager contentsOfDirectoryAtPath:[self.folder stringByAppendingPathComponent:subfolder] withExtensions:self.extensionsToShow options:options skipFiles:NO skipDirectories:YES error:(NSError **)NULL];
}

- (NSUInteger)numberOfAreasInTableView:(ECRelationalTableView *)relationalTableView
{
    return [[self contentsOfFolder] count];
}

- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForHeaderInArea:(NSUInteger)area
{
    return [[self contentsOfFolder] objectAtIndex:area];
}

- (ECRelationalTableViewCell *)relationalTableView:(ECRelationalTableView *)relationalTableView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ECRelationalTableViewCell *file = [self.tableView dequeueReusableCell];
    if (!file)
    {
        file = [[[ECRelationalTableViewCell alloc] init] autorelease];
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.tag = 1;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.frame = UIEdgeInsetsInsetRect(file.bounds, UIEdgeInsetsMake(2.0, 2.0, 2.0, 2.0));
        label.backgroundColor = [UIColor greenColor];
        [file addSubview:label];
    }
    ((UILabel *)[file viewWithTag:1]).text = [[self filesInSubfolder:[self relationalTableView:nil titleForHeaderInArea:indexPath.area]] objectAtIndex:(indexPath.item)];
    return file;
}

- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    NSArray *links = [self filesInSubfolder:[self relationalTableView:nil titleForHeaderInArea:area]];
    return [links count];
}

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    if (!indexPath)
        return;
    NSString *subfolder = [self relationalTableView:nil titleForHeaderInArea:indexPath.area];
    NSString *file = [[self filesInSubfolder:subfolder] objectAtIndex:indexPath.item];
    [self loadFile:[self.folder stringByAppendingPathComponent:[subfolder stringByAppendingPathComponent:file]]];
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
