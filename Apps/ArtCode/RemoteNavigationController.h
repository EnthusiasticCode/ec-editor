//
//  UINavigationController+RemoteNavigationController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import <UIKit/UIKit.h>

@class ReactiveConnection, RemoteNavigationToolbarController;

@interface RemoteNavigationController : UIViewController

#pragma mark Remote related properties

@property (nonatomic, strong, readonly) NSDictionary *remote;
@property (nonatomic, strong, readonly) ReactiveConnection *connection;

#pragma mark UI related properties

// The toolbar that will be set in place of the default navigation toolbar in the \c SingleTabController
@property (nonatomic, strong) IBOutlet RemoteNavigationToolbarController *toolbarController;

@end
