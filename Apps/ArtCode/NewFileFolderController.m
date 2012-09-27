//
//  NewFileFolderController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewFileFolderController.h"
#import "UIViewController+Utilities.h"
#import "NSFileCoordinator+CoordinatedFileManagement.h"

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"
#import "BezelAlert.h"


@implementation NewFileFolderController

@synthesize folderNameTextField;
@synthesize infoLabel;

#pragma mark - View lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self)
    return nil;
  
  // RAC
  __weak NewFileFolderController *this = self;
  
  // Subscribable to get the latest folder name or nil if the name is not valid
  [[[[[[[RACAble(self.folderNameTextField.rac_textSubscribable) switch] throttle:0.5] distinctUntilChanged] select:^id(NSString *x) {
    if (x.length && ![[NSFileManager defaultManager] fileExistsAtPath:[this.artCodeTab.currentLocation.url URLByAppendingPathComponent:x].path]) {
      return x;
    } else {
      return nil;
    }
  }] doNext:^(id x) {
    this.infoLabel.text = x ? [NSString stringWithFormat:@"A new empty folder will be created in: %@.", this.artCodeTab.currentLocation.prettyPath] : @"The speficied folder name already exists or is invalid.";
  }] select:^id(id x) {
    return [NSNumber numberWithBool:x != nil];
  }] toProperty:RAC_KEYPATH_SELF(self.navigationItem.rightBarButtonItem.enabled) onObject:self];
  
  return self;
}

- (void)viewDidUnload
{
  [self setFolderNameTextField:nil];
  [self setInfoLabel:nil];
  [super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  self.folderNameTextField.text = @"";
  [self.folderNameTextField becomeFirstResponder];
  self.infoLabel.text = @"A new empty folder will be created.";
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

#pragma mark Public methods

- (IBAction)createAction:(id)sender {
  [NSFileCoordinator coordinatedMakeDirectoryAtURL:[self.artCodeTab.currentLocation.url URLByAppendingPathComponent:self.folderNameTextField.text] renameIfNeeded:NO completionHandler:^(NSError *error, NSURL *newURL) {
    if (!error) {
      [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"New folder created" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
    }
  }];
}
@end
