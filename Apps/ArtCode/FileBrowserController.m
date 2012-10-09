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
#import "FolderBrowserController.h"
#import "MoveConflictController.h"
#import "RenameController.h"

#import "ExportRemotesListController.h"
#import "RemoteDirectoryBrowserController.h"
#import "RemoteTransferController.h"

#import "NSString+PluralFormat.h"
#import "NSURL+Utilities.h"
#import "BezelAlert.h"

#import "ArtCodeLocation.h"
#import "ArtCodeRemote.h"
#import "ArtCodeTab.h"
#import "FileSystemItem.h"

#import "TopBarToolbar.h"
#import "TopBarTitleControl.h"

#import "ArtCodeProject.h"

#import "UIViewController+Utilities.h"
#import "NSFileCoordinator+CoordinatedFileManagement.h"

#import "CodeFileController.h"

#import <QuickLook/QuickLook.h>

@interface FileBrowserController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate>

- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditDuplicateAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

- (void)_directoryBrowserCopyAction:(id)sender;
- (void)_directoryBrowserMoveAction:(id)sender;
- (void)_remoteBrowserWithRightButton:(UIBarButtonItem *)rightButton;
- (void)_remoteDirectoryBrowserUploadAction:(id)sender;
- (void)_remoteDirectoryBrowserSyncAction:(id)sender;

- (void)_previewFile:(NSURL *)fileURL;
- (NSArray *)_previewItems;
- (void)_clearPreviewItems;

@end

#pragma mark -

@interface FilePreviewItem : NSObject <QLPreviewItem>

+ (id)filePreviewItemWithFileURL:(NSURL *)fileURL;

@end

#pragma mark - Implementations
#pragma mark -

@implementation FileBrowserController {
  UIPopoverController *_toolNormalAddPopover;
  UIActionSheet *_toolEditItemDuplicateActionSheet;
  UIActionSheet *_toolEditItemExportActionSheet;
  
  NSMutableArray *_selectedItems;
  NSMutableArray *_previewItems;
}

- (id)init
{
  self = [super initWithTitle:nil searchBarStaticOnTop:NO];
  if (!self)
    return nil;
  
  // RAC
  __weak FileBrowserController *weakSelf = self;
  __block RACDisposable *filteredItemsBindingDisposable = nil;
  
  [RACAble(self.artCodeTab.currentLocation.url) subscribeNext:^(NSURL *url) {
    FileBrowserController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    [[FileSystemItem readItemAtURL:url] subscribeNext:^(FileSystemItem *directory) {
      FileBrowserController *anotherStrongSelf = weakSelf;
      if (!anotherStrongSelf) {
        return;
      }
      // TODO: not quite sure this is needed, test it when directory auto updating is in
      [filteredItemsBindingDisposable dispose];
      filteredItemsBindingDisposable = [anotherStrongSelf rac_deriveProperty:RAC_KEYPATH(anotherStrongSelf, filteredItems) from:[directory childrenFilteredByAbbreviation:anotherStrongSelf.searchBarTextSubject]];
    }];
  }];
  [RACAble(self.filteredItems) subscribeNext:^(NSArray *items) {
    FileBrowserController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (strongSelf.searchBar.text.length) {
      if (items.count == 0) {
        strongSelf.infoLabel.text = L(@"No items in this folder match the filter.");
      } else {
        strongSelf.infoLabel.text = [NSString stringWithFormat:L(@"Showing %u filtered items"), items.count];
      }
    } else {
      if (items.count == 0) {
        strongSelf.infoLabel.text = L(@"This folder has no items. Use the + button to add a new one.");
      } else {
        strongSelf.infoLabel.text = [NSString stringWithFormatForSingular:L(@"One item in this folder.") plural:L(@"%u items in this folder.") count:items.count];
      }
    }
  }];

  return self;
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
  [super viewWillAppear:animated];
    
  // Hide sync button if no remotes
  self.bottomToolBarSyncButton.hidden = [self.artCodeTab.currentLocation.project.remotes count] == 0;
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
  RACTuple *item = [self.filteredItems objectAtIndex:indexPath.row];
  NSURL *itemURL = item.first;
  
  cell.textLabel.text = itemURL.lastPathComponent;
  cell.textLabelHighlightedCharacters = item.second;
  
  if ([itemURL isDirectory]) {
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  } else {
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[itemURL pathExtension]];
    cell.accessoryType = UITableViewCellAccessoryNone;
  }
    // Side effect. Select this row if present in the selected urls array to keep selection persistent while filtering
  if ([_selectedItems containsObject:itemURL])
    [tView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  if (self.isEditing) {
    if (!_selectedItems)
      _selectedItems = [[NSMutableArray alloc] init];
    [_selectedItems addObject:[self.filteredItems objectAtIndex:indexPath.row]];
  } else {
    NSURL *fileURL = [[self.filteredItems objectAtIndex:indexPath.row] first];
    if ([fileURL isDirectory]) {
      [self.artCodeTab pushFileURL:fileURL withProject:self.artCodeTab.currentLocation.project];
    }else if ([CodeFileController canDisplayFileInCodeView:fileURL]) {
      [self.artCodeTab pushFileURL:fileURL withProject:self.artCodeTab.currentLocation.project];
    } else {
      FilePreviewItem *item = [FilePreviewItem filePreviewItemWithFileURL:fileURL];
      if ([QLPreviewController canPreviewItem:item]) {
        [self _previewFile:fileURL];
      }
    }
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

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
  return [[self _previewItems] count];
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
  return [[self _previewItems] objectAtIndex:index];
}

#pragma mark - QLPreviewControllerDelegate

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
  [self _clearPreviewItems];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (actionSheet == _toolEditDeleteActionSheet)
  {
    if (buttonIndex == actionSheet.destructiveButtonIndex) // Delete
    {
      [NSFileCoordinator coordinatedDeleteItemsAtURLs:_selectedItems completionHandler:^(NSError *error) {
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File deleted") plural:L(@"%u files deleted") count:[_selectedItems count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
      }];
      [self setEditing:NO animated:YES];
    }
  }
  else if (actionSheet == _toolEditItemDuplicateActionSheet)
  {
    if (buttonIndex == 0) // Copy
    {
      FolderBrowserController *directoryBrowser = [[FolderBrowserController alloc] init];
      directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Copy") style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserCopyAction:)];
      directoryBrowser.currentFolderURL = self.artCodeTab.currentLocation.project.fileURL;
      [self modalNavigationControllerPresentViewController:directoryBrowser];
    }
    else if (buttonIndex == 1) // Duplicate
    {
      self.loading = YES;
      NSInteger selectedItemsCount = [_selectedItems count];
      [NSFileCoordinator coordinatedDuplicateItemsAtURLs:_selectedItems completionHandler:^(NSError *error) {
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File duplicated") plural:L(@"%u files duplicated") count:selectedItemsCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
      }];
      [self setEditing:NO animated:YES];
    }
  }
  else if (actionSheet == _toolEditItemExportActionSheet)
  {
    switch (buttonIndex) {
      case 0: // Rename
      {
        if (_selectedItems.count != 1) {
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Select a single file to rename") imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
          break;
        }
        RenameController *renameController = [[RenameController alloc] initWithRenameItemAtURL:[[_selectedItems objectAtIndex:0] first] completionHandler:^(NSUInteger renamedCount, NSError *err) {
          [self modalNavigationControllerDismissAction:nil];
          if (err || renamedCount == 0) {
            [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Can not rename") imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
          } else {
            // Show alert to inform of successful rename
            if (renamedCount == 1) {
              [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Item renamed") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
            } else {
              [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormat:L(@"%u items renamed"), renamedCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
            }
          }
        }];
        [self modalNavigationControllerPresentViewController:renameController];
      } break;
        
      case 1: // Move
      {
        FolderBrowserController *directoryBrowser = [[FolderBrowserController alloc] init];
        directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Move") style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserMoveAction:)];
        directoryBrowser.currentFolderURL = self.artCodeTab.currentLocation.project.fileURL;
        [self modalNavigationControllerPresentViewController:directoryBrowser];
      } break;
        
      case 2: // Upload
      {
        [self _remoteBrowserWithRightButton:[[UIBarButtonItem alloc] initWithTitle:L(@"Upload") style:UIBarButtonItemStyleDone target:self action:@selector(_remoteDirectoryBrowserUploadAction:)]];
      } break;
        
      case 3: // iTunes
      {
        self.loading = YES;
        NSInteger selectedItemsCount = [_selectedItems count];
        [NSFileCoordinator coordinatedCopyItemsAtURLs:_selectedItems toURL:[NSURL applicationDocumentsDirectory] completionHandler:^(NSError *error) {
          self.loading = NO;
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File exported") plural:L(@"%u files exported") count:selectedItemsCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
        }];
        [self setEditing:NO animated:YES];
      } break;
        
      case 4: // Mail
      {
        NSURL *temporaryDirectory = [NSURL temporaryDirectory];
        NSURL *archiveURL = [[temporaryDirectory URLByAppendingPathComponent:[NSString stringWithFormat:L(@"%@ Files"), self.artCodeTab.currentLocation.project.name]] URLByAppendingPathExtension:@"zip"];
        
        // Compressing files to export
        self.loading = YES;
        
        [ArchiveUtilities coordinatedCompressionOfFilesAtURLs:_selectedItems toArchiveAtURL:archiveURL renameIfNeeded:NO completionHandler:^(NSError *error, NSURL *newURL) {
          // Create mail composer
          MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
          mailComposer.mailComposeDelegate = self;
          mailComposer.navigationBar.barStyle = UIBarStyleDefault;
          mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
          
          // Add attachement
          [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:archiveURL] mimeType:@"application/zip" fileName:[archiveURL lastPathComponent]];
          
          // Remove temporary folder
          [NSFileCoordinator coordinatedDeleteItemsAtURLs:[NSArray arrayWithObject:temporaryDirectory] completionHandler:nil];
          
          // Add precompiled mail fields
          [mailComposer setSubject:[NSString stringWithFormat:L(@"%@ exported files"), self.artCodeTab.currentLocation.project.name]];
          [mailComposer setMessageBody:L(@"<br/><p>Open this file with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained project.</p>") isHTML:YES];
          
          // Present mail composer
          [self presentViewController:mailComposer animated:YES completion:nil];
          [mailComposer.navigationBar.topItem.leftBarButtonItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
          self.loading = NO;
        }];
        
        [self setEditing:NO animated:YES];
      } break;
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
    _toolNormalAddPopover.popoverBackgroundViewClass = [ImagePopoverBackgroundView class];
    popoverViewController.presentingPopoverController = _toolNormalAddPopover;
  }
  [(UINavigationController *)_toolNormalAddPopover.contentViewController popToRootViewControllerAnimated:NO];
  [_toolNormalAddPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)_toolEditExportAction:(id)sender {
  if (!_toolEditItemExportActionSheet)
  {
    _toolEditItemExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Rename"), L(@"Move to new location"), L(@"Upload to remote"), L(@"Export to iTunes"), ([MFMailComposeViewController canSendMail] ? L(@"Send via E-Mail") : nil), nil];
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
  FolderBrowserController *directoryBrowser = (FolderBrowserController *)_modalNavigationController.topViewController;
  NSURL *moveFolderURL = directoryBrowser.selectedFolderURL;
  
  // Initialize conflict controller
  MoveConflictController *conflictController = [[MoveConflictController alloc] init];
  [self modalNavigationControllerPresentViewController:conflictController];
  
  // Start copy
  NSArray *items = [_selectedItems copy];
  [conflictController moveItems:items toFolder:moveFolderURL usingBlock:^(NSURL *itemURL) {
    if (![[NSFileManager defaultManager] copyItemAtURL:itemURL toURL:[moveFolderURL URLByAppendingPathComponent:itemURL.lastPathComponent] error:NULL]) {
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
  FolderBrowserController *directoryBrowser = (FolderBrowserController *)_modalNavigationController.topViewController;
  NSURL *moveFolderURL = directoryBrowser.selectedFolderURL;
  
  // Initialize conflict controller
  MoveConflictController *conflictController = [[MoveConflictController alloc] init];
  [self modalNavigationControllerPresentViewController:conflictController];
  
  // Start moving
  NSArray *items = [_selectedItems copy];
  [conflictController moveItems:items toFolder:moveFolderURL usingBlock:^(NSURL *itemURL) {
    [[NSFileManager defaultManager] moveItemAtURL:itemURL toURL:[moveFolderURL URLByAppendingPathComponent:itemURL.lastPathComponent] error:NULL];
  } completion:^{
    [self setEditing:NO animated:YES];
    [self modalNavigationControllerDismissAction:sender];
    if (items.count) {
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Files moved" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
    }
  }];
}

- (void)_remoteBrowserWithRightButton:(UIBarButtonItem *)rightButton {
  switch ([self.artCodeTab.currentLocation.project.remotes count]) {
    case 0: {
      // Show error
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"No remotes present") imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
      break;
    }
      
    case 1: {
      RemoteDirectoryBrowserController *syncController = [[RemoteDirectoryBrowserController alloc] init];
      syncController.remoteURL = [(ArtCodeRemote *)[self.artCodeTab.currentLocation.project.remotes objectAtIndex:0] url];
      syncController.navigationItem.rightBarButtonItem = rightButton;
      [self modalNavigationControllerPresentViewController:syncController];
      break;
    }
      
    default: {
      ExportRemotesListController *remotesListController = [[ExportRemotesListController alloc] init];
      remotesListController.remotes = self.artCodeTab.currentLocation.project.remotes;
      remotesListController.remoteSelectedBlock = ^(ExportRemotesListController *senderController, ArtCodeRemote *remote) {
        // Shows the remote directory browser
        RemoteDirectoryBrowserController *uploadController = [[RemoteDirectoryBrowserController alloc] init];
        uploadController.remoteURL = remote.url;
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
  RemoteTransferController *remoteTransferController = [[RemoteTransferController alloc] init];
  [self modalNavigationControllerPresentViewController:remoteTransferController];
  
  // Start upload
  [remoteTransferController uploadItemURLs:[_selectedItems copy] toConnection:remoteDirectoryBrowser.connection path:remoteURL.path completion:^(id<CKConnection> connection, NSError *error) {
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
  RemoteTransferController *remoteTransferController = [[RemoteTransferController alloc] init];
  [self modalNavigationControllerPresentViewController:remoteTransferController];
  
  // Start sync
  [remoteTransferController synchronizeLocalDirectoryURL:self.artCodeTab.currentLocation.url withConnection:remoteDirectoryBrowser.connection path:remoteURL.path options:nil completion:^(id<CKConnection> connection, NSError *error) {
    [self modalNavigationControllerDismissAction:sender];
  }];
}

- (void)_previewFile:(NSURL *)fileURL {
  QLPreviewController *previewer = [[QLPreviewController alloc] init];
  [previewer setDataSource:self];
  [previewer setCurrentPreviewItemIndex:[[self _previewItems] indexOfObjectPassingTest:^BOOL(FilePreviewItem *item, NSUInteger idx, BOOL *stop) {
    return [item.previewItemURL isEqual:fileURL];
  }]];
  [self presentModalViewController:previewer animated:YES];
}

- (NSArray *)_previewItems {
  if (!_previewItems) {
    _previewItems = [NSMutableArray arrayWithCapacity:[[self filteredItems] count]];
    for (RACTuple *tuple in [self filteredItems]) {
      NSURL *fileURL = tuple.first;
      FilePreviewItem *item = [FilePreviewItem filePreviewItemWithFileURL:fileURL];
      if (![CodeFileController canDisplayFileInCodeView:fileURL] && [QLPreviewController canPreviewItem:item]) {
        [_previewItems addObject:item];
      }
    }
  }
  return _previewItems;
}

- (void)_clearPreviewItems {
  _previewItems = nil;
}

@end

#pragma mark -

@implementation FilePreviewItem {
  NSURL *_fileURL;
}

+ (id)filePreviewItemWithFileURL:(NSURL *)fileURL {
  FilePreviewItem *filePreviewItem = [[self alloc] init];
  filePreviewItem->_fileURL = fileURL;
  return filePreviewItem;
}

- (NSURL *)previewItemURL {
  return _fileURL;
}

@end
