//
//  RemoteBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 20/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SearchableTableBrowserController.h"

@interface RemoteBrowserController : SearchableTableBrowserController

/// Set the URL to open. This methos will activelly connect to the URL.
@property (nonatomic, strong) NSURL *URL;

#pragma mark Login panel outlets

@property (strong, nonatomic) IBOutlet UILabel *loginLabel;
@property (strong, nonatomic) IBOutlet UITextField *loginUser;
@property (strong, nonatomic) IBOutlet UITextField *loginPassword;
@property (strong, nonatomic) IBOutlet UISwitch *loginSavePassword;
- (IBAction)loginAction:(id)sender;

@end
