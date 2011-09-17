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

#import "ACNavigationController.h"
#import "ECPopoverController.h"

@implementation ACEditorToolSelectionController

@synthesize targetNavigationController, containerPopoverController;

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

- (IBAction)tabsAction:(id)sender 
{
    [targetNavigationController.tabNavigationController toggleTabBar:sender];
    [containerPopoverController dismissPopoverAnimated:YES];
}
@end
