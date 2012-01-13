//
//  ACNewProjectImportController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACNewProjectImportController.h"
#import "ACNewProjectNavigationController.h"
#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECFoundation/ECDirectoryPresenter.h>
#import <ECArchive/ECArchive.h>

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSURL *projectsDirectory = [(ACNewProjectNavigationController *)self.navigationController projectsDirectory];
    ECASSERT(projectsDirectory != nil);
    
    [ECArchive extractArchiveAtURL:[_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row] toDirectory:projectsDirectory];
}

@end
