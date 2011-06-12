//
//  ECStoryboardTripleSplitMenuSegue.m
//  edit
//
//  Created by Uri Baghin on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECStoryboardTripleSplitMenuSegue.h"
#import "ECTripleSplitViewController.h"

@implementation ECStoryboardTripleSplitMenuSegue

@synthesize transition = _transition;

- (void)perform
{
    [[self.sourceViewController tripleSplitViewController] setMenuController:self.destinationViewController withTransition:self.transition];
}

@end
