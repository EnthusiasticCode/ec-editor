//
//  UINavigationController+RemoteNavigationController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import <UIKit/UIKit.h>

@class ArtCodeRemote, ReactiveConnection;

@interface RemoteNavigationController : UINavigationController

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote;

@property (nonatomic, strong, readonly) ArtCodeRemote *remote;
@property (nonatomic, strong, readonly) ReactiveConnection *connection;

@end


@interface UIViewController (RemoteNavigationController)

- (RemoteNavigationController *)remoteNavigationController;

@end
