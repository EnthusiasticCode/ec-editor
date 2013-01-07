//
//  NewFileFolderController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewFileFolderController : UIViewController <UITextFieldDelegate>

#pragma mark IB outlets

@property (weak, nonatomic) IBOutlet UITextField *folderNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

- (IBAction)createAction:(id)sender;

@end
