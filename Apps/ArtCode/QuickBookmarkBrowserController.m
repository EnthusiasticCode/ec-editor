//
//  QuickBookmarkBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 25/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickBookmarkBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import "NSTimer+BlockTimer.h"
#import "NSArray+ScoreForAbbreviation.h"

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"

@implementation QuickBookmarkBrowserController {
    UISearchBar *_searchBar;
    UILabel *_infoLabel;
    NSTimer *_filterDebounceTimer;
    
    NSArray *_sortedBookmarks;
    NSArray *_sortedBookmarksHitMasks;
}

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self)
        return nil;
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Bookmarks" image:nil tag:0];
    self.navigationItem.title = @"Bookmarks";
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

#pragma mark - Properties

@synthesize tableView;

- (UITableView *)tableView
{
    if (!tableView)
    {
        tableView = [UITableView new];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.backgroundColor = [UIColor colorWithWhite:0.91 alpha:1];
        tableView.separatorColor = [UIColor colorWithWhite:0.35 alpha:1];
    }
    return tableView;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    CGRect bounds = self.view.bounds;
    
    // Add search bar
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, 44)];
    _searchBar.delegate = self;
    _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _searchBar.placeholder = @"Search for bookmark";
    [self.view addSubview:_searchBar];
    [self searchBar:_searchBar textDidChange:nil];
    
    // Add table view
    [self.view addSubview:self.tableView];
    self.tableView.frame = CGRectMake(0, 44, bounds.size.width, bounds.size.height - 44);
    
    // Add table view footer view
    _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 50)];
    _infoLabel.textAlignment = UITextAlignmentCenter;
    _infoLabel.backgroundColor = [UIColor clearColor];
    _infoLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    _infoLabel.shadowColor = [UIColor whiteColor];
    _infoLabel.shadowOffset = CGSizeMake(0, 1);
    self.tableView.tableFooterView = _infoLabel;
    if ([_sortedBookmarks count] == 0)
        _infoLabel.text = @"The project has no bookmarks.";
}


- (void)viewDidUnload
{
    _infoLabel = nil;
    tableView = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - UISeachBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [_filterDebounceTimer invalidate];
    
    if ([searchText length] == 0)
    {
        _sortedBookmarks = [self.artCodeTab.currentURL.project.bookmarks sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj1 description] compare:[obj2 description]];
        }];
        _sortedBookmarksHitMasks = nil;
        [self.tableView reloadData];
        _infoLabel.text = [_sortedBookmarks count] ? nil : [NSString stringWithFormat:@"%@ has no bookmarks.", self.artCodeTab.currentURL.project.name];
        return;
    }
    
    // Apply filter to filterController with .3 second debounce
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        NSArray *hitMasks = nil;
        _sortedBookmarks = [self.artCodeTab.currentURL.project.bookmarks sortedArrayUsingScoreForAbbreviation:searchText resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(ProjectBookmark *bookmark) {
            return [bookmark description];
        }];
        _sortedBookmarksHitMasks = hitMasks;
        [self.tableView reloadData];
        _infoLabel.text = [_sortedBookmarks count] ? nil : @"No results matching the search string.";
    } repeats:NO];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [_sortedBookmarks count];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    HighlightTableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabelHighlightedCharactersBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
    }
    
    ProjectBookmark *bookmark = [_sortedBookmarks objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [bookmark description];
    cell.textLabelHighlightedCharacters = _sortedBookmarksHitMasks ? [_sortedBookmarksHitMasks objectAtIndex:indexPath.row] : nil;
    cell.detailTextLabel.text = bookmark.note;
    cell.imageView.image = [UIImage imageNamed:@"bookmarkTable_Icon"];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.quickBrowsersContainerController.popoverController dismissPopoverAnimated:YES];
    [self.artCodeTab pushURL:[[_sortedBookmarks objectAtIndex:indexPath.row] URL]];
}

@end
