//
//  QuickFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import "NSTimer+BlockTimer.h"

#import "ArtCodeTab.h"
#import "ArtCodeProject.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"

#import "SmartFilteredDirectoryPresenter.h"

static void *_directoryObservingContext;

@interface QuickFileBrowserController ()

@property (nonatomic, strong) SmartFilteredDirectoryPresenter *directoryPresenter;

- (void)_showBrowserInTabAction:(id)sender;
- (void)_showProjectsInTabAction:(id)sender;

@end


@implementation QuickFileBrowserController {
    UISearchBar *_searchBar;
    UILabel *_infoLabel;
    NSTimer *_filterDebounceTimer;
    NSString *_projectURLAbsoluteString;
}

#pragma mark - Properties

@synthesize directoryPresenter = _directoryPresenter, tableView;

- (DirectoryPresenter *)directoryPresenter
{
    if (!_directoryPresenter)
    {
        NSURL *projectURL = self.quickBrowsersContainerController.tab.currentProject.URL;
        _directoryPresenter = [[SmartFilteredDirectoryPresenter alloc] initWithDirectoryURL:projectURL options:NSDirectoryEnumerationSkipsHiddenFiles];
        [_directoryPresenter addObserver:self forKeyPath:@"fileURLs" options:0 context:&_directoryObservingContext];
        _projectURLAbsoluteString = [projectURL absoluteString];
    }
    return _directoryPresenter;
}

- (void)setDirectoryPresenter:(SmartFilteredDirectoryPresenter *)directoryPresenter
{
    if (directoryPresenter == _directoryPresenter)
        return;
    [self willChangeValueForKey:@"directoryPresenter"];
    [_directoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&_directoryObservingContext];
    _directoryPresenter = directoryPresenter;
    [_directoryPresenter addObserver:self forKeyPath:@"fileURLs" options:0 context:&_directoryObservingContext];
    [self didChangeValueForKey:@"directoryPresenter"];
}

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

#pragma mark - Controller lifecycle

- (id)init
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self)
        return nil;
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Files" image:nil tag:0];
    self.navigationItem.title = @"Open quickly";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStyleDone target:self action:@selector(_showBrowserInTabAction:)];
    UIBarButtonItem *backToProjectsItem = [[UIBarButtonItem alloc] initWithTitle:@"Projects" style:UIBarButtonItemStylePlain target:self action:@selector(_showProjectsInTabAction:)];
    [backToProjectsItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    self.navigationItem.leftBarButtonItem = backToProjectsItem;
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

- (void)dealloc
{
    self.directoryPresenter = nil; // this is so we stop observing
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    self.directoryPresenter = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &_directoryObservingContext)
    {
        NSKeyValueChange kind = [[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        [[change objectForKey:NSKeyValueChangeIndexesKey] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        }];
        switch (kind) {
            case NSKeyValueChangeInsertion:
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            case NSKeyValueChangeRemoval:
                [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            case NSKeyValueChangeReplacement:
                [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                break;
            case NSKeyValueChangeSetting:
                [self.tableView reloadData];
                break;
            default:
                ECASSERT(NO && "unhandled KVO change");
                break;
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
    _infoLabel.backgroundColor = [UIColor clearColor];
    _infoLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1];
    _infoLabel.shadowColor = [UIColor whiteColor];
    _infoLabel.shadowOffset = CGSizeMake(0, 1);
    _infoLabel.text = @"Type a file name to open.";
    self.tableView.tableFooterView = _infoLabel;
}

- (void)viewDidUnload
{
    _searchBar = nil;
    _infoLabel = nil;
    tableView = nil;
    self.directoryPresenter = nil;
    
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

#pragma mark - UISeachBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Apply filter to filterController with .3 second debounce
    [_filterDebounceTimer invalidate];
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        self.directoryPresenter.filterString = searchText;
        if ([self.directoryPresenter.fileURLs count] == 0)
        {
            _infoLabel.text = [searchText length] ? @"No file found for the search term." : @"Type a file name to open.";
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
    
    HighlightTableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabelHighlightedCharactersBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
    }
    
    NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:indexPath.row];
    BOOL isDirecotry = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirecotry];
    if (isDirecotry)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[fileURL pathExtension]];
    
    cell.textLabel.text = [fileURL lastPathComponent];
    cell.textLabelHighlightedCharacters = [self.directoryPresenter hitMaskForFileURL:fileURL];
    cell.detailTextLabel.text = [[ArtCodeProject pathRelativeToProjectsDirectory:fileURL] prettyPath];
    
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

- (void)_showProjectsInTabAction:(id)sender
{
    [self.quickBrowsersContainerController.popoverController dismissPopoverAnimated:YES];
    [self.quickBrowsersContainerController.tab pushURL:[ArtCodeProject projectsDirectory]];
}

@end
