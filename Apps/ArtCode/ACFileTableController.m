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
#import "ACColorSelectionControl.h"
#import "ACHighlightTableViewCell.h"

#import "ACNewFileController.h"
#import "ACDirectoryBrowserController.h"
#import "ACMoveConflictController.h"

#import <ECFoundation/NSTimer+block.h>
#import <ECFoundation/NSString+ECAdditions.h>
#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECUIKit/NSURL+URLDuplicate.h>
#import <ECUIKit/ECBezelAlert.h>

#import "ACTab.h"
#import "ACProject.h"
#import "ACTopBarToolbar.h"
#import "ACTopBarTitleControl.h"

#import "ACQuickBrowsersContainerController.h"
#import "ACQuickFileBrowserController.h"


@interface ACFileTableController () {
    UIButton *_projectColorLabelButton;
    UITextField *_projectTitleLabelTextField;
    UIPopoverController *_projectColorLabelPopover;
    
    NSArray *_toolNormalItems;
    NSArray *_toolEditItems;
    
    UIPopoverController *_toolNormalAddPopover;
    UIActionSheet *_toolEditItemDeleteActionSheet;
    UIActionSheet *_toolEditItemDuplicateActionSheet;
    UIActionSheet *_toolEditItemExportActionSheet;
    UINavigationController *_directoryBrowserNavigationController;
    
    NSTimer *_filterDebounceTimer;
    
    NSMutableArray *_selectedURLs;
    
    ECDirectoryPresenter *_directoryPresenter;
    ECSmartFilteredDirectoryPresenter *_openQuicklyPresenter;
    BOOL _isShowingOpenQuickly;
    
    UIPopoverController *_quickBrowsersPopover;
}

- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditDeleteAction:(id)sender;
- (void)_toolEditDuplicateAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

- (void)_directoryBrowserShowWithRightBarItem:(UIBarButtonItem *)rightItem;
- (void)_directoryBrowserDismissAction:(id)sender;
- (void)_directoryBrowserCopyAction:(id)sender;
- (void)_directoryBrowserMoveAction:(id)sender;

- (ECDirectoryPresenter *)_currentPresenter;

@end

#pragma mark - Implementations
#pragma mark -

@implementation ACFileTableController

#pragma mark - Properties

@synthesize directory = _directory, tab;

- (void)setDirectory:(NSURL *)directory
{
    if (directory == _directory)
        return;
    [self willChangeValueForKey:@"directory"];
    _directory = directory;
    _directoryPresenter = [[ECDirectoryPresenter alloc] initWithDirectoryURL:_directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    _openQuicklyPresenter = [[ECSmartFilteredDirectoryPresenter alloc] initWithDirectoryURL:_directory options:NSDirectoryEnumerationSkipsHiddenFiles];
    _directoryPresenter.delegate = self;
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
        searchBar.placeholder = @"Filter this folder files";
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
    
    _directoryPresenter = [[ECDirectoryPresenter alloc] initWithDirectoryURL:self.directory options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants];
    _directoryPresenter.delegate = self;
    
    _openQuicklyPresenter = [[ECSmartFilteredDirectoryPresenter alloc] initWithDirectoryURL:self.directory options:NSDirectoryEnumerationSkipsHiddenFiles];
    _openQuicklyPresenter.delegate = self;
    
    [_selectedURLs removeAllObjects];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    _directoryPresenter = nil;
    _openQuicklyPresenter = nil;
    _selectedURLs = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self willChangeValueForKey:@"editing"];
    
    [super setEditing:editing animated:animated];
    
    self.singleTabController.defaultToolbar.titleControl.backgroundButton.enabled = !editing;
    _projectColorLabelButton.enabled = _projectTitleLabelTextField.enabled = editing;
    
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

#pragma mark - Single tab content controller protocol methods

- (void)_projectColorLabelSelectionAction:(id)sender
{
    self.tab.currentProject.labelColor = [(ACColorSelectionControl *)sender selectedColor];
    [_projectColorLabelButton setImage:[UIImage styleProjectLabelImageWithSize:CGSizeMake(14, 22) color:self.tab.currentProject.labelColor] forState:UIControlStateNormal];
    [_projectColorLabelPopover dismissPopoverAnimated:YES];
}

- (void)_projectColorLabelAction:(id)sender
{
    if (!_projectColorLabelPopover)
    {
        ACColorSelectionControl *colorControl = [ACColorSelectionControl new];
        colorControl.colorCellsMargin = 2;
        colorControl.columns = 3;
        colorControl.rows = 2;
        colorControl.colors = [NSArray arrayWithObjects:
                               [UIColor colorWithRed:255./255. green:106./255. blue:89./255. alpha:1], 
                               [UIColor colorWithRed:255./255. green:184./255. blue:62./255. alpha:1], 
                               [UIColor colorWithRed:237./255. green:233./255. blue:68./255. alpha:1],
                               [UIColor colorWithRed:168./255. green:230./255. blue:75./255. alpha:1],
                               [UIColor colorWithRed:93./255. green:157./255. blue:255./255. alpha:1],
                               [UIColor styleForegroundColor], nil];
        [colorControl addTarget:self action:@selector(_projectColorLabelSelectionAction:) forControlEvents:UIControlEventTouchUpInside];
        
        UIViewController *viewController = [UIViewController new];
        viewController.contentSizeForViewInPopover = CGSizeMake(145, 90);
        viewController.view = colorControl;
        
        _projectColorLabelPopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
        _projectColorLabelPopover.popoverBackgroundViewClass = [ACShapePopoverBackgroundView class];
    }
    
    [_projectColorLabelPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (BOOL)singleTabController:(ACSingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(ACTopBarToolbar *)toolbar
{
    return YES;
}

- (void)singleTabController:(ACSingleTabController *)singleTabController titleControlAction:(id)sender
{
    if (!_quickBrowsersPopover)
    {
        ACQuickBrowsersContainerController *quickBrowserContainerController = [ACQuickBrowsersContainerController new];
        quickBrowserContainerController.contentSizeForViewInPopover = CGSizeMake(500, 500);
        quickBrowserContainerController.tab = self.tab;
        [quickBrowserContainerController setViewControllers:[NSArray arrayWithObjects:[ACQuickFileBrowserController new], nil] animated:NO];
        
        _quickBrowsersPopover = [[UIPopoverController alloc] initWithContentViewController:quickBrowserContainerController];
        quickBrowserContainerController.popoverController = _quickBrowsersPopover;
    }
    [_quickBrowsersPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (BOOL)singleTabController:(ACSingleTabController *)singleTabController setupDefaultToolbarTitleControl:(ACTopBarTitleControl *)titleControl
{
    BOOL isRoot = NO;
    NSString *projectName = [ACProject projectNameFromURL:self.tab.currentURL isProjectRoot:&isRoot];
    if (!isRoot)
    {
        return NO; // default behaviour
    }
    else
    {
        if (!_projectColorLabelButton)
        {
            _projectColorLabelButton  = [UIButton buttonWithType:UIButtonTypeCustom];
            _projectColorLabelButton.adjustsImageWhenDisabled = NO;
            [_projectColorLabelButton addTarget:self action:@selector(_projectColorLabelAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        [_projectColorLabelButton setImage:[UIImage styleProjectLabelImageWithSize:CGSizeMake(14, 22) color:self.tab.currentProject.labelColor] forState:UIControlStateNormal];
        [_projectColorLabelButton sizeToFit];
        _projectColorLabelButton.enabled = self.isEditing;
        
        if (!_projectTitleLabelTextField)
        {
            _projectTitleLabelTextField = [UITextField new];
            _projectTitleLabelTextField.delegate = self;
            _projectTitleLabelTextField.font = [UIFont boldSystemFontOfSize:20];
            _projectTitleLabelTextField.textColor = [UIColor whiteColor];
            _projectTitleLabelTextField.returnKeyType = UIReturnKeyDone;
        }
        _projectTitleLabelTextField.text = projectName;
        [_projectTitleLabelTextField sizeToFit];
        _projectTitleLabelTextField.enabled = self.isEditing;
        
        [titleControl setTitleFragments:[NSArray arrayWithObjects:_projectColorLabelButton, _projectTitleLabelTextField, nil] 
                        selectedIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
    }
    return YES;
}

#pragma mark - Text Field delefate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *projectName = [ACProject projectNameFromURL:self.tab.currentURL isProjectRoot:NULL];
    if ([textField.text length] == 0 || [projectName isEqualToString:textField.text])
        return;
    
#warning TODO check that the name is ok
    
    self.tab.currentProject.name = textField.text;
    
    // File coordination will care about changing the tab url and hence reload the controller
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self _currentPresenter].fileURLs count];
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
    NSURL *fileURL = [[self _currentPresenter].fileURLs objectAtIndex:indexPath.row];
    
    BOOL isDirecotry = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:[fileURL path] isDirectory:&isDirecotry];
    if (isDirecotry)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[fileURL pathExtension]];
    
    cell.highlightLabel.text = [fileURL lastPathComponent];
    
    if (_isShowingOpenQuickly)
    {
        cell.highlightLabel.highlightedBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
        cell.highlightLabel.highlightedCharacters = [_openQuicklyPresenter hitMaskForFileURL:fileURL];
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

#pragma mark - Directory Presenter Delegate

- (NSOperationQueue *)delegateOperationQueue
{
    return [NSOperationQueue mainQueue];
}

- (void)directoryPresenter:(ECDirectoryPresenter *)directoryPresenter didInsertFileURLsAtIndexes:(NSIndexSet *)insertIndexes removeFileURLsAtIndexes:(NSIndexSet *)removeIndexes changeFileURLsAtIndexes:(NSIndexSet *)changeIndexes
{
    if ((_isShowingOpenQuickly && directoryPresenter != _openQuicklyPresenter) || (!_isShowingOpenQuickly && directoryPresenter != _directoryPresenter))
        return;
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
        _openQuicklyPresenter.filterString = searchText;
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
    directoryBrowser.URL = self.tab.currentProject.URL;
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
        [self setEditing:NO animated:YES];
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
        [self setEditing:NO animated:YES];
        [self _directoryBrowserDismissAction:sender];
    }];
}

- (ECDirectoryPresenter *)_currentPresenter
{
    return _isShowingOpenQuickly ? _openQuicklyPresenter : _directoryPresenter;
}

@end
