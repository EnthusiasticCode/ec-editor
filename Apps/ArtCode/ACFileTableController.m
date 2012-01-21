//
//  ACFileTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileTableController.h"
#import "ACSingleProjectBrowsersController.h"

#import "AppStyle.h"
#import "ACNewFileController.h"
#import "ACDirectoryBrowserController.h"
#import "ACMoveConflictController.h"

#import <ECFoundation/NSTimer+block.h>
#import <ECFoundation/NSString+ECAdditions.h>
#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECUIKit/NSURL+URLDuplicate.h>
#import <ECUIKit/ECBezelAlert.h>

#import "ACHighlightTableViewCell.h"

#import "ACTab.h"


@interface ACFileTableController () {
    NSArray *_toolNormalItems;
    NSArray *_toolEditItems;
    
    UIPopoverController *_toolNormalAddPopover;
    UIActionSheet *_toolEditItemDeleteActionSheet;
    UIActionSheet *_toolEditItemDuplicateActionSheet;
    UIActionSheet *_toolEditItemExportActionSheet;
    UINavigationController *_directoryBrowserNavigationController;
    
    NSTimer *_filterDebounceTimer;
    
    NSMutableArray *_selectedURLs;
}

@property (nonatomic, strong) ECDirectoryPresenter *directoryPresenter;

- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditDeleteAction:(id)sender;
- (void)_toolEditDuplicateAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

- (void)_directoryBrowserShowWithRightBarItem:(UIBarButtonItem *)rightItem;
- (void)_directoryBrowserDismissAction:(id)sender;
- (void)_directoryBrowserCopyAction:(id)sender;
- (void)_directoryBrowserMoveAction:(id)sender;

@end

#pragma mark - Implementations
#pragma mark -

@implementation ACFileTableController

#pragma mark - Properties

@synthesize directory = _directory, directoryPresenter = _directoryPresenter;

- (void)setDirectory:(NSURL *)directory
{
    if (directory == _directory)
        return;
    [self willChangeValueForKey:@"directory"];
    _directory = directory;
    self.directoryPresenter = [[ECDirectoryPresenter alloc] initWithDirectoryURL:_directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    self.directoryPresenter.delegate = self;
    [self didChangeValueForKey:@"directory"];
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    // TODO Write hints in this view
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 0)];
    self.tableView.tableFooterView = footerView;
    
    // Preparing tool items array changed in set editing
    _toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Duplicate"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDuplicateAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDeleteAction:)], nil];
    
    _toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)]];
    self.toolbarItems = _toolNormalItems;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.contentOffset = CGPointMake(0, 45);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _toolNormalAddPopover = nil;
    
    _toolEditItemDeleteActionSheet = nil;
    _toolEditItemExportActionSheet = nil;
    _toolEditItemDuplicateActionSheet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.directoryPresenter = [[ECDirectoryPresenter alloc] initWithDirectoryURL:self.directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    self.directoryPresenter.delegate = self;
    
    [_selectedURLs removeAllObjects];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.directoryPresenter = nil;
    _selectedURLs = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
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
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.directoryPresenter.filteredFileURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FileCellIdentifier = @"FileCell";
    
    ACHighlightTableViewCell *cell = [tView dequeueReusableCellWithIdentifier:FileCellIdentifier];
    if (cell == nil)
    {
        cell = [[ACHighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FileCellIdentifier];
    }
    
    // Configure the cell
    NSURL *fileURL = [self.directoryPresenter.filteredFileURLs objectAtIndex:indexPath.row];
    
    BOOL isDirecotry = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirecotry];
    if (isDirecotry)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[fileURL pathExtension]];
    
    cell.highlightLabel.text = [fileURL lastPathComponent];
    
    if ([self.directoryPresenter.filterString length] > 0)
    {
        cell.highlightLabel.highlightedBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
        cell.highlightLabel.highlightedCharacters = [self.directoryPresenter.filterHitMasks objectAtIndex:indexPath.row];
    }
    else
    {
        cell.highlightLabel.highlightedCharacters = nil;
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
    {
        if (!_selectedURLs)
            _selectedURLs = [NSMutableArray new];
        [_selectedURLs addObject:[self.directoryPresenter.filteredFileURLs objectAtIndex:indexPath.row]];
        BOOL anySelected = [tableView indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in _toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
    else
    {
        [self.singleProjectBrowsersController.tab pushURL:[self.directoryPresenter.filteredFileURLs objectAtIndex:indexPath.row]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
    {
        [_selectedURLs removeObject:[self.directoryPresenter.filteredFileURLs objectAtIndex:indexPath.row]];
        BOOL anySelected = [tableView indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in _toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
}

#pragma mark - Directory Presenter Delegate

- (NSOperationQueue *)delegateOperationQueue
{
    return [NSOperationQueue mainQueue];
}

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didInsertFilteredFileURLsAtIndexes:(NSIndexSet *)indexes
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[indexes count]];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didRemoveFilteredFileURLsAtIndexes:(NSIndexSet *)indexes
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[indexes count]];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didChangeHitMasksAtIndexes:(NSIndexSet *)indexes
{
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[indexes count]];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
    }];
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UISeachBar Delegate Methods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    // Apply filter to filterController with .3 second debounce
    [_filterDebounceTimer invalidate];
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        self.directoryPresenter.filterString = searchText;
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
            ECFileCoordinator *coordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
            NSFileManager *fileManager = [NSFileManager new];
            [_selectedURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
                [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
                    [fileManager removeItemAtURL:newURL error:NULL];
                }];
            }];
            self.loading = NO;
            [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File deleted" plural:@"%u files deleted" count:[_selectedURLs count]] image:nil displayImmediatly:YES];
            [self.singleProjectBrowsersController setEditing:NO animated:YES];
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
            ECFileCoordinator *coordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
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
            [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File duplicated" plural:@"%u files duplicated" count:[_selectedURLs count]] image:nil displayImmediatly:YES];
            [self.singleProjectBrowsersController setEditing:NO animated:YES];
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
            ECFileCoordinator *coordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
            NSFileManager *fileManager = [NSFileManager new];
            NSURL *documentsURL = [NSURL applicationDocumentsDirectory];
            [_selectedURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
                [coordinator coordinateReadingItemAtURL:url options:0 writingItemAtURL:documentsURL options:NSFileCoordinatorWritingForReplacing error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
                    [fileManager copyItemAtURL:newReadingURL toURL:newWritingURL error:NULL];
                }];
            }];
            self.loading = NO;
            [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File exported" plural:@"%u files exported" count:[_selectedURLs count]] image:nil displayImmediatly:YES];
            [self.singleProjectBrowsersController setEditing:NO animated:YES];
        }
        else if (buttonIndex == 2) // Mail
        {
            MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];
            mailComposer.mailComposeDelegate = self;
            mailComposer.navigationBar.barStyle = UIBarStyleDefault;
            mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
            
            // Compressing projects to export
            self.loading = YES;
            
            ECFileCoordinator *coordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
            [_selectedURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
                // Generate zip attachments
                __block NSData *attachment = nil;
                [coordinator coordinateReadingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *newURL) {
                    attachment = [NSData dataWithContentsOfURL:newURL];
                }];
                [mailComposer addAttachmentData:attachment mimeType:@"text/plain" fileName:[url lastPathComponent]];
            }];
            
            [mailComposer setSubject:[NSString stringWithFormat:@"%@ exported files", [[ACProject projectWithURL:[_selectedURLs objectAtIndex:0]] name]]];
            
            if ([_selectedURLs count] == 1)
                [mailComposer setMessageBody:@"<br/><p>Open this file with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained project.</p>" isHTML:YES];
            else
                [mailComposer setMessageBody:@"<br/><p>Open this files with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained projects.</p>" isHTML:YES];
            
            [self.singleProjectBrowsersController setEditing:NO animated:YES];
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
        [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:@"Mail sent" image:nil displayImmediatly:YES];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)_toolNormalAddAction:(id)sender
{
    if (!_toolNormalAddPopover)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewFilePopover" bundle:[NSBundle mainBundle]];
        ACNewFileController *popoverViewController = (ACNewFileController *)[storyboard instantiateInitialViewController];
        //        popoverViewController.group = self.group;
        _toolNormalAddPopover = [[UIPopoverController alloc] initWithContentViewController:popoverViewController];
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
    ACDirectoryBrowserController *directoryBrowser = [ACDirectoryBrowserController new];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    directoryBrowser.navigationItem.leftBarButtonItem = cancelItem;
    directoryBrowser.navigationItem.rightBarButtonItem = rightItem;
    directoryBrowser.URL = self.singleProjectBrowsersController.project.URL;
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
    ACDirectoryBrowserController *directoryBrowser = (ACDirectoryBrowserController *)_directoryBrowserNavigationController.topViewController;
    NSURL *moveURL = directoryBrowser.selectedURL;
    if (moveURL == nil)
        moveURL = directoryBrowser.URL;
    // Initialize conflict controller
    ACMoveConflictController *conflictController = [[ACMoveConflictController alloc] initWithNibName:@"MoveConflictController" bundle:nil];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    conflictController.navigationItem.leftBarButtonItem = cancelItem;
    // Show conflict controller
    NSFileManager *fileManager = [NSFileManager new];
    [_directoryBrowserNavigationController pushViewController:conflictController animated:YES];
    [conflictController processItemURLs:[_selectedURLs copy] toURL:moveURL usignProcessingBlock:^(NSURL *itemURL, NSURL *destinationURL) {
        [fileManager copyItemAtURL:itemURL toURL:destinationURL error:NULL];
    } completion:^{
        [self.singleProjectBrowsersController setEditing:NO animated:YES];
        [self _directoryBrowserDismissAction:sender];
    }];
}

- (void)_directoryBrowserMoveAction:(id)sender
{
    // Retrieve URL to move to
    ACDirectoryBrowserController *directoryBrowser = (ACDirectoryBrowserController *)_directoryBrowserNavigationController.topViewController;
    NSURL *moveURL = directoryBrowser.selectedURL;
    if (moveURL == nil)
        moveURL = directoryBrowser.URL;
    // Initialize conflict controller
    ACMoveConflictController *conflictController = [[ACMoveConflictController alloc] initWithNibName:@"MoveConflictController" bundle:nil];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    conflictController.navigationItem.leftBarButtonItem = cancelItem;
    // Show conflict controller
    NSFileManager *fileManager = [NSFileManager new];
    [_directoryBrowserNavigationController pushViewController:conflictController animated:YES];
    [conflictController processItemURLs:[_selectedURLs copy] toURL:moveURL usignProcessingBlock:^(NSURL *itemURL, NSURL *destinationURL) {
        [fileManager moveItemAtURL:itemURL toURL:destinationURL error:NULL];
    } completion:^{
        [self.singleProjectBrowsersController setEditing:NO animated:YES];
        [self _directoryBrowserDismissAction:sender];
    }];
}

@end
