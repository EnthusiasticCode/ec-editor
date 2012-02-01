//
//  NewProjectImportController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewProjectImportController.h"
#import "NewProjectNavigationController.h"

#import "ArtCodeProject.h"
#import "NSURL+Utilities.h"
#import "DirectoryPresenter.h"
#import "BezelAlert.h"
#import "NSString+PluralFormat.h"


@implementation NewProjectImportController {
    DirectoryPresenter *_documentsDirectoryPresenter;
}

#pragma mark - View Lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setEditing:YES animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    _documentsDirectoryPresenter = [[DirectoryPresenter alloc] initWithDirectoryURL:[NSURL applicationDocumentsDirectory] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    _documentsDirectoryPresenter = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_documentsDirectoryPresenter.fileURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [[_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row] lastPathComponent];
    
    return cell;
}

#pragma mark - Table view delegate

- (IBAction)importAction:(id)sender
{
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSFileManager *fileManager = [NSFileManager new];
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
    [indexPaths enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        NSURL *zipURL = [_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row];
        ArtCodeProject *project = [[ArtCodeProject alloc] initByDecompressingFileAtURL:zipURL toURL:[ArtCodeProject projectURLFromName:[ArtCodeProject validNameForNewProjectName:[[zipURL lastPathComponent] stringByDeletingPathExtension]]]];
        if (project)
        {
            [coordinator coordinateWritingItemAtURL:zipURL options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
                [fileManager removeItemAtURL:newURL error:NULL];
            }];
        }
    }];
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"Project imported" plural:@"%u projects imported" count:[indexPaths count]] image:nil displayImmediatly:YES];
}
@end
