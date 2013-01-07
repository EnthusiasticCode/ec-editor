//
//  RemoteOptionsViewController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RemoteOptionsViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *remoteName;
@property (weak, nonatomic) IBOutlet UISegmentedControl *remoteType;
@property (weak, nonatomic) IBOutlet UITextField *remoteHost;
@property (weak, nonatomic) IBOutlet UITextField *remotePort;
@property (weak, nonatomic) IBOutlet UITextField *remoteUser;
@property (weak, nonatomic) IBOutlet UITextField *remotePassword;

@property (strong, nonatomic) NSString *remoteTypeString;

- (IBAction)remoteTypeChangedAction:(id)sender;

@end
