//
//  ECStoryboardViewSegue.m
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECStoryboardFloatingSplitSidebarSegue.h"
#import "ECFloatingSplitViewController.h"

@implementation ECStoryboardFloatingSplitSidebarSegue

@synthesize transition = _transition;

- (void)perform
{
    [[self.sourceViewController floatingSplitViewController] setSidebarController:self.destinationViewController withTransition:self.transition];
}

@end
