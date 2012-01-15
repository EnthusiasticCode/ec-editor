//
//  ACFileTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileTableController.h"
#import "AppStyle.h"
#import "ACNewFileController.h"
#import <ECFoundation/ECDirectoryPresenter.h>
#import <ECFoundation/NSTimer+block.h>
#import <ECFoundation/NSString+ECAdditions.h>

#import "ACToolFiltersView.h"
#import "ACHighlightTableViewCell.h"

#import "ACTab.h"

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
    self.directoryPresenter.directory = _directory;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.directoryPresenter = [[ECDirectoryPresenter alloc] init];
    self.directoryPresenter.directory = self.directory;
    
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

#pragma mark - UITextField Delegate Methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Apply filter to filterController with .3 second debounce
    [_filterDebounceTimer invalidate];
    _filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        self.filterString = textField.text;
    } repeats:NO];

    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.filterString = nil;
    return YES;
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

@end
