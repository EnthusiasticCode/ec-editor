//
//  NewFilePopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NewFileController.h"


@implementation NewFileController

@synthesize fileNameTextField;

#pragma mark - View lifecycle

- (void)viewDidUnload {
    [self setFileNameTextField:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Public Methods

- (IBAction)createAction:(id)sender {
}

@end
