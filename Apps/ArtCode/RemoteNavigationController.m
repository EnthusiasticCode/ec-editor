//
//  UINavigationController+RemoteNavigationController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import "RemoteNavigationController.h"
#import "ArtCodeRemote.h"
#import "ReactiveConnection.h"
#import "RemoteFileListController.h"

@implementation RemoteNavigationController {
  void (^_dismissBlock)(RemoteNavigationController *);
}

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote dismissBlock:(void (^)(RemoteNavigationController *))dismissBlock {
  ASSERT(remote && remote.url);
  ReactiveConnection *connection = [ReactiveConnection reactiveConnectionWithURL:remote.url];
  self = [super initWithRootViewController:[[RemoteFileListController alloc] initWithArtCodeRemote:remote connection:connection path:remote.path]];
  if (!self)
    return nil;
  _remote = remote;
  _connection = connection;
  _dismissBlock = dismissBlock;
  return self;
}

- (void)dismiss {
  if (_dismissBlock) {
    _dismissBlock(self);
  }
}

@end

@implementation UIViewController (RemoteNavigationController)

- (RemoteNavigationController *)remoteNavigationController {
  return (RemoteNavigationController *)self.navigationController;
}

@end