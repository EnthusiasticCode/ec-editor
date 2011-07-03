//
//  ACToolPanelSegue.m
//  ACUI
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACToolPanelSegue.h"
#import "ACToolPanelController.h"

@implementation ACToolPanelSegue

- (void)perform
{
    UIViewController *ancestor = self.sourceViewController;
    while (ancestor && ![ancestor isKindOfClass:[ACToolPanelController class]])
        ancestor = [ancestor parentViewController];
    
    [(ACToolPanelController *)ancestor setSelectedViewController:self.destinationViewController animated:YES];
}

@end
