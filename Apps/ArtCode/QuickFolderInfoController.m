//
//  QuickFolderInfoController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFolderInfoController.h"
#import "QuickBrowsersContainerController.h"
#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"

@implementation QuickFolderInfoController

@synthesize folderNameTextField;
@synthesize folderFileCountLabel;
@synthesize folderSizeLabel;

+ (id)new
{
  return [[UIStoryboard storyboardWithName:@"QuickInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"QuickFolderInfo"];
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
  [self setFolderNameTextField:nil];
  [self setFolderFileCountLabel:nil];
  [self setFolderSizeLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.folderNameTextField.text = [self.artCodeTab.currentLocation name];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - UITextField Delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
  // TODO rename folder
}

@end
