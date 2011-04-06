//
//  FileMap.m
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectViewController.h"
#import <ECFoundation/NSFileManager(ECAdditions).h>
#import <ECUIKit/ECRelationalTableView.h>

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
@synthesize tableView = tableView_;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)dealloc
{
    self.extensionsToShow = nil;
    self.tableView = nil;
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [self.tableView reloadData];
    [super viewDidLoad];
}


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
//    UILabel *label = [[UILabel alloc] init];
//    label.text = [[self filesInSubfolder:[self relationalTableView:nil titleForHeaderInArea:indexPath.area]] objectAtIndex:(indexPath.item)];
//    [file addSubview:label];
//    label.frame = file.bounds;
    file.backgroundColor = [UIColor redColor];
    return file;
}

- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfItemsAtLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    NSArray *links = [self filesInSubfolder:[self relationalTableView:nil titleForHeaderInArea:area]];
    return [links count];
}

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subfolder = [self relationalTableView:nil titleForHeaderInArea:indexPath.area];
    NSString *file = [[self filesInSubfolder:subfolder] objectAtIndex:indexPath.row];
    NSString *absoluteFilePath = [[self.folder stringByAppendingPathComponent:subfolder] stringByAppendingPathComponent:file];
    [self.delegate fileBrowser:self didSelectFileAtPath:absoluteFilePath];
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *subfolder = [self relationalTableView:nil titleForHeaderInArea:indexPath.area];
    NSString *file = [[self filesInSubfolder:subfolder] objectAtIndex:indexPath.row];
    NSString *absoluteFilePath = [[self.folder stringByAppendingPathComponent:subfolder] stringByAppendingPathComponent:file];
    return ([[absoluteFilePath pathExtension] isEqualToString:@"h"]) ? 0 : 1;
}

@end
