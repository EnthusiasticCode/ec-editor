//
//  NewFilePopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NewFileController.h"
#import "UIViewController+Utilities.h"

#import "ArtCodeTab.h"
#import "ACProject.h"
#import "ACProjectFolder.h"
#import "BezelAlert.h"

@implementation NewFileController

@synthesize fileNameTextField;
@synthesize infoLabel;
@synthesize templateDirectoryURL;

#pragma mark - View lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self)
    return nil;
  
  // Subscribable to get the latest filename with extension
  RACSubscribable *userInputFileNameSubscribable = [[[[RACAbleSelf(self.fileNameTextField.rac_textSubscribable) switch] throttle:0.5] distinctUntilChanged] select:^id(NSString *fileName) {
    if ([[fileName pathExtension] length] == 0)
      return [fileName stringByAppendingPathExtension:@"txt"];
    return fileName;
  }];
  
  // Validate file name and set the create button to enable
  [[[userInputFileNameSubscribable select:^id(id x) {
    return [NSNumber numberWithBool:[x length] && [(ACProjectFolder *)self.artCodeTab.currentItem childWithName:x] == nil];
  }] doNext:^(id x) {
    if ([x boolValue]) {
      self.infoLabel.text = @"A new blank file will be created. If no extension is specified, txt will be used.";
    } else {
      self.infoLabel.text = @"The speficied file already exists or is invalid.";
    }
  }] toProperty:RAC_KEYPATH_SELF(self.navigationItem.rightBarButtonItem.enabled) onObject:self];
  
  return self;
}

- (void)viewDidUnload {
  [self setFileNameTextField:nil];
  [self setInfoLabel:nil];
  [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  self.fileNameTextField.text = @"";
  [self.fileNameTextField becomeFirstResponder];
  self.infoLabel.text = @"A new blank file will be created. If no extension is specified, txt will be used.";
  // TODO if template is specified, set leftview for text field to template icon
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark Text Field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
  [textField resignFirstResponder];
  [self createAction:textField];
  return NO;
}

#pragma mark - Public Methods

- (IBAction)createAction:(id)sender
{
  [self startRightBarButtonItemActivityIndicator];
  
  NSString *fileName = self.fileNameTextField.text;
  // TODO use ArtCodeTemplate here
  if ([[fileName pathExtension] length] == 0)
    fileName = [fileName stringByAppendingPathExtension:@"txt"];
  
  ACProjectFolder *currentFolder = (ACProjectFolder *)self.artCodeTab.currentItem;
  [currentFolder addNewFileWithName:fileName originalURL:nil completionHandler:^(ACProjectFile *newFile, NSError *error) {
    [self stopRightBarButtonItemActivityIndicator];
    if (!error) {
      [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"New file created" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
    } else {
      self.infoLabel.text = [error localizedDescription];
    }
  }];
}

@end
