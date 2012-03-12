//
//  BrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchableTableBrowserController.h"
#import "SingleTabController.h"
#import "QuickBrowsersContainerController.h"
#import "ShapePopoverBackgroundView.h"
#import "NSTimer+BlockTimer.h"
#import "HighlightTableViewCell.h"
#import "UIImage+AppStyle.h"

#import "ArtCodeTab.h"
#import "ArtCodeURL.h"
#import "ACProject.h"


@implementation SearchableTableBrowserController {
    UIPopoverController *_quickBrowsersPopover;
    NSTimer *_filterDebounceTimer;
    BOOL _isSearchBarStaticOnTop;
}

#pragma mark - Properties

@synthesize tableView, searchBar, infoLabel, toolEditItems, toolNormalItems, bottomToolBar;

- (UISearchBar *)searchBar
{
    if (!searchBar)
    {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        searchBar.delegate = self;
        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return searchBar;
}

- (UITableView *)tableView
{
    if (!tableView)
    {
        CGRect bounds = self.view.bounds;
        if (_isSearchBarStaticOnTop)
        {
            bounds.origin.y = 44;
            bounds.size.height -= 44;
        }
        tableView = [[UITableView alloc] initWithFrame:bounds style:UITableViewStylePlain];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.backgroundColor = [UIColor colorWithWhite:0.91 alpha:1];
        tableView.separatorColor = [UIColor colorWithWhite:0.35 alpha:1];
        tableView.allowsMultipleSelectionDuringEditing = YES;
    }
    return tableView;
}

- (UILabel *)infoLabel
{
    if (!infoLabel)
    {
        infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 50)];
        infoLabel.textAlignment = UITextAlignmentCenter;
        infoLabel.backgroundColor = [UIColor clearColor];
        infoLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
        infoLabel.shadowColor = [UIColor whiteColor];
        infoLabel.shadowOffset = CGSizeMake(0, 1);
    }
    return infoLabel;
}

- (NSArray *)filteredItems
{
    return nil;
}

- (void)invalidateFilteredItems
{
}

#pragma mark - Controller lifecycle

- (id)initWithTitle:(NSString *)title searchBarStaticOnTop:(BOOL)isSearchBarStaticOnTop
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self)
        return nil;
    self.title = title;
    _isSearchBarStaticOnTop = isSearchBarStaticOnTop;
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [_quickBrowsersPopover dismissPopoverAnimated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self willChangeValueForKey:@"editing"];
    
    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];
    
    if (editing && [self.toolEditItems count])
    {
        self.toolbarItems = self.toolEditItems;
        for (UIBarButtonItem *item in self.toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:NO];
        }
    }
    else
    {
        self.toolbarItems = self.toolNormalItems;
    }
    
    [self didChangeValueForKey:@"editing"];
}

+ (BOOL)automaticallyNotifiesObserversOfEditing
{
    return NO;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    self.tableView.tableFooterView = self.infoLabel;
    if (_isSearchBarStaticOnTop)
    {
        [self.view addSubview:self.searchBar];
    }
    else
    {
        self.tableView.tableHeaderView = self.searchBar;
        self.tableView.contentOffset = CGPointMake(0, 45);
    }
    [self.view addSubview:self.tableView];
    
    self.editButtonItem.title = @"";
    self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.toolbarItems = self.toolNormalItems;
    
    // Adjust layout if bottomToolBar has been loaded
    if (self.bottomToolBar != nil)
    {
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.size.height -= self.bottomToolBar.bounds.size.height;
        self.tableView.frame = tableViewFrame;
        self.bottomToolBar.frame = CGRectMake(tableViewFrame.origin.x, CGRectGetMaxY(tableViewFrame), tableViewFrame.size.width, self.bottomToolBar.bounds.size.height);
        [self.view addSubview:self.bottomToolBar];
        
        // Select button
        NSInteger selectedTag = 0;
        if ([self.artCodeTab.currentURL isArtCodeProjectBookmarksList])
            selectedTag = 1;
        else if ([self.artCodeTab.currentURL isArtCodeProjectRemotesList])
            selectedTag = 2;
        for (UIView *subview in self.bottomToolBar.subviews)
        {
            if ([subview isKindOfClass:[BottomToolBarButton class]] 
                && [(BottomToolBarButton *)subview tag] == selectedTag)
                [(BottomToolBarButton *)subview setSelected:YES];
        }
    }
}

- (void)viewDidUnload
{
    tableView = nil;
    searchBar = nil;
    infoLabel = nil;
    toolEditItems = nil;
    toolNormalItems = nil;
    _quickBrowsersPopover = nil;
    
    _toolEditDeleteActionSheet = nil;
    _modalNavigationController = nil;
    
    [self setBottomToolBar:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self invalidateFilteredItems];
}

#pragma mark - Single tab content controller protocol methods

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar
{
    return self.artCodeTab.currentURL != nil;
}

- (void)singleTabController:(SingleTabController *)singleTabController titleControlAction:(id)sender
{
    QuickBrowsersContainerController *quickBrowserContainerController = [QuickBrowsersContainerController defaultQuickBrowsersContainerControllerForContentController:self];
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
        _filterDebounceTimer = nil;
        [self invalidateFilteredItems];
        [self.tableView reloadData];
        return;
    }
    
    // Apply filter to filterController with .3 second debounce
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        [self invalidateFilteredItems];
        [self.tableView reloadData];
    } repeats:NO];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [self.filteredItems count];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    HighlightTableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.backgroundColor = [UIColor clearColor];
    }
    
    // Override to configure cell
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing && [self.toolEditItems count])
    {
        BOOL anySelected = [table indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in self.toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
}

- (void)tableView:(UITableView *)table didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing && [self.toolEditItems count])
    {
        BOOL anySelected = [table indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in self.toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
}

#pragma mark - Common actions

- (void)toolEditDeleteAction:(id)sender
{
    if (!_toolEditDeleteActionSheet)
    {
        _toolEditDeleteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Delete permanently" otherButtonTitles:nil];
        _toolEditDeleteActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolEditDeleteActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (IBAction)toolPushUrlForTagAction:(id)sender
{
    switch ([sender tag]) {
        case 1:
            [self.artCodeTab pushURL:[ArtCodeURL artCodeURLWithProject:self.artCodeTab.currentProject item:nil path:artCodeURLProjectBookmarkListPath]];
            break;
            
        case 2:
            [self.artCodeTab pushURL:[ArtCodeURL artCodeURLWithProject:self.artCodeTab.currentProject item:nil path:artCodeURLProjectRemoteListPath]];
            break;
            
        default:
            [self.artCodeTab pushURL:[ArtCodeURL artCodeURLWithProject:self.artCodeTab.currentProject item:nil path:nil]];
            break;
    }
}

#pragma mark - Modal navigation

- (void)modalNavigationControllerPresentViewController:(UIViewController *)viewController completion:(void(^)())completion
{
    // Prepare left cancel button item
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(modalNavigationControllerDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    viewController.navigationItem.leftBarButtonItem = cancelItem;
    
    // Prepare new modal navigation controller and present it
    if (!_modalNavigationController)
    {
        _modalNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
        _modalNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:_modalNavigationController animated:YES completion:completion];
    }
    else
    {
        [_modalNavigationController pushViewController:viewController animated:YES];
        if (completion)
            completion();
    }
}

- (void)modalNavigationControllerPresentViewController:(UIViewController *)viewController
{
    [self modalNavigationControllerPresentViewController:viewController completion:nil];
}

- (void)modalNavigationControllerDismissAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        _modalNavigationController = nil;
    }];
}

@end

@implementation BottomToolBarButton

// Only used for appearance customization

@end
