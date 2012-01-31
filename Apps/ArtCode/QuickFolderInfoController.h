//
//  QuickFolderInfoController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuickFolderInfoController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *folderNameTextField;
@property (strong, nonatomic) IBOutlet UILabel *folderFileCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *folderSizeLabel;

@end
