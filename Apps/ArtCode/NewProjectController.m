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
#import "NSURL+ArtCode.h"

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

@implementation NewProjectController

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.projectColorSelection.enabled = YES;
  self.projectNameTextField.enabled = YES;
  [self stopRightBarButtonItemActivityIndicator];
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
	if (!projectColor) projectColor = UIColor.styleForegroundColor;
  
  [self startRightBarButtonItemActivityIndicator];
  self.projectColorSelection.enabled = NO;
  self.projectNameTextField.enabled = NO;
	[[[RCIODirectory itemWithURL:[NSURL.projectsListDirectory URLByAppendingPathComponent:projectName] mode:RCIOItemModeExclusiveAccess] finally:^{
    [self stopRightBarButtonItemActivityIndicator];
    self.projectColorSelection.enabled = YES;
    self.projectNameTextField.enabled = YES;
	}] subscribeError:^(NSError *error) {
		[self.projectNameTextField selectAll:nil];
		self.descriptionLabel.text = L(@"A project with this name already exists, use a different name.");
	} completed:^{
		[self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
		[BezelAlert.defaultBezelAlert addAlertMessageWithText:L(@"New project created") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
	}];
}

@end