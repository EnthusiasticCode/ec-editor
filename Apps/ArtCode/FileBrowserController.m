//
//  FileTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileBrowserController.h"
#import "SingleTabController.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"
#import "ArchiveUtilities.h"

#import "NewFileController.h"
#import "ProjectFolderBrowserController.h"
#import "MoveConflictController.h"

#import "RemoteDirectoryBrowserController.h"
#import "RemoteTransferController.h"

#import "NSString+PluralFormat.h"
#import "NSURL+Utilities.h"
#import "BezelAlert.h"

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"

#import "TopBarToolbar.h"
#import "TopBarTitleControl.h"

#import "ACProject.h"
#import "ACProjectItem.h"
#import "ACProjectFileSystemItem.h"
#import "ACProjectFolder.h"

#import "UIViewController+Utilities.h"
#import "NSArray+ScoreForAbbreviation.h"

static void *_currentProjectContext;
static void *_currentFolderContext;


@interface FileBrowserController () {
    ACProject *_currentObservedProject;
    
    NSArray *_filteredItems;
    NSArray *_filteredItemsHitMasks;
    
    UIPopoverController *_toolNormalAddPopover;
    UIActionSheet *_toolEditItemDuplicateActionSheet;
    UIActionSheet *_toolEditItemExportActionSheet;
    
    NSMutableArray *_selectedItems;
}

@property (nonatomic, strong) ACProjectFolder *currentFolder;

- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditDuplicateAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

- (void)_directoryBrowserCopyAction:(id)sender;
- (void)_directoryBrowserMoveAction:(id)sender;
- (void)_remoteDirectoryBrowserUploadAction:(id)sender;
- (void)_remoteDirectoryBrowserSyncAction:(id)sender;

@end

#pragma mark - Implementations
#pragma mark -

@implementation FileBrowserController

- (id)init
{
    self = [super initWithTitle:nil searchBarStaticOnTop:NO];
    if (!self)
        return nil;
    return self;
}

#pragma mark - Properties

@synthesize currentFolder = _currentFolder;
@synthesize bottomToolBarDetailLabel, bottomToolBarSyncButton;

- (void)setCurrentFolder:(ACProjectFolder *)value
{
    if (value == _currentFolder)
        return;
    
    [_currentObservedProject removeObserver:self forKeyPath:@"labelColor" context:&_currentProjectContext];
    [_currentObservedProject removeObserver:self forKeyPath:@"name" context:&_currentProjectContext];
    _currentObservedProject = nil;

    [_currentFolder removeObserver:self forKeyPath:@"children" context:&_currentFolderContext];
    _currentFolder = value;
    [_currentFolder addObserver:self forKeyPath:@"children" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&_currentFolderContext];
    
    // Add observer for project to update tile if we are showing the root folder
    if (_currentFolder.parentFolder == nil)
    {
        _currentObservedProject = self.artCodeTab.currentProject;
        [_currentObservedProject addObserver:self forKeyPath:@"labelColor" options:NSKeyValueObservingOptionNew context:&_currentProjectContext];
        [_currentObservedProject addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:&_currentProjectContext];
    }
}

- (NSArray *)filteredItems {
    if (!_filteredItems) {
        if ([self.searchBar.text length]) {
            NSArray *hitMasks = nil;
            _filteredItems = [self.currentFolder.children sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(ACProjectFileSystemItem *element) {
                return element.name;
            }];
            _filteredItemsHitMasks = hitMasks;
            if ([_filteredItems count] == 0)
                self.infoLabel.text = @"No items in this folder match the filter";
            else
                self.infoLabel.text = [NSString stringWithFormat:@"Showing %u filtered items out of %u", [_filteredItems count], [self.currentFolder.children count]];
        } else {
            _filteredItems = self.currentFolder.children;
            _filteredItemsHitMasks = nil;
            if ([_filteredItems count] == 0)
                self.infoLabel.text = @"This folder has no items";
            else
                self.infoLabel.text = [NSString stringWithFormatForSingular:@"One item in this folder" plural:@"%u items in this folder" count:[_filteredItems count]];
        }
    }
    return _filteredItems;
}

- (void)invalidateFilteredItems
{
    _filteredItems = nil;
    _filteredItemsHitMasks = nil;
}

#pragma mark - ArtCodeTab Category

- (void)setArtCodeTab:(ArtCodeTab *)artCodeTab
{
    [super setArtCodeTab:artCodeTab];
    
    ECASSERT(self.artCodeTab.currentItem.type == ACPFolder || !self.artCodeTab.currentItem);
    if (self.artCodeTab.currentItem)
        self.currentFolder = (ACProjectFolder *)self.artCodeTab.currentItem;
    else
        self.currentFolder = self.artCodeTab.currentProject.contentsFolder;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    // Load the bottom toolbar
    [[NSBundle mainBundle] loadNibNamed:@"FileBrowserBottomToolBar" owner:self options:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Customize subviews
    self.searchBar.placeholder = @"Filter files in this folder";
    
    // Preparing tool items array changed in set editing
    self.toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Duplicate"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDuplicateAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)], nil];
    
    self.toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)]];
}

- (void)viewDidUnload
{
    _toolNormalAddPopover = nil;
    
    _toolEditItemExportActionSheet = nil;
    _toolEditItemDuplicateActionSheet = nil;
    
    [self setBottomToolBarDetailLabel:nil];
    [self setBottomToolBarSyncButton:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [_selectedItems removeAllObjects];
    
//    [self invalidateFilteredItems];
    [super viewWillAppear:animated];
    
    // Hide sync button if no remotes
    self.bottomToolBarSyncButton.hidden = [self.artCodeTab.currentProject.remotes count] == 0;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.currentFolder = nil;
    [super viewDidDisappear:animated];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [_selectedItems removeAllObjects];
    [super setEditing:editing animated:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &_currentProjectContext)
    {
        [self.singleTabController updateDefaultToolbarTitle];
    }
    else if (context == &_currentFolderContext)
    {
        [self invalidateFilteredItems];
        [self.tableView reloadData];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc
{
    [_currentObservedProject removeObserver:self forKeyPath:@"labelColor" context:&_currentProjectContext];
    [_currentObservedProject removeObserver:self forKeyPath:@"name" context:&_currentProjectContext];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tView cellForRowAtIndexPath:indexPath];
    
    // Configure the cell
    ACProjectFileSystemItem *fileItem = [self.filteredItems objectAtIndex:indexPath.row];
    
    if (fileItem.type == ACPFolder)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[fileItem.name pathExtension]];
    
    cell.textLabel.text = fileItem.name;
    cell.textLabelHighlightedCharacters = _filteredItemsHitMasks ? [_filteredItemsHitMasks objectAtIndex:indexPath.row] : nil;
    
    // Side effect. Select this row if present in the selected urls array to keep selection persistent while filtering
    if ([_selectedItems containsObject:fileItem])
        [tView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    if (self.isEditing) {
        if (!_selectedItems)
            _selectedItems = [NSMutableArray new];
        [_selectedItems addObject:[self.filteredItems objectAtIndex:indexPath.row]];
    } else {
        [self.artCodeTab pushURL:[[self.filteredItems objectAtIndex:indexPath.row] artCodeURL]];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
    if (self.isEditing)
    {
        [_selectedItems removeObject:[self.filteredItems objectAtIndex:indexPath.row]];
    }
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == _toolEditDeleteActionSheet)
    {
        if (buttonIndex == actionSheet.destructiveButtonIndex) // Delete
        {
            self.loading = YES;
            [_selectedItems makeObjectsPerformSelector:@selector(remove)];
            self.loading = NO;
            [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File deleted" plural:@"%u files deleted" count:[_selectedItems count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
            [self setEditing:NO animated:YES];
        }
    }
    else if (actionSheet == _toolEditItemDuplicateActionSheet)
    {
        if (buttonIndex == 0) // Copy
        {
            ProjectFolderBrowserController *directoryBrowser = [ProjectFolderBrowserController new];
            directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserCopyAction:)];
            directoryBrowser.currentFolder = self.artCodeTab.currentProject.contentsFolder;
            [self modalNavigationControllerPresentViewController:directoryBrowser];
        }
        else if (buttonIndex == 1) // Duplicate
        {
            self.loading = YES;
            NSInteger selectedItemsCount = [_selectedItems count];
            __block NSInteger duplicated = 0;
            [_selectedItems enumerateObjectsUsingBlock:^(ACProjectFileSystemItem *item, NSUInteger idx, BOOL *stop) {
                [item duplicateWithCompletionHandler:^(ACProjectFileSystemItem *duplicate, NSError *error) {
                    if (++duplicated == selectedItemsCount) {
                        self.loading = NO;
                        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File duplicated" plural:@"%u files duplicated" count:selectedItemsCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
                    }
                }];
            }];
            [self setEditing:NO animated:YES];
        }
    }
    else if (actionSheet == _toolEditItemExportActionSheet)
    {
        if (buttonIndex == 0) // Move
        {
            ProjectFolderBrowserController *directoryBrowser = [ProjectFolderBrowserController new];
            directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Move" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserMoveAction:)];
            directoryBrowser.currentFolder = self.artCodeTab.currentProject.contentsFolder;
            [self modalNavigationControllerPresentViewController:directoryBrowser];
        }
        else if (buttonIndex == 1) // Upload
        {
            NSInteger remoteCount = [self.artCodeTab.currentProject.remotes count];
            if (remoteCount == 0)
            {
                // No remotes message 
                [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"No remotes present" imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
            }
            else if (remoteCount == 1)
            {
                // Show only remote in modal
                RemoteDirectoryBrowserController *uploadController = [RemoteDirectoryBrowserController new];
                uploadController.artCodeTab = self.artCodeTab;
                uploadController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Upload" style:UIBarButtonItemStyleDone target:self action:@selector(_remoteDirectoryBrowserUploadAction:)];
                [self modalNavigationControllerPresentViewController:uploadController];
            }
            else {
                // TODO Show remote selection in modal
            }
        }
        else if (buttonIndex == 2) // iTunes
        {
            self.loading = YES;
            NSInteger selectedItemsCount = [_selectedItems count];
            __block NSInteger processed = 0;
            [_selectedItems enumerateObjectsUsingBlock:^(ACProjectFileSystemItem *item, NSUInteger idx, BOOL *stop) {
                [item publishContentsToURL:[[NSURL applicationDocumentsDirectory] URLByAppendingPathComponent:item.name] completionHandler:^(NSError *error) {
                    if (++processed == selectedItemsCount) {
                        self.loading = NO;
                        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"File exported" plural:@"%u files exported" count:selectedItemsCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
                    }
                }];
            }];
            [self setEditing:NO animated:YES];
        }
        else if (buttonIndex == 3) // Mail
        {
            NSURL *tempDirecotryURL = [NSURL temporaryDirectory];
            
            // Compressing files to export
            self.loading = YES;
            NSInteger selectedItemsCount = [_selectedItems count];
            __block NSInteger processed = 0;
            // Create temporary directory to compress
            NSURL *directoryToZipURL = [tempDirecotryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@ Files", self.artCodeTab.currentProject.name]];
            [[NSFileManager defaultManager] createDirectoryAtURL:directoryToZipURL withIntermediateDirectories:YES attributes:nil error:NULL];
            // Add files to directory to zip
            [_selectedItems enumerateObjectsUsingBlock:^(ACProjectFileSystemItem *item, NSUInteger idx, BOOL *stop) {
                [item publishContentsToURL:[directoryToZipURL URLByAppendingPathComponent:item.name] completionHandler:^(NSError *error) {
                    if (++processed == selectedItemsCount) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            // Compress directory
                            NSURL *archiveToSendURL = [directoryToZipURL URLByAppendingPathExtension:@"zip"];
                            [ArchiveUtilities compressDirectoryAtURL:directoryToZipURL toArchive:archiveToSendURL];
                            // Switch to main thread to show mail composer
                            dispatch_async(dispatch_get_main_queue(), ^{
                                // Create mail composer
                                MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];
                                mailComposer.mailComposeDelegate = self;
                                mailComposer.navigationBar.barStyle = UIBarStyleDefault;
                                mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
                                
                                // Add attachement
                                [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:archiveToSendURL] mimeType:@"application/zip" fileName:[archiveToSendURL lastPathComponent]];
                                
                                // Add precompiled mail fields
                                [mailComposer setSubject:[NSString stringWithFormat:@"%@ exported files", self.artCodeTab.currentProject.name]];
                                [mailComposer setMessageBody:@"<br/><p>Open this file with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained project.</p>" isHTML:YES];

                                // Present mail composer
                                [self presentViewController:mailComposer animated:YES completion:nil];
                                [mailComposer.navigationBar.topItem.leftBarButtonItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
                                self.loading = NO;
                            });
                        });
                    }
                }];
            }];
            [self setEditing:NO animated:YES];
        }
    }
}

#pragma mark - Mail composer Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if (result == MFMailComposeResultSent)
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Mail sent" imageNamed:BezelAlertOkIcon displayImmediatly:YES];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)_toolNormalAddAction:(id)sender {
    if (!_toolNormalAddPopover)
    {
        UINavigationController *popoverViewController = (UINavigationController *)[[UIStoryboard storyboardWithName:@"NewFilePopover" bundle:nil] instantiateInitialViewController];
        popoverViewController.artCodeTab = self.artCodeTab;
        [popoverViewController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        
        _toolNormalAddPopover = [[UIPopoverController alloc] initWithContentViewController:popoverViewController];
        _toolNormalAddPopover.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
        popoverViewController.presentingPopoverController = _toolNormalAddPopover;
    }
    [_toolNormalAddPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)_toolEditExportAction:(id)sender {
    if (!_toolEditItemExportActionSheet)
    {
        _toolEditItemExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Move to new location", @"Upload to remote", @"Export to iTunes", ([MFMailComposeViewController canSendMail] ? @"Send via E-Mail" : nil), nil];
        _toolEditItemExportActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolEditItemExportActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditDuplicateAction:(id)sender {
    if (!_toolEditItemDuplicateActionSheet)
    {
        _toolEditItemDuplicateActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Copy to new location", @"Duplicate", nil];
        _toolEditItemDuplicateActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolEditItemDuplicateActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

#pragma mark Modal actions

- (void)modalNavigationControllerDismissAction:(id)sender {
    if ([_modalNavigationController.visibleViewController isKindOfClass:[RemoteTransferController class]] && ![(RemoteTransferController *)_modalNavigationController.visibleViewController isTransferFinished])
    {
        [(RemoteTransferController *)_modalNavigationController.visibleViewController cancelCurrentTransfer];
    }
    else
    {
        [self setEditing:NO animated:YES];
        [super modalNavigationControllerDismissAction:sender];
    }
}

- (void)_directoryBrowserCopyAction:(id)sender {
    // Retrieve URL to move to
    ProjectFolderBrowserController *directoryBrowser = (ProjectFolderBrowserController *)_modalNavigationController.topViewController;
    ACProjectFolder *moveFolder = directoryBrowser.selectedFolder;
    
    // Initialize conflict controller
    MoveConflictController *conflictController = [[MoveConflictController alloc] init];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserDismissAction:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    conflictController.navigationItem.leftBarButtonItem = cancelItem;
    
    // Start copy
    [conflictController moveItems:[_selectedItems copy] toFolder:moveFolder usingBlock:^(ACProjectFileSystemItem *item) {
        [item copyToFolder:moveFolder completionHandler:nil];
    } completion:^{
        [self setEditing:NO animated:YES];
        [self modalNavigationControllerDismissAction:sender];
    }];
}

- (void)_directoryBrowserMoveAction:(id)sender {
    // Retrieve URL to move to
    ProjectFolderBrowserController *directoryBrowser = (ProjectFolderBrowserController *)_modalNavigationController.topViewController;
    ACProjectFolder *moveFolder = directoryBrowser.selectedFolder;
    
    // Initialize conflict controller
    MoveConflictController *conflictController = [[MoveConflictController alloc] init];
    [self modalNavigationControllerPresentViewController:conflictController];

    // Start moving
    [conflictController moveItems:[_selectedItems copy] toFolder:moveFolder usingBlock:^(ACProjectFileSystemItem *item) {
        [item moveToFolder:moveFolder completionHandler:nil];
    } completion:^{
        [self setEditing:NO animated:YES];
        [self modalNavigationControllerDismissAction:sender];
    }];
}

- (void)_remoteDirectoryBrowserUploadAction:(id)sender {
    // Retrieve remote URL to upload to
    RemoteDirectoryBrowserController *remoteDirectoryBrowser = (RemoteDirectoryBrowserController *)_modalNavigationController.topViewController;
    NSURL *remoteURL = remoteDirectoryBrowser.selectedURL;
    
    // Initialize transfer/conflict controller
    RemoteTransferController *remoteTransferController = [RemoteTransferController new];
    [self modalNavigationControllerPresentViewController:remoteTransferController];
    
    // Start upload
    [remoteTransferController uploadProjectItems:[_selectedItems copy] toConnection:remoteDirectoryBrowser.connection path:remoteURL.path completion:^(id<CKConnection> connection, NSError *error) {
        [self setEditing:NO animated:YES];
        [self modalNavigationControllerDismissAction:sender];
    }];
}

- (IBAction)syncAction:(id)sender {
    if ([self.artCodeTab.currentProject.remotes count] == 1) {
        // Show only remote in modal
        RemoteDirectoryBrowserController *syncController = [RemoteDirectoryBrowserController new];
        syncController.artCodeTab = self.artCodeTab;
        syncController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Sync" style:UIBarButtonItemStyleDone target:self action:@selector(_remoteDirectoryBrowserSyncAction:)];
        [self modalNavigationControllerPresentViewController:syncController];
    } else {
        // TODO show remote's selection
    }
}

- (void)_remoteDirectoryBrowserSyncAction:(id)sender {
    // Retrieve remote URL to upload to
    RemoteDirectoryBrowserController *remoteDirectoryBrowser = (RemoteDirectoryBrowserController *)_modalNavigationController.topViewController;
    NSURL *remoteURL = remoteDirectoryBrowser.selectedURL;
    
    // Initialize transfer/conflict controller
    RemoteTransferController *remoteTransferController = [RemoteTransferController new];
    [self modalNavigationControllerPresentViewController:remoteTransferController];
    
    // Start sync
    [remoteTransferController synchronizeLocalProjectFolder:self.currentFolder withConnection:remoteDirectoryBrowser.connection path:remoteURL.path options:nil completion:^(id<CKConnection> connection, NSError *error) {
        [self modalNavigationControllerDismissAction:sender];
    }];
}

@end
