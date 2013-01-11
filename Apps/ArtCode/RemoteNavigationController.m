//
//  UINavigationController+RemoteNavigationController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import "RemoteNavigationController.h"
#import "RemoteNavigationToolbarController.h"
#import "SingleTabController.h"

#import "ArtCodeRemote.h"
#import "ReactiveConnection.h"

#import "LocalFileListController.h"
#import "RemoteFileListController.h"

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"

#import "FileSystemDirectory.h"

#import <Connection/CKConnectionRegistry.h>
#import "BezelAlert.h"
#import "NSString+PluralFormat.h"


@interface RemoteNavigationController () <UINavigationControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong, readwrite) ArtCodeRemote *remote;
@property (nonatomic, strong, readwrite) ReactiveConnection *connection;

@property (nonatomic, weak) UINavigationController *localBrowserNavigationController;
@property (nonatomic, weak) LocalFileListController *localFileListController;
@property (nonatomic, weak) UINavigationController *remoteBrowserNavigationController;
@property (nonatomic, weak) RemoteFileListController *remoteFileListController;

- (void)_downloadSelectedItemsOfRemoteController:(RemoteFileListController *)remoteController toLocationOfLocalController:(LocalFileListController *)localController;
- (void)_uploadSelectedItemsOfLocalController:(LocalFileListController *)localController toLocationOfRemoteController:(RemoteFileListController *)remoteController;
- (void)_presentRemoteDeleteConfirmationActionSheetWithSender:(id)sender;

@property (nonatomic) NSUInteger transfersInProgressCount;
@end

@implementation RemoteNavigationController {
  UIActionSheet *_remoteDeleteConfirmationActionSheet;
}

#pragma mark Controller lifecycle

static void _init(RemoteNavigationController *self) {
  // RAC
  @weakify(self);
  
  RAC(self.connection) = [RACAble(self.remote) map:^id(ArtCodeRemote *remote) {
    return [ReactiveConnection reactiveConnectionWithURL:remote.url];
  }];
  
  RAC(self.remote) = [RACAble(self.artCodeTab) map:^id(ArtCodeTab *tab) {
    return tab.currentLocation.remote;
  }];
  
  [[[RACAble(self.toolbarController)
     map:^id(RemoteNavigationToolbarController *x) {
       return [x buttonsActionSignal];
     }] switchToLatest] subscribeNext:^(UIButton *x) {
       @strongify(self);
       switch (x.tag) {
         case 1: // Local back
           [self.localBrowserNavigationController popViewControllerAnimated:YES];
           break;
           
         case 2: // Upload
           [self _uploadSelectedItemsOfLocalController:self.localFileListController toLocationOfRemoteController:self.remoteFileListController];
           break;
           
         case 3: // Remote back
           [self.remoteBrowserNavigationController popViewControllerAnimated:YES];
           break;
           
         case 4: // Download
           [self _downloadSelectedItemsOfRemoteController:self.remoteFileListController toLocationOfLocalController:self.localFileListController];
           break;
           
         case 5: // Delete
           [self _presentRemoteDeleteConfirmationActionSheetWithSender:x];
           break;
           
         default: // Cancel or Close
           if (self.transfersInProgressCount == 0) {
             [self.artCodeTab moveBackInHistory];
           } else {
             [self.connection cancelAll];
           }
           break;
       }
     }];
  
  // Upload button activation reaction
  [RACAble(self.localFileListController.selectedItems) subscribeNext:^(NSArray *x) {
    @strongify(self);
    self.toolbarController.uploadButton.enabled = x.count != 0 && self.connection.isConnected;
  }];
  
  // Download button activation reaction
  [RACAble(self.remoteFileListController.selectedItems) subscribeNext:^(NSArray *x) {
    @strongify(self);
    self.toolbarController.downloadButton.enabled =
    self.toolbarController.remoteDeleteButton.enabled = x.count != 0 && self.connection.isConnected;
  }];
  
  // React on local file location to change label name
  RAC(self.toolbarController.localTitleLabel.text) = [RACAble(self.localFileListController.locationDirectory.name) switchToLatest];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self) {
    return nil;
  }
  _init(self);
  return self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"LocalBrowser"]) {
    // Set the initial location for the local file browser
    self.localBrowserNavigationController = segue.destinationViewController;
    self.localBrowserNavigationController.editing = YES;
    self.localBrowserNavigationController.delegate = self;
  } else if ([segue.identifier isEqualToString:@"RemoteBrowser"]) {
    ASSERT(self.connection && self.remote);
    self.remoteBrowserNavigationController = (UINavigationController *)segue.destinationViewController;
    self.remoteBrowserNavigationController.editing = YES;
    self.remoteBrowserNavigationController.delegate = self;
    [(RemoteFileListController *)[self.remoteBrowserNavigationController topViewController] prepareWithConnection:self.connection artCodeRemote:self.remote path:self.remote.path];
  }
}

#pragma mark View lifecycle

- (void)loadView {
  [super loadView];
  
  if (!self.toolbarController) {
    self.toolbarController = [[UIStoryboard storyboardWithName:@"RemoteNavigator" bundle:nil] instantiateViewControllerWithIdentifier:@"Toolbar"];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [self.singleTabController setToolbarViewController:(UIViewController *)self.toolbarController animated:YES];
  self.toolbarController.remoteTitleLabel.text = self.remoteFileListController.remotePath.lastPathComponent;
  [super viewDidAppear:animated];
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  // This is done because UIViewController is not KVO compliant on visibleViewController
  if (navigationController == self.localBrowserNavigationController) {
    self.localFileListController = (LocalFileListController *)viewController;
    // RAC setting the initial location for the local file browser
    if ([(LocalFileListController *)viewController locationDirectory] == nil) {
      [[FileSystemDirectory itemWithURL:self.artCodeTab.currentLocation.project.fileURL] subscribeNext:^(FileSystemDirectory *x) {
        [(LocalFileListController *)viewController setLocationDirectory:x];
      }];
    }
  } else if (navigationController == self.remoteBrowserNavigationController) {
    self.remoteFileListController = (RemoteFileListController *)viewController;
    self.toolbarController.remoteTitleLabel.text = self.remoteFileListController.remotePath.lastPathComponent;
  }
}

#pragma mark UIActionSheetDelegate

- (void)_presentRemoteDeleteConfirmationActionSheetWithSender:(id)sender {
  if (!_remoteDeleteConfirmationActionSheet) {
    _remoteDeleteConfirmationActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Delete permanently" otherButtonTitles:nil];
  }
  [_remoteDeleteConfirmationActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (actionSheet == _remoteDeleteConfirmationActionSheet) {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
      [self _deleteSelectedItemsOfRemoteController:self.remoteFileListController];
    }
  }
}

#pragma mark Private methods

- (void)_downloadSelectedItemsOfRemoteController:(RemoteFileListController *)remoteController toLocationOfLocalController:(LocalFileListController *)localController {
  @weakify(self);
  self.transfersInProgressCount++;
  // RAC
  ReactiveConnection *connection = self.connection;
  [[RACSignal zip:[remoteController.selectedItems.rac_sequence.eagerSequence map:^RACSignal *(NSDictionary *item) {
    NSString *itemName = item[cxFilenameKey];
    // Generate local destination URL and start the download
    RACSignal *progressSignal = [connection downloadFileWithRemotePath:[remoteController.remotePath stringByAppendingPathComponent:itemName] isDirectory:(item[NSFileType] == NSFileTypeDirectory)];
    
    // Side effect to start the progress indicator in the local file list
    [localController addProgressItemWithName:itemName progressSignal:progressSignal];
    
    // Return a signal that yields the FileSystemItem of the downloaded file
    return [[[[[progressSignal filter:^BOOL(id x) {
      // Only return URLs
      return [x isKindOfClass:[NSURL class]];
    }] flattenMap:^RACSignal *(NSURL *tempURL) {
      // Convert to filesystem item
      return [FileSystemItem itemWithURL:tempURL];
    }] flattenMap:^RACSignal *(FileSystemItem *x) {
      // Move to destination, the downloaded FileSystemItem is sent
      return [x moveTo:localController.locationDirectory withName:itemName replaceExisting:YES];
    }] catchTo:[RACSignal return:nil]] doNext:^(id x) {
      if (x == nil) {
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Error downloading file") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
      }
    }];
  }]] subscribeCompleted:^{
    @strongify(self);
    self.transfersInProgressCount--;
  }];
}

- (void)_uploadSelectedItemsOfLocalController:(LocalFileListController *)localController toLocationOfRemoteController:(RemoteFileListController *)remoteController {
  @weakify(self);
  self.transfersInProgressCount++;
  // RAC
  ReactiveConnection *connection = self.connection;
  [[[RACSignal zip:[localController.selectedItems.rac_sequence.eagerSequence map:^RACSignal *(FileSystemItem *x) {
    return [[x.url take:1] map:^RACSignal *(NSURL *itemURL) {
      // Start upload
      RACSignal *progressSignal = [connection uploadFileAtLocalURL:itemURL toRemotePath:[remoteController.remotePath stringByAppendingPathComponent:itemURL.lastPathComponent]];
      
      // Start progress indicator in the remote file list
      [remoteController addProgressItemWithURL:itemURL progressSignal:progressSignal];
      
      return progressSignal;
    }];
  }]] finally:^{
    @strongify(self);
    self.transfersInProgressCount--;
    // Refresh remote list
    [remoteController refresh];
  }] subscribeError:^(NSError *error) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Errors uploading files") imageNamed:BezelAlertCancelIcon displayImmediatly:NO];
  } completed:^{
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Upload completed") imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }];
}

- (void)_deleteSelectedItemsOfRemoteController:(RemoteFileListController *)remoteController {
  @weakify(self);
  self.transfersInProgressCount++;
  // RAC
  ReactiveConnection *connection = self.connection;
  [[[RACSignal zip:[remoteController.selectedItems.rac_sequence.eagerSequence map:^RACSignal *(NSDictionary *item) {
    return [connection deleteFileWithRemotePath:[remoteController.remotePath stringByAppendingPathComponent:item[cxFilenameKey]]];
  }]] finally:^{
    @strongify(self);
    self.transfersInProgressCount--;
    [remoteController refresh];
  }] subscribeError:^(NSError *error) {
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Errors deleting files") imageNamed:BezelAlertCancelIcon displayImmediatly:NO];
  } completed:^{
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Files deleted") imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }];
}

@end
