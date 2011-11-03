//
//  ACNewProjectPopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNewProjectPopoverController.h"
#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECFoundation/ECDirectoryPresenter.h>
#import <ECArchive/ECArchive.h>

@interface ACNewProjectPopoverController ()
{
    ECDirectoryPresenter *_documentsDirectoryPresenter;
}
@end

@implementation ACNewProjectPopoverController

@synthesize projectsDirectory = _projectsDirectory;

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
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"New project from template";
    else if (section == 1)
        return @"Import project from archive";
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    else if (section == 1)
        return [_documentsDirectoryPresenter.fileURLs count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if (indexPath.section == 0)
        cell.textLabel.text = @"Blank project";
    else if (indexPath.section == 1)
        cell.textLabel.text = [[_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row] lastPathComponent];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        NSString *projectName = [@"Project " stringByAppendingString:[NSString stringWithFormat:@"%d", arc4random()]];
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [fileCoordinator coordinateWritingItemAtURL:[[self.projectsDirectory URLByAppendingPathComponent:projectName] URLByAppendingPathExtension:@"weakpkg"] options:0 error:NULL byAccessor:^(NSURL *newURL) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            [fileManager createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:NULL];
        }];
    }
    else if (indexPath.section == 1)
    {
        ECArchive *archive = [[ECArchive alloc] initWithFileURL:[_documentsDirectoryPresenter.fileURLs objectAtIndex:indexPath.row]];
        [archive extractToDirectory:self.projectsDirectory];
    }
}

@end