//
//  MenuController.m
//  edit
//
//  Created by Uri Baghin on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MenuController.h"
#import "ECTripleSplitViewController.h"

@implementation MenuController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)hideSidebar:(id)sender
{
    [self.tripleSplitViewController setSidebarHidden:YES animated:YES];
}

- (IBAction)showSidebar:(id)sender
{
    [self.tripleSplitViewController setSidebarHidden:NO animated:YES];
}


@end
