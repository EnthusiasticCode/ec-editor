//
//  ACNewProjectPopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNewProjectPopoverController.h"
#import "ACApplication.h"

@implementation ACNewProjectPopoverController

@synthesize projectsDirectory = _projectsDirectory;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = @"Blank project";
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *projectName = [@"Project " stringByAppendingString:[NSString stringWithFormat:@"%d", arc4random()]];
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:[[self.projectsDirectory URLByAppendingPathComponent:projectName] URLByAppendingPathExtension:@"weakpkg"] options:0 error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:NULL];
    }];
}

@end