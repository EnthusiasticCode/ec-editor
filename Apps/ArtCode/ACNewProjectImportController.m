//
//  ACNewProjectImportController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACNewProjectImportController.h"
#import "ACNewProjectNavigationController.h"

#import "ACProject.h"
#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECFoundation/ECDirectoryPresenter.h>
#import <ECUIKit/ECBezelAlert.h>


@implementation ACNewProjectImportController {
    ECDirectoryPresenter *_documentsDirectoryPresenter;
}

#pragma mark - View Lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    _documentsDirectoryPresenter = [[ECDirectoryPresenter alloc] init];
    _documentsDirectoryPresenter.directory = [NSURL applicationDocumentsDirectory];
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
    ECFileCoordinator *coordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    NSFileManager *fileManager = [NSFileManager new];
    NSArray *indexPaths = [self.tableView indexPathsForSelectedRows];
    [indexPaths enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSIndexPath *indexPath, NSUInteger idx, BOOL *stop) {
        NSURL *zipURL = [_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row];
        ACProject *project = [[ACProject alloc] initByDecompressingFileAtURL:zipURL toURL:[ACProject projectURLFromName:[ACProject validNameForNewProjectName:[[zipURL lastPathComponent] stringByDeletingPathExtension]]]];
        if (project)
        {
            [coordinator coordinateWritingItemAtURL:zipURL options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
                [fileManager removeItemAtURL:newURL error:NULL];
            }];
        }
    }];
    [[(ACNewProjectNavigationController *)self.navigationController popoverController] dismissPopoverAnimated:YES];
    [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:([indexPaths count] == 1 ? @"Project imported" : [NSString stringWithFormat:@"%u projects imported", [indexPaths count]]) image:nil displayImmediatly:YES];
}
@end
