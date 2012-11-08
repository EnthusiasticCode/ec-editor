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
#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"

#import "ArtCodeProject.h"

#import "ColorSelectionControl.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@implementation QuickProjectInfoController

@synthesize projectNameTextField;
@synthesize labelColorSelectionControl;
@synthesize projectFileCountLabel;

#pragma mark - Controller lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self)
    return nil;
  
  // RAC
  // Project name will change when text field does
  [[[[[RACAble(self.projectNameTextField.rac_textSubscribable) switch] throttle:0.3] distinctUntilChanged] where:^BOOL(NSString *x) {
    return x.length;
  }] toProperty:@keypath(self.artCodeTab.currentLocation.project.name) onObject:self];
  
  // Project label color will change when selecting a new color
  [[[RACAble(self.labelColorSelectionControl.selectedColor) distinctUntilChanged] where:^BOOL(id x) {
    return x != nil;
  }] toProperty:@keypath(self.artCodeTab.currentLocation.project.labelColor) onObject:self];
  
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
  
  self.projectNameTextField.text = self.artCodeTab.currentLocation.project.name;
  self.projectFileCountLabel.text = @"0"; // This has to be calculated asynchronously, maybe remove it?
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end


