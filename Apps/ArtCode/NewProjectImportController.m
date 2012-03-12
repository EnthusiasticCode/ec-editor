//
//  NewProjectImportController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewProjectImportController.h"

#import "ACProject.h"

#import "NSURL+Utilities.h"
#import "UIViewController+Utilities.h"
#import "NSString+PluralFormat.h"
#import "DirectoryPresenter.h"
#import "BezelAlert.h"


static void *_directoryObservingContext;

@implementation NewProjectImportController {
    DirectoryPresenter *_documentsDirectoryPresenter;
}

#pragma mark - View Lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.tableView.userInteractionEnabled = YES;
    [self stopRightBarButtonItemActivityIndicator];
    
    _documentsDirectoryPresenter = [[DirectoryPresenter alloc] initWithDirectoryURL:[NSURL applicationDocumentsDirectory] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    [_documentsDirectoryPresenter addObserver:self forKeyPath:@"fileURLs" options:0 context:&_directoryObservingContext];
    if ([_documentsDirectoryPresenter.fileURLs count] != 0)
        [(UILabel *)self.tableView.tableFooterView setText:@"Swipe right on an item to delete it."];
    
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [_documentsDirectoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&_directoryObservingContext];
    _documentsDirectoryPresenter = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &_directoryObservingContext)
    {
        if ([_documentsDirectoryPresenter.fileURLs count] != 0)
            [(UILabel *)self.tableView.tableFooterView setText:@"Swipe right on an item to delete it."];
        else
            [(UILabel *)self.tableView.tableFooterView setText:@"Add files from iTunes to populate this list."];
        [self.tableView reloadData];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [[_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row] lastPathComponent];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:[_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row] options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
            [[NSFileManager new] removeItemAtURL:newURL error:NULL];
        }];
    }
}

#pragma mark - Table view delegate

- (void)_createProjectFromZipAtURL:(NSURL *)zipURL attempt:(NSInteger)attemptNumber
{
    NSString *zipFileName = [[zipURL lastPathComponent] stringByDeletingPathExtension];
    if (attemptNumber > 0)
        zipFileName = [zipFileName stringByAppendingFormat:@" (%d)", attemptNumber];
    
    [self startRightBarButtonItemActivityIndicator];
    self.tableView.userInteractionEnabled = NO;
    [ACProject createProjectWithName:zipFileName importArchiveURL:zipURL completionHandler:^(ACProject *createdProject) {
        if (createdProject)
        {
            [createdProject closeWithCompletionHandler:^(BOOL success) {
                [self stopRightBarButtonItemActivityIndicator];
                self.tableView.userInteractionEnabled = YES;
                
                [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
                [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Project imported" imageNamed:BezelAlertOkIcon displayImmediatly:YES];
            }];
        }
        else
        {
#warning FIX!!! this point is never reached, create for saving doesn't apparently check for existance
            [self _createProjectFromZipAtURL:zipURL attempt:attemptNumber + 1];
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self _createProjectFromZipAtURL:[_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row] attempt:0];
}

@end
