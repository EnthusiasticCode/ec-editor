//
//  FileMap.m
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectViewController.h"

@interface ProjectViewController ()
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSString *folder;
- (NSArray *)filesInSubfolder:(NSString *)subfolder;
@end

@implementation ProjectViewController

@synthesize delegate = delegate_;
@synthesize fileManager = fileManager_;
@synthesize folder = folder_;

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
    NSMutableArray *subfolders = [NSMutableArray array];
    NSEnumerator *links = [self.fileManager enumeratorAtPath:self.folder];
    BOOL isDirectory;
    NSString *oldWorkingDirectory = [self.fileManager currentDirectoryPath];
    [self.fileManager changeCurrentDirectoryPath:self.folder];
    for (NSString *link in links)
    {
        if(![self.fileManager fileExistsAtPath:link isDirectory:&isDirectory])
            continue;
        if(isDirectory)
            [subfolders addObject:link];
    }
    [self.fileManager changeCurrentDirectoryPath:oldWorkingDirectory];
    return subfolders;
}

- (void)browseFolder:(NSString *)folder
{
    self.folder = folder;
}

- (NSArray *)filesInSubfolder:(NSString *)subfolder
{
    NSMutableArray *files = [NSMutableArray array];
    NSString *subfolderAbsolutePath = [self.folder stringByAppendingPathComponent:subfolder];
    NSArray *links = [self.fileManager contentsOfDirectoryAtPath:subfolderAbsolutePath error:NULL];
    BOOL isDirectory;
    NSString *oldWorkingDirectory = [self.fileManager currentDirectoryPath];
    [self.fileManager changeCurrentDirectoryPath:subfolderAbsolutePath];
    for (NSString *link in links)
    {
        if(![self.fileManager fileExistsAtPath:link isDirectory:&isDirectory])
            continue;
        if(!isDirectory)
            [files addObject:link];
    }
    [self.fileManager changeCurrentDirectoryPath:oldWorkingDirectory];
    return files;
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
    }
    file.textLabel.text = [[self filesInSubfolder:[self tableView:nil titleForHeaderInSection:indexPath.section]] objectAtIndex:(indexPath.row)];
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

@end
