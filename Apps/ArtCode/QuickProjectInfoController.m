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


@implementation QuickProjectInfoController

@synthesize projectNameTextField;
@synthesize labelColorSelectionControl;
@synthesize projectFileCountLabel;

#pragma mark - Controller lifecycle

+ (id)new
{
  return [[UIStoryboard storyboardWithName:@"QuickInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"QuickProjectInfo"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self)
    return nil;
  
  // Project name will change when text field does
  [[[[[RACAbleSelf(self.projectNameTextField.rac_textSubscribable) switch] throttle:0.3] distinctUntilChanged] where:^BOOL(id x) {
    return x != nil;
  }] toProperty:RAC_KEYPATH_SELF(self.artCodeTab.currentProject.name) onObject:self];
  
  // Project label color will change when selecting a new color
  [[[RACAbleSelf(self.labelColorSelectionControl.selectedColor) distinctUntilChanged] where:^BOOL(id x) {
    return x != nil;
  }] toProperty:RAC_KEYPATH_SELF(self.artCodeTab.currentProject.labelColor) onObject:self];
  
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Send the selected color to the current project's label color
  self.labelColorSelectionControl.rows = 1;
  self.labelColorSelectionControl.columns = 6;
}

- (void)viewDidUnload
{
  [self setProjectNameTextField:nil];
  [self setLabelColorSelectionControl:nil];
  [self setProjectFileCountLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.projectNameTextField.text = self.artCodeTab.currentProject.name;
  self.projectFileCountLabel.text = [NSString stringWithFormat:@"%u", self.artCodeTab.currentProject.files.count];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end


