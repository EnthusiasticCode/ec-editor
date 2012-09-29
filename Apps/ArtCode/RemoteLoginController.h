//
//  RemoteLoginController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/09/12.
//
//

#import <UIKit/UIKit.h>

@class ArtCodeRemote;

/// This controller will be used inside a RemoteNavigationController to initialize the connection.
@interface RemoteLoginController : UIViewController

- (id)initAndConnectToArtCodeRemote:(ArtCodeRemote *)remote;

#pragma mark Login panel outlets

@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UITextField *loginUser;
@property (weak, nonatomic) IBOutlet UITextField *loginPassword;
@property (weak, nonatomic) IBOutlet UISwitch *loginAlwaysAskPassword;
- (IBAction)loginAction:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *loadingView;

@end
