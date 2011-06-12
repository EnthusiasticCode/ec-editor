//
//  ECStoryboardViewSegue.m
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECStoryboardTripleSplitSidebarSegue.h"
#import "ECTripleSplitViewController.h"

@implementation ECStoryboardTripleSplitSidebarSegue

@synthesize transition = _transition;

- (void)perform
{
    [[self.sourceViewController tripleSplitViewController] setSidebarController:self.destinationViewController withTransition:self.transition];
}

@end
