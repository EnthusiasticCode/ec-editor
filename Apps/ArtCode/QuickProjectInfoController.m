//
//  QuickProjectInfoController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickProjectInfoController.h"
#import "QuickBrowsersContainerController.h"

#import "AppStyle.h"
#import "ArtCodeURL.h"
#import "ArtCodeTab.h"

#import "ACProject.h"

#import "ColorSelectionControl.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface QuickProjectInfoController ()

- (void)_labelColorChangeAction:(id)sender;

@end


@implementation QuickProjectInfoController

@synthesize projectNameTextField;
@synthesize labelColorSelectionControl;
@synthesize projectFileCountLabel;
@synthesize projectSizeLabel;

#pragma mark - Controller lifecycle

+ (id)new
{
  return [[UIStoryboard storyboardWithName:@"QuickInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"QuickProjectInfo"];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Changes the current project name with the one entered
  [[[self.projectNameTextField.rac_textSubscribable throttle:0.3] distinctUntilChanged] toProperty:RAC_KEYPATH_SELF(self.artCodeTab.currentProject.name) onObject:self];
  
  // Send the selected color to the current project's label color
  self.labelColorSelectionControl.rows = 1;
  self.labelColorSelectionControl.columns = 6;
  [[RACAbleSelf(self.labelColorSelectionControl.selectedColor) distinctUntilChanged] toProperty:RAC_KEYPATH_SELF(self.artCodeTab.currentProject.labelColor) onObject:self];
}

- (void)viewDidUnload
{
  [self setProjectNameTextField:nil];
  [self setLabelColorSelectionControl:nil];
  [self setProjectFileCountLabel:nil];
  [self setProjectSizeLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.projectNameTextField.text = [self.artCodeTab.currentProject name];
  // TODO add project files and size
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end


