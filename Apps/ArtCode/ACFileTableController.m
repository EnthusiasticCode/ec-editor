//
//  ACFileTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileTableController.h"
#import "AppStyle.h"
#import "ACNewFilePopoverController.h"
#import <ECFoundation/ECDirectoryPresenter.h>
#import <ECFoundation/NSTimer+block.h>
#import <ECFoundation/NSString+ECAdditions.h>

#import "ACToolFiltersView.h"

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
    UIPopoverController *_popover;
    NSTimer *filterDebounceTimer;
}
@property (nonatomic, strong) ECDirectoryPresenter *directoryPresenter;
@property (nonatomic, strong) NSString *filterString;
@property (nonatomic) NSUInteger filterCount;
@property (nonatomic, strong) NSMutableArray *filteredFileURLs;
- (void)directoryPresenterDidChangeFileURLs:(NSArray *)newFileURLs;
- (void)directoryPresenterDidInsertFileURLsAtIndexes:(NSIndexSet *)indexes inFileURLs:(NSArray *)newFileURLs;
- (void)directoryPresenterDidRemoveFileURLsAtIndexes:(NSIndexSet *)indexes fromFileURLs:(NSArray *)oldFileURLs;
@end

#pragma mark - Implementations
#pragma mark -

@implementation ACFileTableController {
    NSArray *extensions;
}

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
    // TODO: update it by moving objects around in the array instead of making a new one, so we can match the tableview animations to the movements
    NSMutableArray *newFilteredFileURLs = [NSMutableArray array];
    NSUInteger newFilterCount = 0;
    for (FilteredFileURLWrapper *wrapper in self.filteredFileURLs)
    {
        NSIndexSet *hitMask = nil;
        float score = [[wrapper.fileURL lastPathComponent] scoreForAbbreviation:filterString hitMask:&hitMask];
        if (score > 0.0)
            ++newFilterCount;
        wrapper.score = score;
        wrapper.hitMask = hitMask;
        [newFilteredFileURLs addObject:wrapper];
    }
    [newFilteredFileURLs sortUsingSelector:@selector(compare:)];
    self.filteredFileURLs = newFilteredFileURLs;
    self.filterCount = newFilterCount;
    [self.tableView reloadData];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // TODO Write hints in this view
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 0)];
    self.tableView.tableFooterView = footerView;
    
    extensions = [NSArray arrayWithObjects:@"h", @"m", @"hpp", @"cpp", @"mm", @"py", nil];
    
    [self setEditing:NO animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.directoryPresenter = [[ECDirectoryPresenter alloc] init];
    self.directoryPresenter.directory = self.directory;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.directoryPresenter = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    if (editing)
    {
        // TODO set editin toolbar items
    }
    else
    {  
        // Tool buttons for top bar
        self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithTitle:@"add" style:UIBarButtonItemStylePlain target:self action:@selector(toolButtonAction:)]];
    }
}

#pragma mark - TODO refactor: Tool Target Methods

//- (UIButton *)toolButton
//{
//    if (!toolButton)
//    {
//        toolButton = [UIButton new];
//        [toolButton addTarget:self action:@selector(toolButtonAction:) forControlEvents:UIControlEventTouchUpInside];
//        [toolButton setImage:[UIImage styleAddImageWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]] forState:UIControlStateNormal];
//        toolButton.adjustsImageWhenHighlighted = NO;
//    }
//    return toolButton;
//}

- (void)toolButtonAction:(id)sender
{
    // Removing the lazy loading could cause the old popover to be overwritten by the new one causing a dealloc while popover is visible
    if (!_popover)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewFilePopover" bundle:[NSBundle mainBundle]];
        ACNewFilePopoverController *popoverViewController = (ACNewFilePopoverController *)[storyboard instantiateInitialViewController];
//        popoverViewController.group = self.group;
        _popover = [[UIPopoverController alloc] initWithContentViewController:popoverViewController];
    }
    [_popover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filterCount;
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FileCellIdentifier = @"FileCell";
    
    UITableViewCell *cell = [tView dequeueReusableCellWithIdentifier:FileCellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FileCellIdentifier];        
    }
    
    // Configure the cell...
    NSString *fileName = [[[self.filteredFileURLs objectAtIndex:indexPath.row] fileURL] lastPathComponent];
    if (![fileName pathExtension])
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithSize:CGSizeMake(32, 32) 
                                                             color:[[fileName pathExtension] isEqualToString:@"h"] ? [UIColor styleFileRedColor] : [UIColor styleFileBlueColor]
                                                              text:[fileName pathExtension]];
    cell.textLabel.text = fileName;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
        return;
    [self.tab pushURL:[[self.filteredFileURLs objectAtIndex:indexPath.row] fileURL]];
}

#pragma mark - UITextField Delegate Methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Calculate filter string
    NSMutableString *filterString = [textField.text mutableCopy];
    [filterString replaceCharactersInRange:range withString:string];
    
    // Apply filter to filterController with .3 second debounce
    [filterDebounceTimer invalidate];
    filterDebounceTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 usingBlock:^(NSTimer *timer) {
        self.filterString = filterString;
    } repeats:NO];

    if ([textField.rightView isKindOfClass:[UIButton class]])
    {
        if ([filterString length])
            [(UIButton *)textField.rightView setSelected:YES];
        else
            [(UIButton *)textField.rightView setSelected:NO];            
    }
    
    return YES;
}

@end
