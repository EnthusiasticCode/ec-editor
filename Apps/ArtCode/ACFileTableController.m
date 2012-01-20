//
//  ACFileTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileTableController.h"
#import "ACSingleTabController.h"
#import "AppStyle.h"
#import "ACNewFileController.h"
#import "ACDirectoryBrowserController.h"
#import "ACMoveConflictController.h"

#import <ECFoundation/ECDirectoryPresenter.h>
#import <ECFoundation/NSTimer+block.h>
#import <ECFoundation/NSString+ECAdditions.h>
#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECUIKit/NSURL+URLDuplicate.h>
#import <ECUIKit/ECBezelAlert.h>

#import "ACHighlightTableViewCell.h"

#import "ACTab.h"
#import "ACProject.h"

static void * directoryPresenterFileURLsObservingContext;

@interface FilteredFileURLWrapper : NSObject

@property (nonatomic) float score;
@property (nonatomic, strong) NSIndexSet *hitMask;
@property (nonatomic, strong) NSURL *fileURL;

- (id)initWithFileURL:(NSURL *)fileURL;
- (NSComparisonResult)compare:(FilteredFileURLWrapper *)wrapper;

@end


@implementation FilteredFileURLWrapper

@synthesize score = _score, hitMask = _hitMask, fileURL = _fileURL;

- (id)initWithFileURL:(NSURL *)fileURL
{
    self = [super init];
    if (!self)
        return nil;
    self.fileURL = fileURL;
    return self;
}

- (NSComparisonResult)compare:(FilteredFileURLWrapper *)wrapper
{
    if (self.score > wrapper.score)
        return NSOrderedAscending;
    else if (self.score < wrapper.score)
        return NSOrderedDescending;
    return [[self.fileURL lastPathComponent] compare:[wrapper.fileURL lastPathComponent]];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]])
        return NO;
    return [self.fileURL isEqual:[object fileURL]];
}

@end

@interface ACFileTableController () {
    NSArray *_toolNormalItems;
    NSArray *_toolEditItems;
    
    UIPopoverController *_toolNormalAddPopover;
    UIActionSheet *_toolEditItemDeleteActionSheet;
    UIActionSheet *_toolEditItemDuplicateActionSheet;
    UIActionSheet *_toolEditItemExportActionSheet;
    UINavigationController *_directoryBrowserNavigationController;
    
    NSTimer *_filterDebounceTimer;
    
    NSArray *extensions;
    NSMutableArray *_selectedURLs;
}

@property (nonatomic, strong) ECDirectoryPresenter *directoryPresenter;

/// The string used to smart filter the file list
@property (nonatomic, strong) NSString *filterString;

/// The number of filteredFileURLs to consider.
@property (nonatomic) NSUInteger filterCount;

/// Array of URLs ordered based on filterString score.
@property (nonatomic, strong) NSMutableArray *filteredFileURLs;

- (void)directoryPresenterDidChangeFileURLs:(NSArray *)newFileURLs;
- (void)directoryPresenterDidInsertFileURLsAtIndexes:(NSIndexSet *)indexes inFileURLs:(NSArray *)newFileURLs;
- (void)directoryPresenterDidRemoveFileURLsAtIndexes:(NSIndexSet *)indexes fromFileURLs:(NSArray *)oldFileURLs;

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

@synthesize tab = _tab;
@synthesize directory = _directory, directoryPresenter = _directoryPresenter;
@synthesize filterString = _filterString, filterCount = _filterCount, filteredFileURLs = _filteredFileURLs;

- (void)setDirectory:(NSURL *)directory
{
    if (directory == _directory)
        return;
    [self willChangeValueForKey:@"directory"];
    _directory = directory;
    self.directoryPresenter = [[ECDirectoryPresenter alloc] initWithDirectoryURL:_directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    [self didChangeValueForKey:@"directory"];
}

- (void)setDirectoryPresenter:(ECDirectoryPresenter *)directoryPresenter
{
    if (directoryPresenter == _directoryPresenter)
        return;
    [self willChangeValueForKey:@"directoryPresenter"];
    [_directoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&directoryPresenterFileURLsObservingContext];
    _directoryPresenter = directoryPresenter;
    [_directoryPresenter addObserver:self forKeyPath:@"fileURLs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&directoryPresenterFileURLsObservingContext];
    [self didChangeValueForKey:@"directoryPresenter"];
}

- (void)setFilterString:(NSString *)filterString
{
    if (filterString == _filterString)
        return;
    [self willChangeValueForKey:@"filterString"];
    _filterString = filterString;
    // Maintain selection
    NSMutableArray *newSelectedIndexes = nil;
    if (self.isEditing && [_selectedURLs count] > 0)
        newSelectedIndexes = [NSMutableArray new];
    // Sort URLs by score
    NSMutableArray *newFilteredFileURLs = [[NSMutableArray alloc] initWithCapacity:[self.filteredFileURLs count]];
    __block NSMutableArray *filteredOutIndexes = nil;
    __block NSMutableArray *filteredInIndexes = nil;
    __block NSMutableArray *filteredUpdateIndexes = nil;
    __block NSUInteger newFilterCount = 0;
    [self.filteredFileURLs enumerateObjectsUsingBlock:^(FilteredFileURLWrapper *wrapper, NSUInteger idx, BOOL *stop) {
        NSIndexSet *hitMask = nil;
        float score = [[wrapper.fileURL lastPathComponent] scoreForAbbreviation:filterString hitMask:&hitMask];
        if (score > 0.0)
        {
            if (idx < _filterCount)
            {
                if (!filteredUpdateIndexes)
                    filteredUpdateIndexes = [NSMutableArray new];
                [filteredUpdateIndexes addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
            }
            else
            {
                if (!filteredInIndexes)
                    filteredInIndexes = [NSMutableArray new];
                [filteredInIndexes addObject:[NSIndexPath indexPathForRow:newFilterCount inSection:0]];
            }
            ++newFilterCount;
        }
        else
        {
            if (idx < _filterCount)
            {
                if (!filteredOutIndexes)
                    filteredOutIndexes = [NSMutableArray new];
                [filteredOutIndexes addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
            }
        }
        wrapper.score = score;
        wrapper.hitMask = hitMask;
        [newFilteredFileURLs addObject:wrapper];
    }];
    // Apply new filtered URLs
    [newFilteredFileURLs sortUsingSelector:@selector(compare:)];
    self.filteredFileURLs = newFilteredFileURLs;
    self.filterCount = newFilterCount;
    // Animate filtering
    [self.tableView beginUpdates];
    if (filteredOutIndexes)
        [self.tableView deleteRowsAtIndexPaths:filteredOutIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
    if (filteredUpdateIndexes)
        [self.tableView reloadRowsAtIndexPaths:filteredUpdateIndexes withRowAnimation:UITableViewRowAnimationNone];
    if (filteredInIndexes)
        [self.tableView insertRowsAtIndexPaths:filteredInIndexes withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    // Apply selection
    [newFilteredFileURLs enumerateObjectsUsingBlock:^(FilteredFileURLWrapper *wrapper, NSUInteger idx, BOOL *stop) {
        if (idx >= newFilterCount)
        {
            *stop = YES;
            return;
        }
        if ([_selectedURLs containsObject:wrapper.fileURL])
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }];
    [self didChangeValueForKey:@"filterString"];
}

- (NSMutableArray *)filteredFileURLs
{
    if (!_filteredFileURLs)
        _filteredFileURLs = [NSMutableArray array];
    return _filteredFileURLs;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &directoryPresenterFileURLsObservingContext)
    {
        if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeInsertion)
            [self directoryPresenterDidInsertFileURLsAtIndexes:[change objectForKey:NSKeyValueChangeIndexesKey] inFileURLs:[change objectForKey:NSKeyValueChangeNewKey]];
        else if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeRemoval)
            [self directoryPresenterDidRemoveFileURLsAtIndexes:[change objectForKey:NSKeyValueChangeIndexesKey] fromFileURLs:[change objectForKey:NSKeyValueChangeOldKey]];
        else if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeReplacement)
        {
            [self directoryPresenterDidRemoveFileURLsAtIndexes:[change objectForKey:NSKeyValueChangeIndexesKey] fromFileURLs:[change objectForKey:NSKeyValueChangeOldKey]];
            [self directoryPresenterDidInsertFileURLsAtIndexes:[change objectForKey:NSKeyValueChangeIndexesKey] inFileURLs:[change objectForKey:NSKeyValueChangeNewKey]];
        }
        else
            [self directoryPresenterDidChangeFileURLs:[[change objectForKey:NSKeyValueChangeNewKey] isEqual:[NSNull null]] ? nil : [change objectForKey:NSKeyValueChangeNewKey]];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)directoryPresenterDidChangeFileURLs:(NSArray *)newFileURLs
{
    [self.filteredFileURLs removeAllObjects];
    [_selectedURLs removeAllObjects];
    NSUInteger newFilterCount = 0;
    for (NSURL *fileURL in newFileURLs)
    {
        FilteredFileURLWrapper *fileURLWrapper = [[FilteredFileURLWrapper alloc] initWithFileURL:fileURL];
        NSIndexSet *hitMask = nil;
        float score = [[fileURL lastPathComponent] scoreForAbbreviation:self.filterString hitMask:&hitMask];
        if (score)
            newFilterCount++;
        fileURLWrapper.score = score;
        fileURLWrapper.hitMask = hitMask;
        [self.filteredFileURLs addObject:fileURLWrapper];
    }
    self.filterCount = newFilterCount;
    [self.filteredFileURLs sortUsingSelector:@selector(compare:)];
    [self.tableView reloadData];
}

- (void)directoryPresenterDidInsertFileURLsAtIndexes:(NSIndexSet *)indexes inFileURLs:(NSArray *)newFileURLs
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSURL *fileURL = [newFileURLs objectAtIndex:idx];
        FilteredFileURLWrapper *fileURLWrapper = [[FilteredFileURLWrapper alloc] initWithFileURL:fileURL];
        NSIndexSet *hitMask = nil;
        fileURLWrapper.score = [[fileURL lastPathComponent] scoreForAbbreviation:self.filterString hitMask:&hitMask];
        fileURLWrapper.hitMask = hitMask;
        [self.filteredFileURLs insertObject:fileURLWrapper atIndex:[self.filteredFileURLs indexOfObject:fileURLWrapper inSortedRange:NSMakeRange(0, [self.filteredFileURLs count]) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }]];
    }];
}

- (void)directoryPresenterDidRemoveFileURLsAtIndexes:(NSIndexSet *)indexes fromFileURLs:(NSArray *)oldFileURLs
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSURL *fileURL = [oldFileURLs objectAtIndex:idx];
        FilteredFileURLWrapper *fileURLWrapper = [[FilteredFileURLWrapper alloc] initWithFileURL:fileURL];
        fileURLWrapper.score = [[fileURL lastPathComponent] scoreForAbbreviation:self.filterString hitMask:NULL];
        NSUInteger index = [self.filteredFileURLs indexOfObject:fileURLWrapper inSortedRange:NSMakeRange(0, [self.filteredFileURLs count]) options:0 usingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }];
        [self.filteredFileURLs removeObjectAtIndex:index];
    }];
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    // TODO Write hints in this view
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 0)];
    self.tableView.tableFooterView = footerView;
    
    extensions = [NSArray arrayWithObjects:@"h", @"m", @"hpp", @"cpp", @"mm", @"py", nil];
    
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
    return self.filterCount;
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
    FilteredFileURLWrapper *fileWrapper = [self.filteredFileURLs objectAtIndex:indexPath.row];
    NSString *fileName = [[fileWrapper fileURL] lastPathComponent];
    if (![fileName pathExtension])
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithSize:CGSizeMake(32, 32) 
                                                             color:[[fileName pathExtension] isEqualToString:@"h"] ? [UIColor styleFileRedColor] : [UIColor styleFileBlueColor]
                                                              text:[fileName pathExtension]];
    cell.highlightLabel.text = fileName;
    
    if ([fileWrapper.hitMask count] > 0)
    {
        cell.highlightLabel.highlightedBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
        cell.highlightLabel.highlightedCharacters = fileWrapper.hitMask;
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
        [_selectedURLs addObject:[[self.filteredFileURLs objectAtIndex:indexPath.row] fileURL]];
        BOOL anySelected = [tableView indexPathForSelectedRow] == nil ? NO : YES;
        for (UIBarButtonItem *item in _toolEditItems)
        {
            [(UIButton *)item.customView setEnabled:anySelected];
        }
    }
    else
    {
        [self.tab pushURL:[[self.filteredFileURLs objectAtIndex:indexPath.row] fileURL]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
    {
        [_selectedURLs removeObject:[[self.filteredFileURLs objectAtIndex:indexPath.row] fileURL]];
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
    if ([searchText length] == 0)
    {
        self.filterString = nil;
        return;
    }
    
    // Apply filter to filterController with .3 second debounce
    [_filterDebounceTimer invalidate];
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        self.filterString = searchText;
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
            [self.tabBarController setEditing:NO animated:YES];
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
            [self.tabBarController setEditing:NO animated:YES];
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
            [self.tabBarController setEditing:NO animated:YES];
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
            
            [self.tabBarController setEditing:NO animated:YES];
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
    directoryBrowser.URL = [[ACProject projectWithURL:self.directory] URL];
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
        [self.tabBarController setEditing:NO animated:YES];
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
        [self.tabBarController setEditing:NO animated:YES];
        [self _directoryBrowserDismissAction:sender];
    }];
}

@end
