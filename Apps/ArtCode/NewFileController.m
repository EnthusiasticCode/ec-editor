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
  
  // RAC 
  __weak NewFileController *this = self;
  
  // Subscribable to get the latest filename with extension and activate 'create' button
  [[[[[[[RACAbleSelf(self.fileNameTextField.rac_textSubscribable) switch] throttle:0.5] distinctUntilChanged] select:^id(NSString *fileName) {
    if (fileName.length == 0)
      return nil;
    
    if ([[fileName pathExtension] length] == 0)
      fileName = [fileName stringByAppendingPathExtension:@"txt"];
    
    if ([(ACProjectFolder *)this.artCodeTab.currentItem childWithName:fileName] == nil) {
      return fileName;
    } else {
      return nil;
    }
  }] doNext:^(id x) {
    if (x) {
      this.infoLabel.text = @"A new blank file will be created. If no extension is specified, txt will be used.";
    } else {
      this.infoLabel.text = @"The speficied file already exists or is invalid.";
    }
  }] select:^id(id x) {
    return [NSNumber numberWithBool:x != nil];
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
  NSString *fileName = self.fileNameTextField.text;
  // TODO use ArtCodeTemplate here
  if ([[fileName pathExtension] length] == 0)
    fileName = [fileName stringByAppendingPathExtension:@"txt"];
  
  ACProjectFolder *currentFolder = (ACProjectFolder *)self.artCodeTab.currentItem;
  ACProjectFile *newFile = [currentFolder newChildFileWithName:fileName];
  if (newFile) {
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"New file created" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }
}

@end
