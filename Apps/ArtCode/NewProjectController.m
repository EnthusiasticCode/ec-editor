//
//  NewProjectPopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NewProjectController.h"

#import "BezelAlert.h"
#import "ColorSelectionControl.h"

#import "AppStyle.h"
#import "ColorSelectionControl.h"
#import "UIViewController+Utilities.h"

#import "ArtCodeTab.h"
#import "ArtCodeProject.h"
#import "ArtCodeProjectSet.h"

@implementation NewProjectController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Send the selected color to the current project's label color
  self.projectColorSelection.rows = 1;
  self.projectColorSelection.columns = 6;
	
	if (self.projectToEdit != nil) {
		self.navigationItem.title = L(@"Edit project");
		[self.navigationItem.rightBarButtonItem setTitle:L(@"Done")];
		[self.navigationItem.rightBarButtonItem setAction:@selector(editProjectAction:)];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.projectColorSelection.enabled = YES;
  self.projectNameTextField.enabled = YES;
  [self stopRightBarButtonItemActivityIndicator];
	
	if (self.projectToEdit != nil) {
		self.projectNameTextField.text = self.projectToEdit.name;
		self.projectColorSelection.selectedColor = self.projectToEdit.labelColor;
		self.descriptionLabel.text = @"";
	}
	
  [self.projectNameTextField becomeFirstResponder];
}

#pragma mark Text Field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  [self createProjectAction:textField];
  return NO;
}

#pragma mark Public methods

- (IBAction)createProjectAction:(id)sender {
  NSString *projectName = self.projectNameTextField.text;
  if ([projectName length] == 0) {
    self.descriptionLabel.text = L(@"A project name must be specified.");
    return;
  }
	
	UIColor *projectColor = self.projectColorSelection.selectedColor;
	if (!projectColor) projectColor = [UIColor styleForegroundColor];
  
  [self startRightBarButtonItemActivityIndicator];
  self.projectColorSelection.enabled = NO;
  self.projectNameTextField.enabled = NO;
  [[ArtCodeProjectSet defaultSet] addNewProjectWithName:projectName labelColor:projectColor completionHandler:^(ArtCodeProject *project) {
    [self stopRightBarButtonItemActivityIndicator];
    self.projectColorSelection.enabled = YES;
    self.projectNameTextField.enabled = YES;
    if (!project) {
      [self.projectNameTextField selectAll:nil];
      self.descriptionLabel.text = L(@"A project with this name already exists, use a different name.");
    } else {
      [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"New project created") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
    }
  }];
}

- (void)editProjectAction:(id)sender {
	if (self.projectNameTextField.text.length == 0) {
		self.descriptionLabel.text = L(@"Invalid name for a project");
	}
	self.projectToEdit.name = self.projectNameTextField.text;
	if (self.projectColorSelection.selectedColor != nil) {
		self.projectToEdit.labelColor = self.projectColorSelection.selectedColor;
	}
	[self dismissModalViewControllerAnimated:YES];
}

@end