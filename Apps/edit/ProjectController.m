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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self contentsOfFolder] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self contentsOfFolder] objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *file = [tableView dequeueReusableCellWithIdentifier:@"File"];
    if (!file)
    {
        file = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"File"] autorelease];
        UILabel *label = [[[UILabel alloc] init] autorelease];
        label.tag = 1;
        [file.contentView addSubview:label];
        label.frame = file.contentView.bounds;
    }
    UILabel *label = (UILabel *)[file.contentView viewWithTag:1];
    label.text = [[self filesInSubfolder:[self tableView:nil titleForHeaderInSection:indexPath.section]] objectAtIndex:(indexPath.row)];
    return file;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *links = [self filesInSubfolder:[self tableView:nil titleForHeaderInSection:section]];
    return [links count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath)
        return;
    NSString *subfolder = [self tableView:nil titleForHeaderInSection:indexPath.section];
    NSString *file = [[self filesInSubfolder:subfolder] objectAtIndex:indexPath.row];
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
