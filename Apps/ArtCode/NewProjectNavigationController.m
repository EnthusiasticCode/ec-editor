//
//  NewProjectNavigationController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 13/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NewProjectNavigationController.h"

@implementation NewProjectNavigationController

@synthesize projectsDirectory;
@synthesize popoverController;
@synthesize parentController;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
