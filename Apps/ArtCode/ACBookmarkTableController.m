//
//  ACBookmarkTableController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACBookmarkTableController.h"

#import "ACTab.h"
#import "ACProject.h"

@interface ACBookmarkTableController ()

- (void)_toolEditDeleteAction:(id)sender;

@end


@implementation ACBookmarkTableController {
    NSArray *_toolEditItems;
}

@synthesize tab;

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    // Add search bar
    if (!self.tableView.tableHeaderView)
    {
        UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        searchBar.delegate = self;
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.tableView.tableHeaderView = searchBar;
    }
    
    _toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDeleteAction:)], nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentOffset = CGPointMake(0, 45);
}

- (void)viewDidUnload
{
    _toolEditItems = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self willChangeValueForKey:@"editing"];
    
    [super setEditing:editing animated:animated];
    
    if (editing)
    {
        self.toolbarItems = _toolEditItems;
    }
    else
    {
        self.toolbarItems = nil;
    }
    
    [self didChangeValueForKey:@"editing"];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tab.currentProject.bookmarks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // TODO configure cell better
    ACProjectBookmark *bookmark = [self.tab.currentProject.bookmarks objectAtIndex:indexPath.row];
    
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
    cell.detailTextLabel.text = bookmark.note;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isEditing)
    {
        [self.tab pushURL:[[self.tab.currentProject.bookmarks objectAtIndex:indexPath.row] URL]];
    }
}

#pragma mark - Private methods

- (void)_toolEditDeleteAction:(id)sender
{
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    if ([selectedRows count] == 0)
        return;
    
    for (NSIndexPath *indexPath in [selectedRows reverseObjectEnumerator])
    {
        [self.tab.currentProject removeBookmark:[self.tab.currentProject.bookmarks objectAtIndex:indexPath.row]];
    }
    [self.tableView deleteRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationAutomatic];
    [self setEditing:NO animated:YES];
}

@end
