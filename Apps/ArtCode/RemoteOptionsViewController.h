//
//  RemoteOptionsViewController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RemoteOptionsViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *remoteName;
@property (strong, nonatomic) IBOutlet UISegmentedControl *remoteType;
@property (strong, nonatomic) IBOutlet UITextField *remoteHost;
@property (strong, nonatomic) IBOutlet UITextField *remotePort;
@property (strong, nonatomic) IBOutlet UITextField *remoteUser;
@property (strong, nonatomic) IBOutlet UITextField *remotePassword;

@property (strong, nonatomic) NSString *remoteTypeString;

- (IBAction)remoteTypeChangedAction:(id)sender;

@end
