//
//  FileViewController.m
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileController.h"
#import "ECCodeView.h"
#import "File.h"
#import "Client.h"

@implementation FileController

@synthesize codeView;


- (void)viewDidAppear:(BOOL)animated
{
    [codeView setNeedsLayout];
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.codeView.datasource = [Client sharedClient].currentFile;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)complete:(id)sender {
    [self.codeView showCompletionPopoverAtCursor];
}

@end
