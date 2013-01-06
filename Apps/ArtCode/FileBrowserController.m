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
#import "FileSystemItemCell.h"
#import "ArchiveUtilities.h"

#import "NewFileController.h"
#import "FolderBrowserController.h"
#import "MoveConflictController.h"
#import "RenameController.h"

#import "ExportRemotesListController.h"
#import "RemoteTransferController.h"

#import "NSString+PluralFormat.h"
#import "NSURL+Utilities.h"
#import "BezelAlert.h"

#import "ArtCodeLocation.h"
#import "ArtCodeRemote.h"
#import "ArtCodeTab.h"

#import "TopBarToolbar.h"
#import "TopBarTitleControl.h"

#import "ArtCodeProject.h"

#import "UIViewController+Utilities.h"
#import "FileSystemItem.h"

#import "CodeFileController.h"

#import <QuickLook/QuickLook.h>

@interface FileBrowserController () <QLPreviewControllerDataSource, QLPreviewControllerDelegate>

@property (nonatomic, strong) FileSystemDirectory *currentDirectory;
@property (nonatomic, strong) NSArray *previewItems;

- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditDuplicateAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

- (void)_directoryBrowserCopyAction:(id)sender;
- (void)_directoryBrowserMoveAction:(id)sender;

- (void)_previewFile:(NSURL *)fileURL;

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
}

- (id)init
{
  self = [super initWithTitle:nil searchBarStaticOnTop:NO];
  if (!self)
    return nil;
  
  // RAC
  @weakify(self);
	__block NSString *revealFileName = nil;
	__block NSIndexPath *scrollToIndexPath = nil;

	[[[RACAble(self.artCodeTab.currentLocation) flattenMap:^id(ArtCodeLocation *location) {
		revealFileName = [location.dataDictionary objectForKey:@"reveal"];
		return [FileSystemDirectory directoryWithURL:location.url];
	}] catchTo:RACSignal.empty] toProperty:@keypath(self.currentDirectory) onObject:self];
  
	[[[RACAble(self.currentDirectory) flattenMap:^(FileSystemDirectory *directory) {
		@strongify(self);
		return [directory childrenFilteredByAbbreviation:self.searchBarTextSubject];
	}] doNext:^(NSArray *items) {
		@strongify(self);
		// Should reveal a file
		if (revealFileName) {
			// TODO: Implement this
			NSLog(@"should reveal %@", revealFileName);
			revealFileName = nil;
		}
		// If the new items are more than the previous, find the first one inserted
		else if (self.filteredItems.count < items.count) {
			[self.filteredItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if ([obj first] != [items[idx] first]) {
					scrollToIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
					*stop = YES;
				}
			}];
		}
	}] toProperty:@keypath(self.filteredItems) onObject:self];
	
  [RACAble(self.filteredItems) subscribeNext:^(NSArray *items) {
    @strongify(self);
    [self.tableView reloadData];
		// Update info label text
    if (self.searchBar.text.length) {
      if (items.count == 0) {
        self.infoLabel.text = L(@"No items in this folder match the filter.");
      } else {
        self.infoLabel.text = [NSString stringWithFormat:L(@"Showing %u filtered items"), items.count];
      }
    } else {
      if (items.count == 0) {
        self.infoLabel.text = L(@"This folder has no items. Use the + button to add a new one.");
      } else {
        self.infoLabel.text = [NSString stringWithFormatForSingular:L(@"One item in this folder.") plural:L(@"%u items in this folder.") count:items.count];
      }
    }
		// Scroll the tableview to an added item
		if (scrollToIndexPath) {
			[self.tableView scrollToRowAtIndexPath:scrollToIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
			scrollToIndexPath = nil;
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
  self.toolEditItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Duplicate"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDuplicateAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)]];
  [(self.toolEditItems)[0] setAccessibilityLabel:L(@"Export")];
  [(self.toolEditItems)[1] setAccessibilityLabel:L(@"Copy")];
  [(self.toolEditItems)[2] setAccessibilityLabel:L(@"Delete")];
  
  self.toolNormalItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)]];
  [(self.toolNormalItems)[0] setAccessibilityLabel:L(@"Add file or folder")];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  
  FileSystemItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (!cell) {
    cell = [[FileSystemItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    cell.textLabel.backgroundColor = [UIColor clearColor];
  }
  
  // Configure the cell
  RACTuple *filteredItem = (self.filteredItems)[indexPath.row];
  FileSystemItem *item = filteredItem.first;
  NSIndexSet *hitMask = filteredItem.second;
  cell.item = item;
  cell.hitMask = hitMask;
  
  // Side effect. Select this row if present in the selected urls array to keep selection persistent while filtering
  if ([_selectedItems containsObject:item])
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
  FileSystemItem *item = [(self.filteredItems)[indexPath.row] first];
  if (self.isEditing) {
    if (!_selectedItems)
      _selectedItems = [[NSMutableArray alloc] init];
    [_selectedItems addObject:item];
  } else {
    @weakify(self);
    [[[RACSignal combineLatest:@[item.url, item.type]] take:1] subscribeNext:^(RACTuple *xs) {
      @strongify(self);
      NSURL *fileURL = xs.first;
      NSString *type = xs.second;
      if (type == NSURLFileResourceTypeDirectory) {
        [self.artCodeTab pushFileURL:fileURL withProject:self.artCodeTab.currentLocation.project];
      } else if ([CodeFileController canDisplayFileInCodeView:fileURL]) {
        [self.artCodeTab pushFileURL:fileURL withProject:self.artCodeTab.currentLocation.project];
      } else {
        FilePreviewItem *item = [FilePreviewItem filePreviewItemWithFileURL:fileURL];
        if ([QLPreviewController canPreviewItem:item]) {
          [self _previewFile:fileURL];
        }
      }
    }];
  }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
  if (self.isEditing) {
    [_selectedItems removeObject:[(self.filteredItems)[indexPath.row] first]];
  }
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
  return [self.previewItems count];
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
  return self.previewItems[index];
}

#pragma mark - QLPreviewControllerDelegate

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
	self.previewItems = nil;
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (actionSheet == _toolEditDeleteActionSheet) {
    if (buttonIndex == actionSheet.destructiveButtonIndex) { // Delete
      NSUInteger selectedItemsCount = [_selectedItems count];
      self.loading = YES;
      [[RACSignal zip:[_selectedItems.rac_sequence.eagerSequence map:^(FileSystemItem *x) {
        return [x delete];
      }]] subscribeCompleted:^{
        ASSERT_MAIN_QUEUE();
        self.loading = NO;
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File deleted") plural:L(@"%u files deleted") count:selectedItemsCount] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
      }];
      [self setEditing:NO animated:YES];
    }
  } else if (actionSheet == _toolEditItemDuplicateActionSheet) {
    if (buttonIndex == 0) { // Copy
      FolderBrowserController *directoryBrowser = [[FolderBrowserController alloc] init];
      directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Copy") style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserCopyAction:)];
      directoryBrowser.currentFolderSignal = [FileSystemDirectory directoryWithURL:self.artCodeTab.currentLocation.project.fileURL];
      [self modalNavigationControllerPresentViewController:directoryBrowser];
    } else if (buttonIndex == 1) { // Duplicate
      NSUInteger selectedItemsCount = [_selectedItems count];
      self.loading = YES;
      [[RACSignal zip:[_selectedItems.rac_sequence.eagerSequence map:^(FileSystemItem *x) {
        return [x duplicate];
      }]] subscribeCompleted:^{
        ASSERT_MAIN_QUEUE();
        self.loading = NO;
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File duplicated") plural:L(@"%u files duplicated") count:selectedItemsCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
      }];
      [self setEditing:NO animated:YES];
    }
  } else if (actionSheet == _toolEditItemExportActionSheet) {
    switch (buttonIndex) {
      case 0: { // Rename
        if (_selectedItems.count != 1) {
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Select a single file to rename") imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
          break;
        }
        RenameController *renameController = [[RenameController alloc] initWithRenameItem:_selectedItems[0] completionHandler:^(NSUInteger renamedCount, NSError *err) {
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
        break;
      }
      case 1: { // Move
        FolderBrowserController *directoryBrowser = [[FolderBrowserController alloc] init];
        directoryBrowser.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Move") style:UIBarButtonItemStylePlain target:self action:@selector(_directoryBrowserMoveAction:)];
        directoryBrowser.currentFolderSignal = [FileSystemDirectory directoryWithURL:self.artCodeTab.currentLocation.project.fileURL];
				directoryBrowser.excludeDirectory = self.currentDirectory;
        [self modalNavigationControllerPresentViewController:directoryBrowser];
        break;
      }
      case 2: { // iTunes
        NSUInteger selectedItemsCount = [_selectedItems count];
        self.loading = YES;
        [[[RACSignal zip:[_selectedItems.rac_sequence.eagerSequence map:^(FileSystemItem *x) {
					return [x.url map:^id(NSURL *url) {
						return [x exportTo:[NSURL.applicationDocumentsDirectory URLByAppendingPathComponent:url.lastPathComponent] copy:YES];
					}];
        }]] finally:^{
          self.loading = NO;
				}] subscribeError:^(NSError *error) {
					ASSERT_MAIN_QUEUE();
					[[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"Error exporting file") plural:L(@"Error exporting files") count:selectedItemsCount] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
				} completed:^{
          ASSERT_MAIN_QUEUE();
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"File exported") plural:L(@"%u files exported") count:selectedItemsCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
        }];
        [self setEditing:NO animated:YES];
        break;
      }
      case 3: { // Mail
        // Compressing files to export
        self.loading = YES;
        
        [[RACSignal zip:[_selectedItems.rac_sequence.eagerSequence map:^(FileSystemItem *x) {
          return [x.url take:1];
        }]] subscribeNext:^(RACTuple *x) {
          [ArchiveUtilities compressFileAtURLs:x.allObjects completionHandler:^(NSURL *temporaryDirectoryURL) {
            ASSERT_MAIN_QUEUE();
            if (temporaryDirectoryURL) {
              NSURL *archiveURL = [[temporaryDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:L(@"%@ Files"), self.artCodeTab.currentLocation.project.name]] URLByAppendingPathExtension:@"zip"];
              [[NSFileManager defaultManager] moveItemAtURL:[temporaryDirectoryURL URLByAppendingPathComponent:@"Archive.zip"] toURL:archiveURL error:NULL];
              // Create mail composer
              MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
              mailComposer.mailComposeDelegate = self;
              mailComposer.navigationBar.barStyle = UIBarStyleDefault;
              mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
              
              // Add attachement
              [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:archiveURL] mimeType:@"application/zip" fileName:[archiveURL lastPathComponent]];
              
              // Add precompiled mail fields
              [mailComposer setSubject:[NSString stringWithFormat:L(@"%@ exported files"), self.artCodeTab.currentLocation.project.name]];
              [mailComposer setMessageBody:L(@"<br/><p>Open this file with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained project.</p>") isHTML:YES];
              
              // Present mail composer
              [self presentViewController:mailComposer animated:YES completion:nil];
              [mailComposer.navigationBar.topItem.leftBarButtonItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
              [[NSFileManager defaultManager] removeItemAtURL:temporaryDirectoryURL error:NULL];
            }
            self.loading = NO;
          }];
        }];
        
        [self setEditing:NO animated:YES];
        break;
      }
    }
  }
}

#pragma mark - Mail composer Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  if (result == MFMailComposeResultSent) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Mail sent") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
  }
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)_toolNormalAddAction:(id)sender {
  if (!_toolNormalAddPopover) {
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
  if (!_toolEditItemExportActionSheet) {
    _toolEditItemExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Rename"), L(@"Move to new location"), L(@"Export to iTunes"), ([MFMailComposeViewController canSendMail] ? L(@"Send via E-Mail") : nil), nil];
    _toolEditItemExportActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [_toolEditItemExportActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditDuplicateAction:(id)sender {
  if (!_toolEditItemDuplicateActionSheet) {
    _toolEditItemDuplicateActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Copy to new location"), L(@"Duplicate"), nil];
    _toolEditItemDuplicateActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [_toolEditItemDuplicateActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

#pragma mark Modal actions

- (void)modalNavigationControllerDismissAction:(id)sender {
  if ([_modalNavigationController.visibleViewController isKindOfClass:[RemoteTransferController class]] && ![(RemoteTransferController *)_modalNavigationController.visibleViewController isTransferFinished]) {
    [(RemoteTransferController *)_modalNavigationController.visibleViewController cancelCurrentTransfer];
  } else {
    [self setEditing:NO animated:YES];
    [super modalNavigationControllerDismissAction:sender];
  }
}

- (void)_directoryBrowserCopyAction:(id)sender {
  // Retrieve URL to copy to
  FolderBrowserController *directoryBrowser = (FolderBrowserController *)_modalNavigationController.topViewController;
  FileSystemDirectory *copyDestinationFolder = directoryBrowser.selectedFolder;
  
  // Initialize conflict controller
  MoveConflictController *conflictController = [[MoveConflictController alloc] init];
  [self modalNavigationControllerPresentViewController:conflictController];
  
  // Start copy
  NSArray *items = [_selectedItems copy];
	if (items.count == 0) {
		return;
	}
  [[[conflictController moveItems:items toFolder:copyDestinationFolder usingSignalBlock:^(FileSystemItem *item, FileSystemDirectory *destinationFolder) {
    return [item copyTo:destinationFolder];
  }] finally:^{
    ASSERT_MAIN_QUEUE();
    [self setEditing:NO animated:YES];
    [self modalNavigationControllerDismissAction:sender];
  }] subscribeError:^(NSError *error) {
    ASSERT_MAIN_QUEUE();
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Error copying files") imageNamed:BezelAlertForbiddenIcon displayImmediatly:NO];
  } completed:^{
    ASSERT_MAIN_QUEUE();
		[[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Files copied") imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }];
}

- (void)_directoryBrowserMoveAction:(id)sender {
  // Retrieve URL to move to
  FolderBrowserController *directoryBrowser = (FolderBrowserController *)_modalNavigationController.topViewController;
  FileSystemDirectory *moveDestinationFolder = directoryBrowser.selectedFolder;
  
  // Initialize conflict controller
  MoveConflictController *conflictController = [[MoveConflictController alloc] init];
  [self modalNavigationControllerPresentViewController:conflictController];
  
  // Start moving
  NSArray *items = [_selectedItems copy];
	if (items.count == 0) {
		return;
	}
  [[[conflictController moveItems:items toFolder:moveDestinationFolder usingSignalBlock:^(FileSystemItem *item, FileSystemDirectory *destinationFolder) {
    return [item moveTo:destinationFolder];
  }] finally:^{
    ASSERT_MAIN_QUEUE();
    [self setEditing:NO animated:YES];
    [self modalNavigationControllerDismissAction:sender];
  }] subscribeError:^(NSError *error) {
    ASSERT_MAIN_QUEUE();
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Error moving files") imageNamed:BezelAlertForbiddenIcon displayImmediatly:NO];
  } completed:^{
    ASSERT_MAIN_QUEUE();
		[[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Files moved") imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }];
}

- (void)_previewFile:(NSURL *)fileURL {
	[[[RACSignal zip:[self.filteredItems.rac_sequence.eagerSequence map:^id(RACTuple *value) {
		return [(FileSystemItem *)value.first url];
	}]] take:1] subscribeNext:^(RACTuple *x) {
		NSMutableArray *previewItems = [NSMutableArray arrayWithCapacity:x.count];
		for (NSURL *itemURL in x) {
			FilePreviewItem *previewItem = [FilePreviewItem filePreviewItemWithFileURL:itemURL];
			if (![CodeFileController canDisplayFileInCodeView:itemURL] && [QLPreviewController canPreviewItem:previewItem]) {
				[previewItems addObject:previewItem];
			}
		}
		self.previewItems = previewItems;
		QLPreviewController *previewer = [[QLPreviewController alloc] init];
		[previewer setDataSource:self];
		[previewer setCurrentPreviewItemIndex:[self.previewItems indexOfObjectPassingTest:^BOOL(FilePreviewItem *item, NSUInteger idx, BOOL *stop) {
			return [item.previewItemURL isEqual:fileURL];
		}]];
		[self presentViewController:previewer animated:YES completion:nil];
	}];
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
