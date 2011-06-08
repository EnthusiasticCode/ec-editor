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

@implementation FileController

@synthesize codeView;
@synthesize file;
@synthesize completionButton;

- (void)dealloc
{
    self.file = nil;
    self.codeView = nil;
    [completionButton release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated
{
    [codeView setNeedsLayout];
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.completionButton;
}

- (void)viewDidUnload
{
    [self setCompletionButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.codeView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)loadFile:(File *)aFile
{
    self.file = aFile;
    self.title = [aFile.path lastPathComponent];
    self.codeView.datasource = aFile;
}

- (IBAction)complete:(id)sender {
    [self.codeView showCompletionPopoverAtCursor];
}

@end
