//
//  NewFileFolderController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewFileFolderController.h"
#import "UIViewController+Utilities.h"
#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "BezelAlert.h"
#import "NSString+Utilities.h"
#import "NSURL+ArtCode.h"
#import "NSURL+Utilities.h"


@implementation NewFileFolderController

#pragma mark - View lifecycle

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self)
    return nil;
  
  self.artCodeTab = self.navigationController.artCodeTab;
  
  // RAC
  @weakify(self);
  
  // Signal to get the latest folder name or nil if the name is not valid
  [[[[[[[RACAble(self.folderNameTextField.rac_textSignal) switchToLatest] throttle:0.5] distinctUntilChanged] map:^id(NSString *x) {
    @strongify(self);
		if (x.length == 0) {
			return @"";
		}
    if (![NSFileManager.defaultManager fileExistsAtPath:[self.artCodeTab.currentLocation.url URLByAppendingPathComponent:x].path]) {
      return x;
    } else {
      return nil;
    }
  }] doNext:^(id x) {
    @strongify(self);
    self.infoLabel.text = x ? [NSString stringWithFormat:@"A new empty folder will be created in: %@.", [self.artCodeTab.currentLocation.url pathRelativeToURL:NSURL.projectsListDirectory].prettyPath] : @"The speficied folder name already exists or is invalid.";
  }] map:^id(id x) {
		return @([x length] != 0);
  }] toProperty:@keypath(self.navigationItem.rightBarButtonItem.enabled) onObject:self];
  
  return self;
}

- (void)viewDidLoad {
  self.artCodeTab = self.navigationController.artCodeTab;
  [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  self.folderNameTextField.text = @"";
  [self.folderNameTextField becomeFirstResponder];
  self.infoLabel.text = @"A new empty folder will be created.";
}

#pragma mark Text Field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  [self createAction:textField];
  return NO;
}

#pragma mark Public methods

- (IBAction)createAction:(id)sender {
  [[RCIODirectory itemWithURL:[self.artCodeTab.currentLocation.url URLByAppendingPathComponent:self.folderNameTextField.text] mode:RCIOItemModeExclusiveAccess] subscribeCompleted:^{
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    [BezelAlert.defaultBezelAlert addAlertMessageWithText:@"New folder created" imageNamed:BezelAlertOkIcon displayImmediatly:NO];
  }];
}
@end
