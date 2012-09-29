//
//  UINavigationController+RemoteNavigationController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import "RemoteNavigationController.h"
#import "ArtCodeRemote.h"
#import <Connection/CKConnectionRegistry.h>
#import "RemoteLoginController.h"

@implementation RemoteNavigationController

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote {
  self = [super initWithRootViewController:[[RemoteLoginController alloc] initAndConnectToArtCodeRemote:remote]];
  if (!self)
    return nil;
  _remote = remote;
  return self;
}

- (void)dealloc {
  [self setConnection:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self setConnection:nil];
  [super viewWillDisappear:animated];
}

- (void)setConnection:(id<CKConnection>)connection {
  // Disconnect
  if (connection == nil) {
    [_connection setDelegate:nil];
    [_connection disconnect];
    _connection = nil;
    return;
  }
  
  ASSERT(_connection == nil); // The connection should be set only once
  _connection = connection;
}

@end

@implementation UIViewController (RemoteNavigationController)

- (RemoteNavigationController *)remoteNavigationController {
  return (RemoteNavigationController *)self.navigationController;
}

@end