//
//  UINavigationController+RemoteNavigationController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import <UIKit/UIKit.h>

@class ArtCodeRemote;
@protocol CKConnection;

@interface RemoteNavigationController : UINavigationController

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote;

@property (nonatomic, strong, readonly) ArtCodeRemote *remote;
@property (nonatomic, strong) id<CKConnection> connection;

@end


@interface UIViewController (RemoteNavigationController)

- (RemoteNavigationController *)remoteNavigationController;

@end
