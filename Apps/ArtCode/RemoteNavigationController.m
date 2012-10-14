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

#import <Connection/CKConnectionRegistry.h>


@interface RemoteNavigationController () <UINavigationControllerDelegate>
@property (nonatomic, strong, readwrite) ArtCodeRemote *remote;
@property (nonatomic, strong, readwrite) ReactiveConnection *connection;

@property (nonatomic, weak) UINavigationController *localBrowserNavigationController;
@property (nonatomic, weak) LocalFileListController *localFileListController;
@property (nonatomic, weak) UINavigationController *remoteBrowserNavigationController;
@property (nonatomic, weak) RemoteFileListController *remoteFileListController;

- (void)_downloadSelectedItemsOfRemoteController:(RemoteFileListController *)remoteController toLocationOfLocalController:(LocalFileListController *)localController;
- (void)_uploadSelectedItemsOfLocalController:(LocalFileListController *)localController toLocationOfRemoteController:(RemoteFileListController *)remoteController;
@end

@implementation RemoteNavigationController

#pragma mark Controller lifecycle

static void _init(RemoteNavigationController *self) {
  // RAC
  @weakify(self);
  
  RAC(self.connection) = [RACAble(self.remote) select:^id(ArtCodeRemote *remote) {
    return [ReactiveConnection reactiveConnectionWithURL:remote.url];
  }];
  
  RAC(self.remote) = [RACAble(self.artCodeTab) select:^id(ArtCodeTab *tab) {
    return tab.currentLocation.remote;
  }];
  
  [[[RACAble(self.toolbarController)
   select:^id(RemoteNavigationToolbarController *x) {
     return [x buttonsActionSubscribable];
   }] switch] subscribeNext:^(UIButton *x) {
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
         
       default: // Close
         [self.artCodeTab moveBackInHistory];
         break;
     }
   }];
  
  // Upload button activation reaction
  [RACAble(self.localFileListController.selectedItems) subscribeNext:^(NSArray *x) {
    @strongify(self);
    self.toolbarController.uploadButton.enabled = x.count != 0; // TODO && connected
  }];
  
  // Download button activation reaction
  [RACAble(self.remoteFileListController.selectedItems) subscribeNext:^(NSArray *x) {
    @strongify(self);
    self.toolbarController.downloadButton.enabled = x.count != 0;
  }];
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
    [(LocalFileListController *)[self.localBrowserNavigationController topViewController] setLocationURL:self.artCodeTab.currentLocation.project.fileURL];
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
  [super viewDidAppear:animated];
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  // This is done because UIViewController is not KVO compliant on visibleViewController
  if (navigationController == self.localBrowserNavigationController) {
    self.localFileListController = (LocalFileListController *)viewController;
  } else if (navigationController == self.remoteBrowserNavigationController) {
    self.remoteFileListController = (RemoteFileListController *)viewController;
  }
}

#pragma mark Private methods

- (void)_downloadSelectedItemsOfRemoteController:(RemoteFileListController *)remoteController toLocationOfLocalController:(LocalFileListController *)localController {
  // RAC
  ReactiveConnection *connection = self.connection;
  [[remoteController.selectedItems.rac_toSubscribable select:^id(NSDictionary *item) {
    NSString *itemName = [item objectForKey:cxFilenameKey];
    // Generate local destination URL and start the download
    NSURL *localURL = [localController.locationURL URLByAppendingPathComponent:itemName];
    RACSubscribable *progressSubscribable = [connection downloadFileWithRemotePath:[remoteController.remotePath stringByAppendingPathComponent:itemName] isDirectory:([item objectForKey:NSFileType] == NSFileTypeDirectory)];
    
    // Side effect to start the progress indicator in the local file list
    [localController addProgressItemWithURL:localURL progressSubscribable:progressSubscribable];
    
    // Return a subscribable that yields tuple of temporary URL and local destination URL
    return [[progressSubscribable takeLast:1] select:^id(NSURL *tempURL) {
      return [RACTuple tupleWithObjects:tempURL, localURL, nil];
    }];
  }] subscribeNext:^(RACTuple *urlTuple) {
    // Move the temporary file to the destination URL
    [[NSFileManager defaultManager] moveItemAtURL:urlTuple.first toURL:urlTuple.second error:NULL];
  }];
}

- (void)_uploadSelectedItemsOfLocalController:(LocalFileListController *)localController toLocationOfRemoteController:(RemoteFileListController *)remoteController {
  // RAC
  ReactiveConnection *connection = self.connection;
  [localController.selectedItems.rac_toSubscribable subscribeNext:^void(NSURL *itemURL) {
    // Start upload
    RACSubscribable *progressSubscribable = [connection uploadFileAtLocalURL:itemURL toRemotePath:[remoteController.remotePath stringByAppendingPathComponent:itemURL.lastPathComponent]];
    
    // Start progress indicator in the remote file list
    [remoteController addProgressItemWithURL:itemURL progressSubscribable:progressSubscribable];
  }];
}

@end
