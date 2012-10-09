//
//  RemoteFileListController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/09/12.
//
//

#import <UIKit/UIKit.h>
#import "SearchableTableBrowserController.h"

@class ArtCodeRemote, ReactiveConnection;

@interface RemoteFileListController : SearchableTableBrowserController

/// Make the controller use the given connection to connect to the remote path.
- (void)prepareWithConnection:(ReactiveConnection *)connection artCodeRemote:(ArtCodeRemote *)remote path:(NSString *)remotePath;

#pragma mark Login panel outlets

@property (strong, nonatomic) IBOutlet UIView *loginView;
@property (weak, nonatomic) IBOutlet UILabel *loginLabel;
@property (weak, nonatomic) IBOutlet UITextField *loginUser;
@property (weak, nonatomic) IBOutlet UITextField *loginPassword;
@property (weak, nonatomic) IBOutlet UISwitch *loginAlwaysAskPassword;
- (IBAction)loginAction:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *loadingView;

@end
