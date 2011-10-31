//
//  ACCodeFileSearchBarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileSearchBarController.h"
#import "ACSingleTabController.h"

@implementation ACCodeFileSearchBarController

#pragma mark - Properties

@synthesize findTextField;

#pragma mark - View Lifecycle

- (void)viewDidUnload {
    [self setFindTextField:nil];
    [super viewDidUnload];
}

#pragma mark - Action Methods

- (IBAction)moveResultAction:(id)sender {
}

- (IBAction)toggleReplaceAction:(id)sender {
}

- (IBAction)closeBarAction:(id)sender {
    ECASSERT(self.singleTabController.toolbarViewController == self);
    [self.singleTabController setToolbarViewController:nil animated:YES];
}

@end
