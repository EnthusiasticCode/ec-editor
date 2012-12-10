//
//  NewProjectPopoverController.h
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ColorSelectionControl, ArtCodeProject;

@interface NewProjectController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) ArtCodeProject *projectToEdit;

@property (weak, nonatomic) IBOutlet ColorSelectionControl *projectColorSelection;
@property (weak, nonatomic) IBOutlet UITextField *projectNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

- (IBAction)createProjectAction:(id)sender;
- (IBAction)editProjectAction:(id)sender;

@end
