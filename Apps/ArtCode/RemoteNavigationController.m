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

@implementation RemoteNavigationController

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote {
  ASSERT(remote && remote.url);
  ReactiveConnection *connection = [ReactiveConnection reactiveConnectionWithURL:remote.url];
  self = [super initWithRootViewController:[[RemoteFileListController alloc] initWithArtCodeRemote:remote connection:connection path:remote.path]];
  if (!self)
    return nil;
  _remote = remote;
  _connection = connection;
  return self;
}

@end

@implementation UIViewController (RemoteNavigationController)

- (RemoteNavigationController *)remoteNavigationController {
  return (RemoteNavigationController *)self.navigationController;
}

@end