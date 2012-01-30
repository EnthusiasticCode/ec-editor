//
//  QuickFileInfoController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuickFileInfoController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *fileNameTextField;
@property (strong, nonatomic) IBOutlet UILabel *fileSizeLabel;
@property (strong, nonatomic) IBOutlet UILabel *fileLineCountLabel;

@end
