//
//  ACBookmarkTableController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACBookmarkTableController.h"
#import "ACSingleProjectBrowsersController.h"


@implementation ACBookmarkTableController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentOffset = CGPointMake(0, 45);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.singleProjectBrowsersController.project.bookmarks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // TODO configure cell better
    ACProjectBookmark *bookmark = [self.singleProjectBrowsersController.project.bookmarks objectAtIndex:indexPath.row];
    cell.textLabel.text = [bookmark.URL lastPathComponent];
    
    return cell;
}

#pragma mark - Table view delegate

@end
