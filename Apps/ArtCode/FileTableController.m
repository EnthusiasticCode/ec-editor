//
//  FileTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileTableController.h"
#import "SingleTabController.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"

#import "NewFileController.h"
#import "DirectoryBrowserController.h"
#import "MoveConflictController.h"

#import "NSTimer+BlockTimer.h"
#import "NSString+PluralFormat.h"
#import "NSURL+Utilities.h"
#import "BezelAlert.h"

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"
#import "TopBarToolbar.h"
#import "TopBarTitleControl.h"

#import "UIViewController+PresentingPopoverController.h"
#import "QuickBrowsersContainerController.h"

#import "DirectoryPresenter.h"
#import "SmartFilteredDirectoryPresenter.h"

static void *_currentProjectContext;
static void *_directoryObservingContext;
static void *_openQuicklyObservingContext;


@interface FileTableController () {
    ArtCodeProject *_currentObservedProject;
    
    NSArray *_toolNormalItems;
    NSArray *_toolEditItems;
    
    UIPopoverController *_toolNormalAddPopover;
    UIActionSheet *_toolEditItemDeleteActionSheet;
    UIActionSheet *_toolEditItemDuplicateActionSheet;
    UIActionSheet *_toolEditItemExportActionSheet;
    UINavigationController *_directoryBrowserNavigationController;
    
    NSTimer *_filterDebounceTimer;
    
    NSMutableArray *_selectedURLs;
    
    BOOL _isShowingOpenQuickly;
    
    UIPopoverController *_quickBrowsersPopover;
}

@property (nonatomic, strong) DirectoryPresenter *directoryPresenter;
@property (nonatomic, strong) SmartFilteredDirectoryPresenter *openQuicklyPresenter;

- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditDeleteAction:(id)sender;
- (void)_toolEditDuplicateAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

- (void)_directoryBrowserShowWithRightBarItem:(UIBarButtonItem *)rightItem;
- (void)_directoryBrowserDismissAction:(id)sender;
- (void)_directoryBrowserCopyAction:(id)sender;
- (void)_directoryBrowserMoveAction:(id)sender;

- (DirectoryPresenter *)_currentPresenter;

@end

#pragma mark - Implementations
#pragma mark -

@implementation FileTableController

#pragma mark - Properties

@synthesize directory = _directory, tab;
@synthesize directoryPresenter = _directoryPresenter, openQuicklyPresenter = _openQuicklyPresenter;

- (void)setDirectoryPresenter:(DirectoryPresenter *)directoryPresenter
{
    if (directoryPresenter == _directoryPresenter)
        return;
    [self willChangeValueForKey:@"directoryPresenter"];
    [_directoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&_directoryObservingContext];
    _directoryPresenter = directoryPresenter;
    [_directoryPresenter addObserver:self forKeyPath:@"fileURLs" options:0 context:&_directoryObservingContext];
    [self didChangeValueForKey:@"directoryPresenter"];
}

- (void)setOpenQuicklyPresenter:(SmartFilteredDirectoryPresenter *)openQuicklyPresenter
{
    if (openQuicklyPresenter == _openQuicklyPresenter)
        return;
    [self willChangeValueForKey:@"openQuicklyPresenter"];
    [_openQuicklyPresenter removeObserver:self forKeyPath:@"fileURLs" context:&_openQuicklyObservingContext];
    _openQuicklyPresenter = openQuicklyPresenter;
    [_openQuicklyPresenter addObserver:self forKeyPath:@"fileURLs" options:0 context:&_openQuicklyObservingContext];
    [self didChangeValueForKey:@"openQuicklyPresenter"];
}

- (void)setDirectory:(NSURL *)directory
{
    if (directory == _directory)
        return;
    [self willChangeValueForKey:@"directory"];
    [_selectedURLs removeAllObjects];
    [_currentObservedProject removeObserver:self forKeyPath:@"labelColor" context:&_currentProjectContext];
    [_currentObservedProject removeObserver:self forKeyPath:@"name" context:&_currentProjectContext];
    _directory = directory;
    self.directoryPresenter = [[DirectoryPresenter alloc] initWithDirectoryURL:_directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    self.openQuicklyPresenter = [[SmartFilteredDirectoryPresenter alloc] initWithDirectoryURL:_directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    _currentObservedProject = self.tab.currentURL.project;
    [_currentObservedProject addObserver:self forKeyPath:@"labelColor" options:NSKeyValueObservingOptionNew context:&_currentProjectContext];
    [_currentObservedProject addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:&_currentProjectContext];    
    [self.tableView reloadData];
    [self didChangeValueForKey:@"directory"];
}

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
        searchBar.placeholder = @"Filter files";
        self.tableView.tableHeaderView = searchBar;
    }
    
    // TODO Write hints in this view
    if (!self.tableView.tableFooterView)
    {
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 0)];
        self.tableView.tableFooterView = footerView;
    }
    
    // Prepare edit button
    self.editButtonItem.title = @"";
    self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
    
    // Preparing tool items array changed in set editing
    _toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Duplicate"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDuplicateAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDeleteAction:)], nil];
    
    _toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.contentOffset = CGPointMake(0, 45);
    self.toolbarItems = _toolNormalItems;
}

- (void)viewDidUnload
{
    _toolNormalAddPopover = nil;
    
    _toolEditItemDeleteActionSheet = nil;
    _toolEditItemExportActionSheet = nil;
    _toolEditItemDuplicateActionSheet = nil;
    
    _toolEditItems = nil;
    _toolNormalItems = nil;
    
    _quickBrowsersPopover = nil;
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.directoryPresenter = [[DirectoryPresenter alloc] initWithDirectoryURL:self.directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    
    self.openQuicklyPresenter = [[SmartFilteredDirectoryPresenter alloc] initWithDirectoryURL:self.directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    
    [_selectedURLs removeAllObjects];
    
    if (!_currentObservedProject)
    {
        _currentObservedProject = self.tab.currentURL.project;
        [_currentObservedProject addObserver:self forKeyPath:@"labelColor" options:NSKeyValueObservingOptionNew context:&_currentProjectContext];
        [_currentObservedProject addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:&_currentProjectContext];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.directoryPresenter = nil;
    self.openQuicklyPresenter = nil;
    _selectedURLs = nil;
    
    [_currentObservedProject removeObserver:self forKeyPath:@"labelColor" context:&_currentProjectContext];
    [_currentObservedProject removeObserver:self forKeyPath:@"name" context:&_currentProjectContext];
    _currentObservedProject = nil;
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
    
    [_selectedURLs removeAllObjects];
    
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
        self.toolbarItems = _toolNormalItems;
    }
    
    [self didChangeValueForKey:@"editing"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &_currentProjectContext)
    {
        [self.singleTabController updateDefaultToolbarTitle];
    }
    else if (context == &_directoryObservingContext || context == &_openQuicklyObservingContext)
    {
        if (_isShowingOpenQuickly && object == _openQuicklyPresenter)
        {
            [self.tableView reloadData];
            return;
        }
        if (object == _directoryPresenter && _isShowingOpenQuickly)
            return;
        [self.tableView reloadData];
        NSKeyValueChange kind = [[change objectForKey:NSKeyValueChangeKindKey] unsignedIntegerValue];
        if (kind == NSKeyValueChangeInsertion)
        {
            [[change objectForKey:NSKeyValueChangeIndexesKey] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                *stop = YES;
            }];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    // this is so we stop observing
    self.directoryPresenter = nil;
    self.openQuicklyPresenter = nil;
    [_currentObservedProject removeObserver:self forKeyPath:@"labelColor" context:&_currentProjectContext];
    [_currentObservedProject removeObserver:self forKeyPath:@"name" context:&_currentProjectContext];
}

#pragma mark - Single tab content controller protocol methods

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar
{
    return YES;
}

- (void)singleTabController:(SingleTabController *)singleTabController titleControlAction:(id)sender
{
    // TODO the quick browser container controller gets created every time, is it ok?
    QuickBrowsersContainerController *quickBrowserContainerController = [QuickBrowsersContainerController defaultQuickBrowsersContainerControllerForTab:self.tab];
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
    quickBrowserContainerController.popoverController = _quickBrowsersPopover;
    quickBrowserContainerController.openingButton = sender;
    [_quickBrowsersPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (BOOL)singleTabController:(SingleTabController *)singleTabController setupDefaultToolbarTitleControl:(TopBarTitleControl *)titleControl
{
    BOOL isRoot = NO;
    NSString *projectName = [ArtCodeURL projectNameFromURL:self.tab.currentURL isProjectRoot:&isRoot];
    if (!isRoot)
    {
        return NO; // default behaviour
    }
    else
    {
        [titleControl setTitleFragments:[NSArray arrayWithObjects:[UIImage styleProjectLabelImageWithSize:CGSizeMake(12, 22) color:self.tab.currentURL.project.labelColor], projectName, nil] 
                        selectedIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
    }
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self _currentPresenter].fileURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FileCellIdentifier = @"FileCell";
    
    HighlightTableViewCell *cell = [tView dequeueReusableCellWithIdentifier:FileCellIdentifier];
    if (cell == nil)
    {
        cell = [[HighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:FileCellIdentifier];
        cell.textLabelHighlightedCharactersBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
    }
    
    // Configure the cell
    NSURL *fileURL = [[self _currentPresenter].fileURLs objectAtIndex:indexPath.row];
    
    BOOL isDirecotry = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirecotry];
    if (isDirecotry)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[fileURL pathExtension]];
    
    cell.textLabel.text = [fileURL lastPathComponent];
    
    if (_isShowingOpenQuickly)
        cell.textLabelHighlightedCharacters = [self.openQuicklyPresenter hitMaskForFileURL:fileURL];
    else
        cell.textLabelHighlightedCharacters = nil;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
    {
        if (!_selectedURLs)
            _selectedURLs = [NSMutableArray new];
        [_selectedURLs addObject:[[self _currentPresenter].fileURLs objectAtIndex:indexPath.row]];
        BOOL anySelected = [tableView indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in _toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
    else
    {
        [self.tab pushURL:[[self _currentPresenter].fileURLs objectAtIndex:indexPath.row]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
    {
        [_selectedURLs removeObject:[[self _currentPresenter].fileURLs objectAtIndex:indexPath.row]];
        BOOL anySelected = [tableView indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in _toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
}

#pragma mark - UISeachBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Apply filter to filterController with .3 second debounce
    [_filterDebounceTimer invalidate];
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        if (_isShowingOpenQuickly)
            [_selectedURLs removeAllObjects];
        if ([searchText length] && !_isShowingOpenQuickly)
        {
            [_selectedURLs removeAllObjects];
            _isShowingOpenQuickly = YES;
            [self.tableView reloadData];
        }
        else if (![searchText length] && _isShowingOpenQuickly)
        {
            _isShowingOpenQuickly = NO;
            [self.tableView reloadData];
        }
        self.openQuicklyPresenter.filterString = searchText;
    } repeats:NO];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == _toolEditItemDeleteActionSheet)
    {
        if (buttonIndex == actionSheet.destructiveButtonIndex) // Delete
        {
            self.loading = YES;
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSFileManager *fileManager = [NSFileManager new];
            [_selectedURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
                [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
                    [fileManager removeItemAtURL:newURL error:NULL];
                }];
            }];
            self.loading = NO;
            [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File deleted" plural:@"%u files deleted" count:[_selectedURLs count]] image:nil displayImmediatly:YES];
            [self setEditing:NO animated:YES];
        }
    }
    else if (actionSheet == _toolEditItemDuplicateActionSheet)
    {
        if (buttonIndex == 0) // Copy
        {
            [self _directoryBrowserShowWithRightBarItem:[[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserCopyAction:)]];
        }
        else if (buttonIndex == 1) // Duplicate
        {
            self.loading = YES;
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSFileManager *fileManager = [NSFileManager new];
            [_selectedURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
                NSUInteger count = 0;
                NSURL *dupUrl = nil;
                do {
                    dupUrl = [url URLByAddingDuplicateNumber:++count];
                } while ([fileManager fileExistsAtPath:[dupUrl path]]);
                [coordinator coordinateReadingItemAtURL:url options:0 writingItemAtURL:dupUrl options:NSFileCoordinatorWritingForReplacing error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
                    [fileManager copyItemAtURL:newReadingURL toURL:newWritingURL error:NULL];
                }];
            }];
            self.loading = NO;
            [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File duplicated" plural:@"%u files duplicated" count:[_selectedURLs count]] image:nil displayImmediatly:YES];
            [self setEditing:NO animated:YES];
        }
    }
    else if (actionSheet == _toolEditItemExportActionSheet)
    {
        if (buttonIndex == 0) // Move
        {
            [self _directoryBrowserShowWithRightBarItem:[[UIBarButtonItem alloc] initWithTitle:@"Move" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserMoveAction:)]];
        }
        else if (buttonIndex == 1) // iTunes
        {
            self.loading = YES;
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSFileManager *fileManager = [NSFileManager new];
            NSURL *documentsURL = [NSURL applicationDocumentsDirectory];
            [_selectedURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
                [coordinator coordinateReadingItemAtURL:url options:0 writingItemAtURL:documentsURL options:NSFileCoordinatorWritingForReplacing error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
                    [fileManager copyItemAtURL:newReadingURL toURL:newWritingURL error:NULL];
                }];
            }];
            self.loading = NO;
            [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File exported" plural:@"%u files exported" count:[_selectedURLs count]] image:nil displayImmediatly:YES];
            [self setEditing:NO animated:YES];
        }
        else if (buttonIndex == 2) // Mail
        {
            MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];
            mailComposer.mailComposeDelegate = self;
            mailComposer.navigationBar.barStyle = UIBarStyleDefault;
            mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
            
            // Compressing projects to export
            self.loading = YES;
            
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [_selectedURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
                // Generate zip attachments
                __block NSData *attachment = nil;
                [coordinator coordinateReadingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *newURL) {
                    attachment = [NSData dataWithContentsOfURL:newURL];
                }];
                [mailComposer addAttachmentData:attachment mimeType:@"text/plain" fileName:[url lastPathComponent]];
            }];
            
            [mailComposer setSubject:[NSString stringWithFormat:@"%@ exported files", [[ArtCodeProject projectWithURL:[_selectedURLs objectAtIndex:0]] name]]];
            
            if ([_selectedURLs count] == 1)
                [mailComposer setMessageBody:@"<br/><p>Open this file with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained project.</p>" isHTML:YES];
            else
                [mailComposer setMessageBody:@"<br/><p>Open this files with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained projects.</p>" isHTML:YES];
            
            [self setEditing:NO animated:YES];
            [self presentViewController:mailComposer animated:YES completion:nil];
            [mailComposer.navigationBar.topItem.leftBarButtonItem setBackgroundImage:[[UIImage imageNamed:@"topBar_ToolButton_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 10, 10)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            self.loading = NO;
        }
    }
}

#pragma mark - Mail composer Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent)
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Mail sent" image:nil displayImmediatly:YES];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)_toolNormalAddAction:(id)sender
{
    if (!_toolNormalAddPopover)
    {
        UINavigationController *popoverViewController = (UINavigationController *)[[UIStoryboard storyboardWithName:@"NewFilePopover" bundle:nil] instantiateInitialViewController];
        popoverViewController.artCodeTab = self.tab;
        [popoverViewController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        
        _toolNormalAddPopover = [[UIPopoverController alloc] initWithContentViewController:popoverViewController];
        _toolNormalAddPopover.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
        popoverViewController.presentingPopoverController = _toolNormalAddPopover;
    }
    [_toolNormalAddPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)_toolEditDeleteAction:(id)sender
{
    if (!_toolEditItemDeleteActionSheet)
    {
        _toolEditItemDeleteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Delete permanently" otherButtonTitles:nil];
        _toolEditItemDeleteActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolEditItemDeleteActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditExportAction:(id)sender
{
    if (!_toolEditItemExportActionSheet)
    {
        _toolEditItemExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Move to new location", @"Export to iTunes", ([MFMailComposeViewController canSendMail] ? @"Send via E-Mail" : nil), nil];
        _toolEditItemExportActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolEditItemExportActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditDuplicateAction:(id)sender
{
    if (!_toolEditItemDuplicateActionSheet)
    {
        _toolEditItemDuplicateActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Copy to new location", @"Duplicate", nil];
        _toolEditItemDuplicateActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolEditItemDuplicateActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_directoryBrowserShowWithRightBarItem:(UIBarButtonItem *)rightItem
{
    DirectoryBrowserController *directoryBrowser = [DirectoryBrowserController new];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    directoryBrowser.navigationItem.leftBarButtonItem = cancelItem;
    directoryBrowser.navigationItem.rightBarButtonItem = rightItem;
    directoryBrowser.URL = self.tab.currentURL.project.URL;
    _directoryBrowserNavigationController = [[UINavigationController alloc] initWithRootViewController:directoryBrowser];
    _directoryBrowserNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:_directoryBrowserNavigationController animated:YES completion:nil];
}

- (void)_directoryBrowserDismissAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        _directoryBrowserNavigationController = nil;
    }];
}

- (void)_directoryBrowserCopyAction:(id)sender
{    
    // Retrieve URL to move to
    DirectoryBrowserController *directoryBrowser = (DirectoryBrowserController *)_directoryBrowserNavigationController.topViewController;
    NSURL *moveURL = directoryBrowser.selectedURL;
    if (moveURL == nil)
        moveURL = directoryBrowser.URL;
    // Initialize conflict controller
    MoveConflictController *conflictController = [[MoveConflictController alloc] init];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    conflictController.navigationItem.leftBarButtonItem = cancelItem;
    // Show conflict controller
    NSFileManager *fileManager = [NSFileManager new];
    [_directoryBrowserNavigationController pushViewController:conflictController animated:YES];
    [conflictController processItemURLs:[_selectedURLs copy] toURL:moveURL usignProcessingBlock:^(NSURL *itemURL, NSURL *destinationURL) {
        [fileManager copyItemAtURL:itemURL toURL:destinationURL error:NULL];
    } completion:^{
        [self setEditing:NO animated:YES];
        [self _directoryBrowserDismissAction:sender];
    }];
}

- (void)_directoryBrowserMoveAction:(id)sender
{
    // Retrieve URL to move to
    DirectoryBrowserController *directoryBrowser = (DirectoryBrowserController *)_directoryBrowserNavigationController.topViewController;
    NSURL *moveURL = directoryBrowser.selectedURL;
    if (moveURL == nil)
        moveURL = directoryBrowser.URL;
    // Initialize conflict controller
    MoveConflictController *conflictController = [[MoveConflictController alloc] init];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    conflictController.navigationItem.leftBarButtonItem = cancelItem;
    // Show conflict controller
    NSFileManager *fileManager = [NSFileManager new];
    [_directoryBrowserNavigationController pushViewController:conflictController animated:YES];
    [conflictController processItemURLs:[_selectedURLs copy] toURL:moveURL usignProcessingBlock:^(NSURL *itemURL, NSURL *destinationURL) {
        [fileManager moveItemAtURL:itemURL toURL:destinationURL error:NULL];
    } completion:^{
        [self setEditing:NO animated:YES];
        [self _directoryBrowserDismissAction:sender];
    }];
}

- (DirectoryPresenter *)_currentPresenter
{
    return _isShowingOpenQuickly ? self.openQuicklyPresenter : self.directoryPresenter;
}

@end
