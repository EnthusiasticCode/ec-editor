//
//  NewFilePopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NewFileController.h"
#import "UIViewController+PresentingPopoverController.h"

#import "ArtCodeTab.h"
#import "BezelAlert.h"

@implementation NewFileController

@synthesize fileNameTextField;
@synthesize infoLabel;
@synthesize templateDirectoryURL;

#pragma mark - View lifecycle

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
    if ([fileName length] == 0)
    {
        self.infoLabel.text = @"A file name must be specified.";
        [self.fileNameTextField becomeFirstResponder];
        return;
    }
    // TODO use ArtCodeTemplate here
    if ([[fileName pathExtension] length] == 0)
        fileName = [fileName stringByAppendingPathExtension:@"txt"];
    // TODO the current url should have methods to retrieve the normalized, plain url ensuring that it's a folder
    NSFileManager *fileManager = [NSFileManager new];
    NSURL *fileURL = [self.artCodeTab.currentURL URLByAppendingPathComponent:fileName];
    if ([fileManager fileExistsAtPath:[fileURL path]])
    {
        self.infoLabel.text = [NSString stringWithFormat:@"The speficied file name (%@) already exists.", fileName];
        [self.fileNameTextField becomeFirstResponder];
        [self.fileNameTextField selectAll:nil];
        return;
    }
    // File creation
    NSError *err = nil;
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForReplacing error:&err byAccessor:^(NSURL *newURL) {
        [fileManager createFileAtPath:[newURL path] contents:nil attributes:nil];
    }];
    if (err)
    {
        self.infoLabel.text = [err localizedDescription];
        [self.fileNameTextField becomeFirstResponder];
        return;
    }
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"New file created" image:nil displayImmediatly:NO];
}

@end
