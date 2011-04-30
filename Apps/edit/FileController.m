//
//  FileViewController.m
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FileController.h"

#import <ECUIKit/ECCodeStringDataSource.h>

@implementation FileController

@synthesize codeView;
@synthesize file;

- (void)dealloc
{
    self.file = nil;
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.codeView.text = [NSString stringWithContentsOfFile:self.file encoding:NSUTF8StringEncoding error:nil];
//    ECCodeStringDataSource *codeSource = (ECCodeStringDataSource *)self.codeView.datasource;
}

- (void)viewDidAppear:(BOOL)animated
{
    [codeView setNeedsLayout];
}

- (void)viewDidUnload
{
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

- (void)loadFile:(NSString *)aFile
{
    self.file = aFile;
    self.title = [aFile lastPathComponent];
}

@end
