//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileController.h"
#import "ProjectController.h"
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

@synthesize project = project_;
@synthesize codeIndex = codeIndex_;
@synthesize fileManager = fileManager_;
@synthesize folder = folder_;
@synthesize extensionsToShow = extensionsToShow_;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)dealloc
{
    self.folder = nil;
    self.fileManager = nil;
    self.extensionsToShow = nil;
    self.project = nil;
    self.codeIndex = nil;
    [super dealloc];
}
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}*/
/*
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
*/

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
 }
 */

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/
/*
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
*/
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
    ECRelationalTableViewCell *file = [[[ECRelationalTableViewCell alloc] init] autorelease];
    UILabel *label = [[[UILabel alloc] init] autorelease];
    label.text = [[self filesInSubfolder:[self relationalTableView:nil titleForHeaderInArea:indexPath.area]] objectAtIndex:(indexPath.item)];
    [file addSubview:label];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    label.frame = file.bounds;
    label.backgroundColor = [UIColor redColor];
    return file;
}

- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfItemsAtLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    NSArray *links = [self filesInSubfolder:[self relationalTableView:nil titleForHeaderInArea:area]];
    return [links count];
}

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    NSString *subfolder = [self relationalTableView:nil titleForHeaderInArea:indexPath.area];
    NSString *file = [[self filesInSubfolder:subfolder] objectAtIndex:indexPath.item];
    [self loadFile:[self.folder stringByAppendingPathComponent:[subfolder stringByAppendingPathComponent:file]]];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subfolder = [self relationalTableView:nil titleForHeaderInArea:indexPath.area];
    NSString *file = [[self filesInSubfolder:subfolder] objectAtIndex:indexPath.row];
    NSString *absoluteFilePath = [[self.folder stringByAppendingPathComponent:subfolder] stringByAppendingPathComponent:file];
    return ([[absoluteFilePath pathExtension] isEqualToString:@"h"]) ? 0 : 1;
}

- (void)loadProject:(NSString *)projectRoot
{
    self.folder = projectRoot;
    self.project = [Project projectWithRootDirectory:projectRoot];
    self.codeIndex = [[[ECCodeIndex alloc] init] autorelease];
    self.extensionsToShow = [[self.codeIndex extensionToLanguageMap] allKeys];
}

- (void)loadFile:(NSString *)file
{
    ECCodeUnit *codeUnit = [self.codeIndex unitForFile:file];
    FileController *fileController = [[[FileController alloc] initWithNibName:@"FileController" bundle:[NSBundle mainBundle]] autorelease];
    [fileController loadFile:file withCodeUnit:codeUnit];
    [self.navigationController pushViewController:fileController animated:YES];
}

@end
