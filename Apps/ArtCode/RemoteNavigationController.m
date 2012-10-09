//
//  UINavigationController+RemoteNavigationController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import "RemoteNavigationController.h"
#import "SingleTabController.h"

#import "ArtCodeRemote.h"
#import "ReactiveConnection.h"

#import "BaseFileBrowserController.h"
#import "RemoteFileListController.h"

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"


@interface RemoteNavigationController ()
@property (nonatomic, strong, readwrite) ArtCodeRemote *remote;
@property (nonatomic, strong, readwrite) ReactiveConnection *connection;

@property (nonatomic, weak) UINavigationController *localBrowserNavigationController;
@property (nonatomic, weak) UINavigationController *remoteBrowserNavigationController;
@end

@implementation RemoteNavigationController

static void _init(RemoteNavigationController *self) {
  // RAC
  RAC(self.connection) = [RACAble(self.remote) select:^id(ArtCodeRemote *remote) {
    return [ReactiveConnection reactiveConnectionWithURL:remote.url];
  }];
  
  RAC(self.remote) = [RACAble(self.artCodeTab) select:^id(ArtCodeTab *tab) {
    return tab.currentLocation.remote;
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

- (void)loadView {
  [super loadView];
  
  if (!self.toolbarController) {
    self.toolbarController = [[UIStoryboard storyboardWithName:@"RemoteNavigator" bundle:nil] instantiateViewControllerWithIdentifier:@"Toolbar"];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [self.singleTabController setToolbarViewController:self.toolbarController animated:YES];
  [super viewDidAppear:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"LocalBrowser"]) {
    // Set the initial location for the local file browser
    self.localBrowserNavigationController = segue.destinationViewController;
    self.localBrowserNavigationController.editing = YES;
    [(BaseFileBrowserController *)[self.localBrowserNavigationController topViewController] setLocationURL:self.artCodeTab.currentLocation.project.fileURL];
  } else if ([segue.identifier isEqualToString:@"RemoteBrowser"]) {
    ASSERT(self.connection && self.remote);
    [(RemoteFileListController *)[(UINavigationController *)segue.destinationViewController topViewController] prepareWithConnection:self.connection artCodeRemote:self.remote path:self.remote.path];
  }
}

@end
