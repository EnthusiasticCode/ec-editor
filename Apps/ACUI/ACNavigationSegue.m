//
//  ACNavigationSegue.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNavigationSegue.h"
#import "ACNavigationController.h"

@implementation ACNavigationSegue

- (void)perform
{
    UIViewController *ancestor = self.sourceViewController;
    while (ancestor && ![ancestor isKindOfClass:[ACNavigationController class]])
        ancestor = [ancestor parentViewController];
    
    [(ACNavigationController *)ancestor pushViewController:self.destinationViewController animated:NO];
}

@end
