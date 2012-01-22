//
//  ACBookmarkTableController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACBookmarkTableController.h"
#import "ACSingleProjectBrowsersController.h"

#import "ACProject.h"

@interface ACBookmarkTableController ()

- (void)_toolEditDeleteAction:(id)sender;

@end


@implementation ACBookmarkTableController {
    NSArray *_toolEditItems;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    _toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDeleteAction:)], nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentOffset = CGPointMake(0, 45);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing)
    {
        self.toolbarItems = _toolEditItems;
    }
    else
    {
        self.toolbarItems = nil;
    }
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
    
    NSUInteger bookmarkLine = [bookmark line];
    if (bookmarkLine != 0)
    {
        NSInteger fragmentLocation = [bookmark.bookmarkPath rangeOfString:@"#"].location;
        if (fragmentLocation != NSNotFound)
        {
            cell.textLabel.text = [[bookmark.bookmarkPath substringToIndex:fragmentLocation] stringByAppendingFormat:@" - Line: %u", bookmarkLine];
        }
        else
        {
            cell.textLabel.text = [bookmark.bookmarkPath stringByAppendingFormat:@" - Line: %u", bookmarkLine];
        }
    }
    else
    {
        cell.textLabel.text = bookmark.bookmarkPath;
    }
    
    return cell;
}

#pragma mark - Table view delegate

#pragma mark - Private methods

- (void)_toolEditDeleteAction:(id)sender
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
        return;
    
    for (NSIndexPath *indexPath in [selectedRows reverseObjectEnumerator])
    {
        [self.singleProjectBrowsersController.project removeBookmark:[self.singleProjectBrowsersController.project.bookmarks objectAtIndex:indexPath.row]];
    }
    [self.tableView deleteRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.singleProjectBrowsersController setEditing:NO animated:YES];
}

@end
