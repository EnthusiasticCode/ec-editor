//
//  QuickFolderInfoController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuickFolderInfoController : UITableViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *folderNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *folderFileCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *folderSubfolderCountLabel;

@end
