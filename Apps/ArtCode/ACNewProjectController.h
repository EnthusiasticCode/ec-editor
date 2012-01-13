//
//  ACNewProjectPopoverController.h
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACNewProjectController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *projectColorButton;
@property (strong, nonatomic) IBOutlet UITextField *projectNameTextField;

- (IBAction)changeColorAction:(id)sender;
- (IBAction)createProjectAction:(id)sender;

@end
