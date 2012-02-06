//
//  BookmarkBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkBrowserController.h"
#import "SingleTabController.h"
#import "QuickBrowsersContainerController.h"

#import "NSTimer+BlockTimer.h"
#import "NSArray+ScoreForAbbreviation.h"

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"

#import "BezelAlert.h"
#import "NSString+PluralFormat.h"


@interface BookmarkBrowserController (/*Private methods*/)

- (void)_toolEditDeleteAction:(id)sender;

@end


@implementation BookmarkBrowserController {
@protected
    NSArray *_toolEditItems;
    UIActionSheet *_toolEditItemDeleteActionSheet;
    
    UISearchBar *_searchBar;
    UILabel *_infoLabel;
    NSTimer *_filterDebounceTimer;
    
    NSArray *_sortedBookmarks;
    NSArray *_sortedBookmarksHitMasks;
    
    UIPopoverController *_quickBrowsersPopover;
}

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self)
        return nil;
    self.title = @"Bookmarks";
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
        tableView.allowsMultipleSelectionDuringEditing = YES;
    }
    return tableView;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    CGRect bounds = self.view.bounds;
    
    // Tool edit items
    self.editButtonItem.title = @"";
    self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
    _toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDeleteAction:)], nil];
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self isMemberOfClass:[BookmarkBrowserController class]])
    {
        [_searchBar removeFromSuperview];
        self.tableView.frame = self.view.bounds;
        self.tableView.tableHeaderView = _searchBar;
        self.tableView.contentOffset = CGPointMake(0, 45);
    }
}

- (void)viewDidUnload
{
    _toolEditItems = nil;
    
    _searchBar = nil;
    _infoLabel = nil;
    tableView = nil;
    
    _quickBrowsersPopover = nil;
    
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
    [self.tableView setEditing:editing animated:animated];
    
    if (editing)
    {
        self.toolbarItems = _toolEditItems;
        for (UIBarButtonItem *item in _toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:NO];
        }
    }
    else
    {  
        self.toolbarItems = nil;
    }
    
    [self didChangeValueForKey:@"editing"];
}

#pragma mark - Single tab content controller protocol methods

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar
{
    return YES;
}

- (void)singleTabController:(SingleTabController *)singleTabController titleControlAction:(id)sender
{
    // TODO the quick browser container controller gets created every time, is it ok?
    QuickBrowsersContainerController *quickBrowserContainerController = [QuickBrowsersContainerController defaultQuickBrowsersContainerControllerForTab:self.artCodeTab];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:quickBrowserContainerController];
    [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    if (!_quickBrowsersPopover)
    {
        _quickBrowsersPopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        _quickBrowsersPopover.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
    }
    else
    {
        [_quickBrowsersPopover setContentViewController:navigationController animated:NO];
    }
    quickBrowserContainerController.presentingPopoverController = _quickBrowsersPopover;
    quickBrowserContainerController.openingButton = sender;
    [_quickBrowsersPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - UISeachBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [_filterDebounceTimer invalidate];
    
    if ([searchText length] == 0)
    {
        _sortedBookmarks = [self.artCodeTab.currentProject.bookmarks sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj1 description] compare:[obj2 description]];
        }];
        _sortedBookmarksHitMasks = nil;
        [self.tableView reloadData];
        _infoLabel.text = [_sortedBookmarks count] ? nil : [NSString stringWithFormat:@"%@ has no bookmarks.", self.artCodeTab.currentProject.name];
        return;
    }
    
    // Apply filter to filterController with .3 second debounce
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        NSArray *hitMasks = nil;
        _sortedBookmarks = [self.artCodeTab.currentProject.bookmarks sortedArrayUsingScoreForAbbreviation:searchText resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(ProjectBookmark *bookmark) {
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
    if (!self.isEditing)
    {
        [self.artCodeTab pushURL:[[_sortedBookmarks objectAtIndex:indexPath.row] URL]];
    }
    else
    {
        BOOL anySelected = [table indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in _toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
}

- (void)tableView:(UITableView *)table didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
    {
        BOOL anySelected = [table indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in _toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == _toolEditItemDeleteActionSheet)
    {
        if (buttonIndex == actionSheet.destructiveButtonIndex)
        {
            self.loading = YES;
            NSArray *selectedRows = self.tableView.indexPathsForSelectedRows;
            [self setEditing:NO animated:YES];
            for (NSIndexPath *indexPath in selectedRows)
            {
                [self.artCodeTab.currentProject removeBookmark:[_sortedBookmarks objectAtIndex:indexPath.row]];
            }
            self.loading = NO;
            [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"Bookmark deleted" plural:@"%u bookmarks deleted" count:[selectedRows count]] image:nil displayImmediatly:YES];
            [self searchBar:_searchBar textDidChange:_searchBar.text];
        }
    }
}

#pragma mark - Private methods

- (void)_toolEditDeleteAction:(id)sender
{
    if (!_toolEditItemDeleteActionSheet)
    {
        _toolEditItemDeleteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Delete permanently" otherButtonTitles:nil];
        _toolEditItemDeleteActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolEditItemDeleteActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

@end
