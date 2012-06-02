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

#import "ExportRemotesListController.h"
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
#import "ACProjectRemote.h"

#import "UIViewController+Utilities.h"
#import "NSArray+ScoreForAbbreviation.h"


@interface FileBrowserController () {
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
- (void)_remoteBrowserWithRightButton:(UIBarButtonItem *)rightButton;
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
  
  // Update current folder with current tab item
  [[RACAbleSelf(self.artCodeTab.currentItem) where:^BOOL(id x) {
    return [x isKindOfClass:[ACProjectFolder class]];
  }] toProperty:RAC_KEYPATH_SELF(self.currentFolder) onObject:self];
  
  // Update table view when current folder's children change
  [RACAbleSelf(self.currentFolder.children) subscribeNext:^(id x) {
    [self invalidateFilteredItems];
    [self.tableView reloadData];
  }];
  
  return self;
}

#pragma mark - Properties

@synthesize currentFolder = _currentFolder;
@synthesize bottomToolBarDetailLabel, bottomToolBarSyncButton;


- (NSArray *)filteredItems {
  if (!_filteredItems) {
    if ([self.searchBar.text length]) {
      NSArray *hitMasks = nil;
      _filteredItems = [self.currentFolder.children sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(ACProjectFileSystemItem *element) {
        return element.name;
      }];
      _filteredItemsHitMasks = hitMasks;
      if ([_filteredItems count] == 0)
        self.infoLabel.text = L(@"No items in this folder match the filter.");
      else
        self.infoLabel.text = [NSString stringWithFormat:L(@"Showing %u filtered items out of %u."), [_filteredItems count], [self.currentFolder.children count]];
    } else {
      _filteredItems = [self.currentFolder.children sortedArrayUsingComparator:^NSComparisonResult(ACProjectFileSystemItem *obj1, ACProjectFileSystemItem *obj2) {
        return [obj1.name compare:obj2.name];
      }];
      _filteredItemsHitMasks = nil;
      if ([_filteredItems count] == 0)
        self.infoLabel.text = L(@"This folder has no items. Use the + button to add a new one.");
      else
        self.infoLabel.text = [NSString stringWithFormatForSingular:L(@"One item in this folder.") plural:L(@"%u items in this folder.") count:[_filteredItems count]];
    }
  }
  return _filteredItems;
}

- (void)invalidateFilteredItems
{
  _filteredItems = nil;
  _filteredItemsHitMasks = nil;
}

#pragma mark - View lifecycle

- (void)loadView
{
  [super loadView];
  
  self.tableView.accessibilityIdentifier = @"file browser";
  
  // Load the bottom toolbar
  [[NSBundle mainBundle] loadNibNamed:@"FileBrowserBottomToolBar" owner:self options:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Customize subviews
  self.searchBar.placeholder = L(@"Filter files in this folder");
  
  // Preparing tool items array changed in set editing
  self.toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Duplicate"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDuplicateAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)], nil];
  [[self.toolEditItems objectAtIndex:0] setAccessibilityLabel:L(@"Export")];
  [[self.toolEditItems objectAtIndex:1] setAccessibilityLabel:L(@"Copy")];
  [[self.toolEditItems objectAtIndex:2] setAccessibilityLabel:L(@"Delete")];
  
  self.toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)]];
  [[self.toolNormalItems objectAtIndex:0] setAccessibilityLabel:L(@"Add file or folder")];
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

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tView cellForRowAtIndexPath:indexPath];
  
  // Configure the cell
  ACProjectFileSystemItem *fileItem = [self.filteredItems objectAtIndex:indexPath.row];
  
  if (fileItem.type == ACPFolder) {
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  } else {
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[fileItem.name pathExtension]];
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
  
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
      for (ACProjectFileSystemItem *item in _selectedItems) {
        [item.parentFolder removeChildItem:item];
      }
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File deleted") plural:L(@"%u files deleted") count:[_selectedItems count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
      [self setEditing:NO animated:YES];
    }
  }
  else if (actionSheet == _toolEditItemDuplicateActionSheet)
  {
    if (buttonIndex == 0) // Copy
    {
      ProjectFolderBrowserController *directoryBrowser = [ProjectFolderBrowserController new];
      directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Copy") style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserCopyAction:)];
      directoryBrowser.currentFolder = self.artCodeTab.currentProject.contentsFolder;
      [self modalNavigationControllerPresentViewController:directoryBrowser];
    }
    else if (buttonIndex == 1) // Duplicate
    {
      self.loading = YES;
      NSInteger selectedItemsCount = [_selectedItems count];
      [_selectedItems enumerateObjectsUsingBlock:^(ACProjectFileSystemItem *item, NSUInteger idx, BOOL *stop) {
        [item copyToFolder:item.parentFolder renameTo:nil];
      }];
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File duplicated") plural:L(@"%u files duplicated") count:selectedItemsCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
      [self setEditing:NO animated:YES];
    }
  }
  else if (actionSheet == _toolEditItemExportActionSheet)
  {
    if (buttonIndex == 0) // Move
    {
      ProjectFolderBrowserController *directoryBrowser = [ProjectFolderBrowserController new];
      directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Move") style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserMoveAction:)];
      directoryBrowser.currentFolder = self.artCodeTab.currentProject.contentsFolder;
      [self modalNavigationControllerPresentViewController:directoryBrowser];
    }
    else if (buttonIndex == 1) // Upload
    {
      [self _remoteBrowserWithRightButton:[[UIBarButtonItem alloc] initWithTitle:L(@"Upload") style:UIBarButtonItemStyleDone target:self action:@selector(_remoteDirectoryBrowserUploadAction:)]];
    }
    else if (buttonIndex == 2) // iTunes
    {
      self.loading = YES;
      NSInteger selectedItemsCount = [_selectedItems count];
      __block NSInteger processed = 0;
      [_selectedItems enumerateObjectsUsingBlock:^(ACProjectFileSystemItem *item, NSUInteger idx, BOOL *stop) {
        [item publishContentsToURL:[[NSURL applicationDocumentsDirectory] URLByAppendingPathComponent:item.name] completionHandler:^(BOOL success) {
          if (++processed == selectedItemsCount) {
            self.loading = NO;
            [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File exported") plural:L(@"%u files exported") count:selectedItemsCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
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
      NSURL *directoryToZipURL = [tempDirecotryURL URLByAppendingPathComponent:[NSString stringWithFormat:L(@"%@ Files"), self.artCodeTab.currentProject.name]];
      [[NSFileManager defaultManager] createDirectoryAtURL:directoryToZipURL withIntermediateDirectories:YES attributes:nil error:NULL];
      // Add files to directory to zip
      [_selectedItems enumerateObjectsUsingBlock:^(ACProjectFileSystemItem *item, NSUInteger idx, BOOL *stop) {
        [item publishContentsToURL:[directoryToZipURL URLByAppendingPathComponent:item.name] completionHandler:^(BOOL success) {
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
                
                // Remote temporary folder
                [[NSFileManager defaultManager] removeItemAtURL:tempDirecotryURL error:NULL];
                
                // Add precompiled mail fields
                [mailComposer setSubject:[NSString stringWithFormat:L(@"%@ exported files"), self.artCodeTab.currentProject.name]];
                [mailComposer setMessageBody:L(@"<br/><p>Open this file with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained project.</p>") isHTML:YES];
                
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
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Mail sent") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
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
  [(UINavigationController *)_toolNormalAddPopover.contentViewController popToRootViewControllerAnimated:NO];
  [_toolNormalAddPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)_toolEditExportAction:(id)sender {
  if (!_toolEditItemExportActionSheet)
  {
    _toolEditItemExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Move to new location"), L(@"Upload to remote"), L(@"Export to iTunes"), ([MFMailComposeViewController canSendMail] ? L(@"Send via E-Mail") : nil), nil];
    _toolEditItemExportActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [_toolEditItemExportActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditDuplicateAction:(id)sender {
  if (!_toolEditItemDuplicateActionSheet)
  {
    _toolEditItemDuplicateActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Copy to new location"), L(@"Duplicate"), nil];
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
  [self modalNavigationControllerPresentViewController:conflictController];
  
  // Start copy
  NSArray *items = [_selectedItems copy];
  [conflictController moveItems:items toFolder:moveFolder usingBlock:^(ACProjectFileSystemItem *item) {
    ACProjectFileSystemItem *copy = [item copyToFolder:moveFolder renameTo:nil];
    if (!copy) {
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Error copying files" imageNamed:BezelAlertForbiddenIcon displayImmediatly:NO];
    };
  } completion:^{
    [self setEditing:NO animated:YES];
    [self modalNavigationControllerDismissAction:sender];
    if (items.count) {
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Files copied" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
    }
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
  NSArray *items = [_selectedItems copy];
  [conflictController moveItems:items toFolder:moveFolder usingBlock:^(ACProjectFileSystemItem *item) {
    [item moveToFolder:moveFolder renameTo:nil];
  } completion:^{
    [self setEditing:NO animated:YES];
    [self modalNavigationControllerDismissAction:sender];
    if (items.count) {
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Files moved" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
    }
  }];
}

- (void)_remoteBrowserWithRightButton:(UIBarButtonItem *)rightButton {
  switch ([self.artCodeTab.currentProject.remotes count]) {
    case 0: {
      // Show error
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"No remotes present") imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
      break;
    }
      
    case 1: {
      RemoteDirectoryBrowserController *syncController = [RemoteDirectoryBrowserController new];
      syncController.remote = (ACProjectRemote *)[self.artCodeTab.currentProject.remotes objectAtIndex:0];
      syncController.navigationItem.rightBarButtonItem = rightButton;
      [self modalNavigationControllerPresentViewController:syncController];
      break;
    }
      
    default: {
      ExportRemotesListController *remotesListController = [ExportRemotesListController new];
      remotesListController.remotes = self.artCodeTab.currentProject.remotes;
      remotesListController.remoteSelectedBlock = ^(ExportRemotesListController *senderController, ACProjectRemote *remote) {
        // Shows the remote directory browser
        RemoteDirectoryBrowserController *uploadController = [RemoteDirectoryBrowserController new];
        uploadController.remote = remote;
        uploadController.navigationItem.rightBarButtonItem = rightButton;
        [senderController.navigationController pushViewController:uploadController animated:YES];
      };
      [self modalNavigationControllerPresentViewController:remotesListController];
      break;
    }
  }
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
  [self _remoteBrowserWithRightButton:[[UIBarButtonItem alloc] initWithTitle:L(@"Sync") style:UIBarButtonItemStyleDone target:self action:@selector(_remoteDirectoryBrowserSyncAction:)]];
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
