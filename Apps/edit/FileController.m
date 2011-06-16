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

@interface FileController ()
- (void)handleFileChangedNotification:(NSNotification *)notification;
@end

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFileChangedNotification:) name:ClientCurrentFileChangedNotification object:nil];
    self.codeView.datasource = [Client sharedClient].currentFile;
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)handleFileChangedNotification:(NSNotification *)notification
{
    self.codeView.datasource = [notification.userInfo objectForKey:ClientNewFileKey];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)complete:(id)sender {
    [self.codeView showCompletionPopoverAtCursor];
}

@end
