//
//  FileMap.m
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectViewController.h"
#import <ECFoundation/NSFileManager(ECAdditions).h>

@interface ProjectViewController ()
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSString *folder;
- (NSArray *)filesInSubfolder:(NSString *)subfolder;
@end

@implementation ProjectViewController

@synthesize delegate = delegate_;
@synthesize fileManager = fileManager_;
@synthesize folder = folder_;
@synthesize extensionsToShow = extensionsToShow_;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.extensionsToShow = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

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

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (void)browseFolder:(NSString *)folder
{
    self.folder = folder;
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
    NSString *subfolder = [self tableView:nil titleForHeaderInSection:indexPath.section];
    NSString *file = [[self filesInSubfolder:subfolder] objectAtIndex:indexPath.row];
    NSString *absoluteFilePath = [[self.folder stringByAppendingPathComponent:subfolder] stringByAppendingPathComponent:file];
    [self.delegate fileBrowser:self didSelectFileAtPath:absoluteFilePath];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subfolder = [self tableView:nil titleForHeaderInSection:indexPath.section];
    NSString *file = [[self filesInSubfolder:subfolder] objectAtIndex:indexPath.row];
    NSString *absoluteFilePath = [[self.folder stringByAppendingPathComponent:subfolder] stringByAppendingPathComponent:file];
    return ([[absoluteFilePath pathExtension] isEqualToString:@"h"]) ? 0 : 1;
}

@end
