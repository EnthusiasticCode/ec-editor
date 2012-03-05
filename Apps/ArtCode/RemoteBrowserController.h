//
//  RemoteBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchableTableBrowserController.h"

@protocol CKConnection;

@interface RemoteBrowserController : SearchableTableBrowserController

/// Takes over the control of the given connection that is pointing to the given URL.
- (id)initWithConnection:(id<CKConnection>)con url:(NSURL *)conUrl;

@property (nonatomic, strong, readonly) id<CKConnection> connection;

/// Set the URL to open. This methos will activelly connect to the URL.
@property (nonatomic, strong) NSURL *URL;

- (IBAction)refreshAction:(id)sender;

/// Shows a modal to synchronize the current remote path with a local folder
- (IBAction)syncAction:(id)sender;

#pragma mark Login panel outlets

@property (strong, nonatomic) IBOutlet UILabel *loginLabel;
@property (strong, nonatomic) IBOutlet UITextField *loginUser;
@property (strong, nonatomic) IBOutlet UITextField *loginPassword;
@property (strong, nonatomic) IBOutlet UISwitch *loginAlwaysAskPassword;
- (IBAction)loginAction:(id)sender;

@end
