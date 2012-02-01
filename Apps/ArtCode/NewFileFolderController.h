//
//  NewFileFolderController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewFileFolderController : UIViewController

#pragma mark IB outlets

@property (strong, nonatomic) IBOutlet UITextField *folderNameTextField;
@property (strong, nonatomic) IBOutlet UILabel *infoLabel;

- (IBAction)createAction:(id)sender;

@end
