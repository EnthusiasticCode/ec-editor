//
//  QuickFileInfoController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileInfoController.h"
#import "QuickBrowsersContainerController.h"
#import "ArtCodeTab.h"
#import "ArtCodeURL.h"

@implementation QuickFileInfoController

@synthesize fileNameTextField;
@synthesize fileSizeLabel;
@synthesize fileLineCountLabel;

+ (id)new
{
  return [[UIStoryboard storyboardWithName:@"QuickInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"QuickFileInfo"];
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
  [self setFileNameTextField:nil];
  [self setFileSizeLabel:nil];
  [self setFileLineCountLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.fileNameTextField.text = [self.artCodeTab.currentURL name];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
