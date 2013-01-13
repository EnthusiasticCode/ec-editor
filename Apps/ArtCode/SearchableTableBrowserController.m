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
#import "ImagePopoverBackgroundView.h"
#import "NSTimer+BlockTimer.h"
#import "HighlightTableViewCell.h"
#import "UIImage+AppStyle.h"

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"

#import "NSNotificationCenter+RACSupport.h"

@interface SearchableTableBrowserController ()

@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UILabel *infoLabel;

@property (nonatomic) BOOL isSearchBarStaticOnTop;

@property (nonatomic, strong) UIPopoverController *quickBrowsersPopover;
@property (nonatomic, strong) UIActionSheet *toolEditDeleteActionSheet;

@end

@implementation SearchableTableBrowserController {
  RACDisposable *_racGlobalDisposable;
}

#pragma mark - Properties

@synthesize searchBarTextSubject = _searchBarTextSubject;

- (RACSubject *)searchBarTextSubject {
  if (!_searchBarTextSubject) {
    _searchBarTextSubject = [RACReplaySubject replaySubjectWithCapacity:1];
    [_searchBarTextSubject sendNext:self.searchBar.text];
  }
  return _searchBarTextSubject;
}

- (void)invalidateFilteredItems {
}

#pragma mark - Controller lifecycle

- (id)initWithNibNamed:(NSString *)nibName title:(NSString *)title searchBarStaticOnTop:(BOOL)isSearchBarStaticOnTop
{
  self = [super initWithNibName:nibName bundle:nil];
  if (!self)
    return nil;
  
  self.title = title;
  self.isSearchBarStaticOnTop = isSearchBarStaticOnTop;
      
  return self;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.quickBrowsersPopover dismissPopoverAnimated:YES];
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

- (void)didReceiveMemoryWarning {
	[self invalidateFilteredItems];
  [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
	
	// Table View
	CGRect bounds = self.view.bounds;
	if (self.isSearchBarStaticOnTop) {
		bounds.origin.y = 44;
		bounds.size.height -= 44;
	}
	UITableView *tableView = [[UITableView alloc] initWithFrame:bounds style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	tableView.backgroundColor = [UIColor colorWithWhite:0.91 alpha:1];
	tableView.separatorColor = [UIColor colorWithWhite:0.35 alpha:1];
	tableView.allowsMultipleSelectionDuringEditing = YES;
	self.tableView = tableView;
	[self.view addSubview:self.tableView];
  [self.tableView setEditing:self.editing animated:NO];
  
	// Info Label
	UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 50)];
	infoLabel.textAlignment = NSTextAlignmentCenter;
	infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
	infoLabel.numberOfLines = 0;
	infoLabel.backgroundColor = [UIColor clearColor];
	infoLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
	infoLabel.shadowColor = [UIColor whiteColor];
	infoLabel.shadowOffset = CGSizeMake(0, 1);
	self.infoLabel = infoLabel;
  self.tableView.tableFooterView = self.infoLabel;
	
	// Search bar
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
	searchBar.delegate = self;
	searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.searchBar = searchBar;
  if (self.isSearchBarStaticOnTop)
  {
    [self.view addSubview:self.searchBar];
  }
  else
  {
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.contentOffset = CGPointMake(0, 45);
  }
  
  self.editButtonItem.title = @"";
  self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
  
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
    if (self.artCodeTab.currentLocation.type == ArtCodeLocationTypeBookmarksList)
      selectedTag = 1;
    else if (self.artCodeTab.currentLocation.type == ArtCodeLocationTypeRemotesList)
      selectedTag = 2;
    for (UIView *subview in self.bottomToolBar.subviews)
    {
      if ([subview isKindOfClass:[BottomToolBarButton class]] 
          && [(BottomToolBarButton *)subview tag] == selectedTag)
        [(BottomToolBarButton *)subview setSelected:YES];
    }
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // RAC
  __weak SearchableTableBrowserController *this = self;
  NSMutableArray *disposables = [NSMutableArray array];
  _racGlobalDisposable = [RACDisposable disposableWithBlock:^{
    for (RACDisposable *d in disposables) {
      [d dispose];
    }
  }];
  
  // Invalidate the table data when the search bar text changes
  [disposables addObject:[[[self.searchBarTextSubject throttle:0.3] distinctUntilChanged] subscribeNext:^(id x) {
    [this invalidateFilteredItems];
  }]];
  
  // Reload the table when the table data changes
  [disposables addObject:[RACAble(self.filteredItems) subscribeNext:^(NSArray *items) {
    [this.tableView reloadData];
  }]];
  
  // TODO: this property is not the correct one to use for enabling the keyboard resize, there should be a dedicated one
  if (!self.isSearchBarStaticOnTop) {
    // Account for keyboard and resize table accordingly
    [disposables addObject:[[RACSignal merge:@[[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardDidShowNotification object:nil], [[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillHideNotification object:nil]]] subscribeNext:^(NSNotification *note) {
      CGPoint tableViewOffset = this.tableView.contentOffset;
      SearchableTableBrowserController *strongSelf = this;
      if (note.name == UIKeyboardDidShowNotification) {
        CGRect tableViewFrame = this.tableView.frame;
        tableViewFrame.size.height = [this.view convertRect:[[note userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil].origin.y - tableViewFrame.origin.y;
        this.tableView.frame = tableViewFrame;
      } else {
        CGRect tableViewFrame = this.view.bounds;
        // Re-calculate frame based of search bar position
        if (strongSelf && strongSelf.isSearchBarStaticOnTop) {
          tableViewFrame.origin.y = 44;
          tableViewFrame.size.height -= 44;
        }
        // Account for bottom bar
        if (this.bottomToolBar != nil) {
          tableViewFrame.size.height -= this.bottomToolBar.bounds.size.height;
        }
        // Resize table view
        this.tableView.frame = tableViewFrame;
      }
      // Account for search bar glitch
      if (strongSelf && !strongSelf.isSearchBarStaticOnTop && tableViewOffset.y < 45) {
        [this.tableView setContentOffset:tableViewOffset animated:NO];
      }
    }]];
  }
  
  self.toolbarItems = self.toolNormalItems;
  [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
  [_racGlobalDisposable dispose];
  _racGlobalDisposable = nil;
  [self invalidateFilteredItems];
  [super viewDidDisappear:animated];
}

#pragma mark - Single tab content controller protocol methods

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar
{
  return self.artCodeTab.currentLocation != nil;
}

- (void)singleTabController:(SingleTabController *)singleTabController titleControlAction:(id)sender
{
  QuickBrowsersContainerController *quickBrowserContainerController = [QuickBrowsersContainerController defaultQuickBrowsersContainerControllerForContentController:self];
  UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:quickBrowserContainerController];
  [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
  if (!self.quickBrowsersPopover)
  {
    self.quickBrowsersPopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
    self.quickBrowsersPopover.popoverBackgroundViewClass = [ImagePopoverBackgroundView class];
  }
  else
  {
    [self.quickBrowsersPopover setContentViewController:navigationController animated:NO];
  }
  quickBrowserContainerController.presentingPopoverController = self.quickBrowsersPopover;
  quickBrowserContainerController.openingButton = sender;
  [self.quickBrowsersPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - UISeachBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
  [self.searchBarTextSubject sendNext:searchText];
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
  if (!self.toolEditDeleteActionSheet)
  {
    self.toolEditDeleteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Delete permanently" otherButtonTitles:nil];
    self.toolEditDeleteActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [self.toolEditDeleteActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (BOOL)isToolEditDeleteActionSheet:(UIActionSheet *)actionSheet {
	return self.toolEditDeleteActionSheet != nil && actionSheet == self.toolEditDeleteActionSheet;
}

- (IBAction)toolPushUrlForTagAction:(id)sender
{
  switch ([sender tag]) {
    case 1:
      [self.artCodeTab pushBookmarksListForProject:self.artCodeTab.currentLocation.project];
      break;
      
    case 2:
      [self.artCodeTab pushRemotesListForProject:self.artCodeTab.currentLocation.project];
      break;
      
    default:
      [self.artCodeTab pushProject:self.artCodeTab.currentLocation.project];
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
  if (!self.modalNavigationController)
  {
    self.modalNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.modalNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:_modalNavigationController animated:YES completion:completion];
  }
  else
  {
    [self.modalNavigationController pushViewController:viewController animated:YES];
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
    self.modalNavigationController = nil;
  }];
}

@end

@implementation BottomToolBarButton

// Only used for appearance customization

@end
