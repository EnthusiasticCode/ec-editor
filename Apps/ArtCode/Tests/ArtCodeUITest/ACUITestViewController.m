//
//  ACUITestViewController.m
//  ArtCodeUITest
//
//  Created by Nicola Peduzzi on 16/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACUITestViewController.h"
#import "ACTopBarController.h"


@implementation ACUITestViewController
@synthesize toolbarView;

- (IBAction)changeToolbar:(id)sender {
    ACTopBarController *parent = self.topBarController;
    if (parent.currentToolbarView == toolbarView)
        [parent popToolbarViewAnimated:YES];
    else
        [parent pushToolbarView:toolbarView animated:YES];
}

- (IBAction)resizeToolbar:(id)sender {
    ACTopBarController *parent = self.topBarController;
    if (parent.toolbarHeight != 88)
        [parent setToolbarHeight:88 animated:YES];
    else
        [parent resetToolbarHeightAnimated:YES];
}
@end
