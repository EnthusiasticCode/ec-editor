//
//  NewProjectPopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NewProjectController.h"

#import "BezelAlert.h"

#import "AppStyle.h"
#import "ColorSelectionControl.h"
#import "UIViewController+Utilities.h"

#import "ArtCodeTab.h"
#import "ArtCodeProject.h"
#import "ArtCodeProjectSet.h"

@implementation NewProjectController {
  UIViewController *changeColorController;
  UIColor *projectColor;
}

@synthesize projectColorButton;
@synthesize projectNameTextField;
@synthesize descriptionLabel;

- (void)viewDidLoad {
  [super viewDidLoad];
  self.projectColorButton.accessibilityIdentifier = @"Label color";
  self.projectColorButton.accessibilityLabel = L(@"No color label");
}

- (void)viewDidUnload {
  [self setProjectNameTextField:nil];
  [self setProjectColorButton:nil];
  [self setDescriptionLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.projectColorButton.hidden = NO;
  self.projectNameTextField.enabled = YES;
  [self stopRightBarButtonItemActivityIndicator];
  
  [self.projectColorButton setImage:[UIImage styleProjectLabelImageWithSize:CGSizeMake(14, 22) color:projectColor] forState:UIControlStateNormal];
  [self.projectNameTextField becomeFirstResponder];
}

- (void)_selectColorAction:(ColorSelectionControl *)sender
{
  projectColor = sender.selectedColor;
  [self.projectColorButton setImage:[UIImage styleProjectLabelImageWithSize:self.projectColorButton.bounds.size color:projectColor] forState:UIControlStateNormal];
  self.projectColorButton.accessibilityLabel = [NSString stringWithFormat:L(@"%@ label"), projectColor];
  [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Text Field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  [self createProjectAction:textField];
  return NO;
}

#pragma mark Public methods

- (IBAction)changeColorAction:(id)sender
{
  if (!changeColorController)
  {
    ColorSelectionControl *colorSelectionControl = [[ColorSelectionControl alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    [colorSelectionControl addTarget:self action:@selector(_selectColorAction:) forControlEvents:UIControlEventTouchUpInside];
    colorSelectionControl.accessibilityIdentifier = @"color selector";
    
    changeColorController = [UIViewController new];
    changeColorController.view = colorSelectionControl;
    changeColorController.contentSizeForViewInPopover = CGSizeMake(400, 200);
  }
  [self.navigationController pushViewController:changeColorController animated:YES];
}

- (IBAction)createProjectAction:(id)sender {
  NSString *projectName = self.projectNameTextField.text;
  if ([projectName length] == 0) {
    self.descriptionLabel.text = L(@"A project name must be specified.");
    return;
  }
  
  [self startRightBarButtonItemActivityIndicator];
  self.projectColorButton.enabled = NO;
  self.projectNameTextField.enabled = NO;
  [[ArtCodeProjectSet defaultSet] addNewProjectWithName:projectName completionHandler:^(ArtCodeProject *project) {
    [self stopRightBarButtonItemActivityIndicator];
    self.projectColorButton.enabled = YES;
    self.projectNameTextField.enabled = YES;
    if (!project) {
      [self.projectNameTextField selectAll:nil];
      self.descriptionLabel.text = L(@"A project with this name already exists, use a different name.");
    } else {
      project.labelColor = projectColor;
      [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"New project created") imageNamed:BezelAlertOkIcon displayImmediatly:YES];
    }
  }];
}

@end