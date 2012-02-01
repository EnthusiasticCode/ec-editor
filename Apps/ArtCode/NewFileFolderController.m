//
//  NewFileFolderController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewFileFolderController.h"
#import "UIViewController+PresentingPopoverController.h"

#import "ArtCodeTab.h"
#import "ArtCodeURL.h"
#import "BezelAlert.h"


@implementation NewFileFolderController

@synthesize folderNameTextField;
@synthesize infoLabel;

#pragma mark - View lifecycle

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
    self.infoLabel.text = [NSString stringWithFormat:@"A new empty folder will be created in: %@.", [self.artCodeTab.currentURL prettyPathRelativeToProjectDirectory]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark Public methods

- (IBAction)createAction:(id)sender
{
    NSString *folderName = self.folderNameTextField.text;
    if ([folderName length] == 0)
    {
        self.infoLabel.text = @"A folder name must be specified.";
        [self.folderNameTextField becomeFirstResponder];
        return;
    }
    // Check for directory validity
    NSFileManager *fileManager = [NSFileManager new];
    NSURL *folderURL = [self.artCodeTab.currentURL URLByAppendingPathComponent:folderName];
    if ([fileManager fileExistsAtPath:[folderURL path]])
    {
        self.infoLabel.text = [NSString stringWithFormat:@"The speficied folder name (%@) already exists.", folderName];
        [self.folderNameTextField becomeFirstResponder];
        [self.folderNameTextField selectAll:nil];
        return;
    }
    // File creation
    __block NSError *err = nil;
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:folderURL options:NSFileCoordinatorWritingForReplacing error:&err byAccessor:^(NSURL *newURL) {
        [fileManager createDirectoryAtPath:[newURL path] withIntermediateDirectories:NO attributes:nil error:&err];
    }];
    if (err)
    {
        self.infoLabel.text = [err localizedDescription];
        [self.folderNameTextField becomeFirstResponder];
        return;
    }
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"New folder created" image:nil displayImmediatly:NO];
}
@end
