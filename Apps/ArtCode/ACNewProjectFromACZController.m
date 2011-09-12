//
//  ACPopoverNewProjectFromACZController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNewProjectFromACZController.h"
#import "ECURL.h"
#import "ACNewProjectPopoverController.h"

@interface ACNewProjectFromACZController ()
{
    NSArray *_fileURLs;
}
@end

@implementation ACNewProjectFromACZController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    _fileURLs = [fileManager contentsOfDirectoryAtURL:[NSURL applicationDocumentsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants error:NULL];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [[[evaluatedObject pathExtension] lowercaseString] isEqualToString:@"acz"];
    }];
    _fileURLs = [_fileURLs filteredArrayUsingPredicate:predicate];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_fileURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    cell.textLabel.text = [[_fileURLs objectAtIndex:indexPath.row] lastPathComponent];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ECASSERT([(ACNewProjectPopoverController *)self.navigationController newProjectFromACZ]);
    [(ACNewProjectPopoverController *)self.navigationController newProjectFromACZ]([_fileURLs objectAtIndex:indexPath.row]);
}

@end
