//
//  ACQuickFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACQuickFileBrowserController.h"
#import "ACQuickBrowsersContainerController.h"

#import <ECFoundation/NSTimer+block.h>

#import "ACTab.h"
#import "ACProject.h"

#import "AppStyle.h"
#import "ACHighlightTableViewCell.h"


@interface ACQuickFileBrowserController ()

@property (nonatomic, strong, readonly) ECSmartFilteredDirectoryPresenter *directoryPresenter;

- (void)_showBrowserInTabAction:(id)sender;

@end


@implementation ACQuickFileBrowserController {
    UISearchBar *_searchBar;
    UILabel *_infoLabel;
    NSTimer *_filterDebounceTimer;
}

#pragma mark - Properties

@synthesize directoryPresenter, tableView;

- (ECDirectoryPresenter *)directoryPresenter
{
    if (!directoryPresenter)
    {
        directoryPresenter = [[ECSmartFilteredDirectoryPresenter alloc] initWithDirectoryURL:self.quickBrowsersContainerController.tab.currentProject.URL options:NSDirectoryEnumerationSkipsHiddenFiles];
        directoryPresenter.delegate = self;
    }
    return directoryPresenter;
}

- (UITableView *)tableView
{
    if (!tableView)
    {
        tableView = [UITableView new];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return tableView;
}

#pragma mark - Controller lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Files" image:nil tag:0];
    self.navigationItem.title = @"Open quickly";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStyleDone target:self action:@selector(_showBrowserInTabAction:)];
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    directoryPresenter = nil;
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
    _searchBar.placeholder = @"Search for file";
    [self.view addSubview:_searchBar];
    
    // Add table view
    [self.view addSubview:self.tableView];
    self.tableView.frame = CGRectMake(0, 44, bounds.size.width, bounds.size.height - 44);
    
    // Add table view footer view
    _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 50)];
    _infoLabel.textAlignment = UITextAlignmentCenter;
    _infoLabel.text = @"Type a file name to open";
    self.tableView.tableFooterView = _infoLabel;
}

- (void)viewDidUnload
{
    _searchBar = nil;
    _infoLabel = nil;
    tableView = nil;
    directoryPresenter = nil;
    
    [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_searchBar becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Directory Presenter Delegate

- (NSOperationQueue *)delegateOperationQueue
{
    return [NSOperationQueue mainQueue];
}

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didInsertFileURLsAtIndexes:(NSIndexSet *)insertIndexes removeFileURLsAtIndexes:(NSIndexSet *)removeIndexes changeFileURLsAtIndexes:(NSIndexSet *)changeIndexes
{
    NSMutableArray *insertIndexPaths = [NSMutableArray arrayWithCapacity:[insertIndexes count]];
    [insertIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [insertIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    NSMutableArray *removeIndexPaths = [NSMutableArray arrayWithCapacity:[removeIndexes count]];
    [removeIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [removeIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    NSMutableArray *changeIndexPaths = [NSMutableArray arrayWithCapacity:[changeIndexes count]];
    [changeIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [changeIndexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView deleteRowsAtIndexPaths:removeIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadRowsAtIndexPaths:changeIndexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

#pragma mark - UISeachBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Apply filter to filterController with .3 second debounce
    [_filterDebounceTimer invalidate];
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        self.directoryPresenter.filterString = searchText;
        if ([self.directoryPresenter.fileURLs count] == 0)
        {
            _infoLabel.text = @"Type a file name to open";
        }
        else
        {
            _infoLabel.text = nil;
        }
    } repeats:NO];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [self.directoryPresenter.fileURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    ACHighlightTableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ACHighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.highlightLabel.highlightedBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
    }
    
    NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:indexPath.row];
    BOOL isDirecotry = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirecotry];
    if (isDirecotry)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[fileURL pathExtension]];
    
    cell.highlightLabel.text = [fileURL lastPathComponent];
    cell.highlightLabel.highlightedCharacters = [self.directoryPresenter hitMaskForFileURL:fileURL];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.quickBrowsersContainerController.popoverController dismissPopoverAnimated:YES];
    [self.quickBrowsersContainerController.tab pushURL:[self.directoryPresenter.fileURLs objectAtIndex:indexPath.row]];
}

#pragma mark - Private methods

- (void)_showBrowserInTabAction:(id)sender
{
    [self.quickBrowsersContainerController.popoverController dismissPopoverAnimated:YES];
    [self.quickBrowsersContainerController.tab pushURL:[self.quickBrowsersContainerController.tab.currentProject URL]];
}

@end
