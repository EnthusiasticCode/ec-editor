//
//  QuickProjectInfoController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ArtCodeTab, ColorSelectionControl;

@interface QuickProjectInfoController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *projectNameTextField;
@property (strong, nonatomic) IBOutlet ColorSelectionControl *labelColorSelectionControl;
@property (strong, nonatomic) IBOutlet UILabel *projectFileCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *projectSizeLabel;

@end
