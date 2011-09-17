//
//  ACEditorToolSelectionController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppStyle.h"
#import "ACEditorToolSelectionController.h"
#import "ECRoundedContentCornersView.h"

@implementation ACEditorToolSelectionController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for (UIView *subview in self.view.subviews)
    {
        if ([subview isKindOfClass:[ECRoundedContentCornersView class]])
        {
            [(ECRoundedContentCornersView *)subview setContentCornerRadius:4];
            subview.backgroundColor = [UIColor styleForegroundColor];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
