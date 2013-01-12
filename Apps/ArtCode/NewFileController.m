//
//  NewFilePopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NewFileController.h"
#import "UIViewController+Utilities.h"
#import "FileSystemFile.h"

#import "ArtCodeTab.h"
#import "ArtCodeProject.h"
#import "BezelAlert.h"

#import "ArtCodeLocation.h"


@implementation NewFileController

@synthesize fileNameTextField;
@synthesize infoLabel;
@synthesize templateDirectoryURL;

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.artCodeTab = self.navigationController.artCodeTab;
  
  // RAC
  @weakify(self);
  
  // Signal to get the latest filename with extension and activate 'create' button
  [[[[[[self.fileNameTextField.rac_textSignal throttle:0.5] distinctUntilChanged] map:^id(NSString *fileName) {
    @strongify(self);
    if (fileName.length == 0) {
      return @"";
    }
    
    if ([[fileName pathExtension] length] == 0) {
      fileName = [fileName stringByAppendingPathExtension:@"txt"];
    }
    
    if ( ! [NSFileManager.defaultManager fileExistsAtPath:[self.artCodeTab.currentLocation.url URLByAppendingPathComponent:fileName].path]) {
      return fileName;
    } else {
      return nil;
    }
  }] doNext:^(id x) {
    @strongify(self);
    if (x) {
      self.infoLabel.text = @"A new blank file will be created. If no extension is specified, txt will be used.";
    } else {
      self.infoLabel.text = @"The speficied file already exists or is invalid.";
    }
  }] map:^id(id x) {
		return @([x length] != 0);
  }] toProperty:@keypath(self.navigationItem.rightBarButtonItem.enabled) onObject:self];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.fileNameTextField.text = @"";
  [self.fileNameTextField becomeFirstResponder];
  self.infoLabel.text = @"A new blank file will be created. If no extension is specified, txt will be used.";
  // TODO: if template is specified, set leftview for text field to template icon
}

#pragma mark Text Field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  [self createAction:textField];
  return NO;
}

#pragma mark - Public Methods

- (IBAction)createAction:(id)sender {
  NSString *fileName = self.fileNameTextField.text;
  // TODO: use ArtCodeTemplate here
  if ([[fileName pathExtension] length] == 0) {
    fileName = [fileName stringByAppendingPathExtension:@"txt"];
  }
  
  [[[FileSystemFile itemWithURL:[self.artCodeTab.currentLocation.url URLByAppendingPathComponent:fileName]] flattenMap:^(FileSystemFile *file) {
		return [file create];
	}] subscribeCompleted:^{
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"New file created" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }];
}

@end
