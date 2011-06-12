//
//  ECStoryboardTripleSplitMainSegue.m
//  edit
//
//  Created by Uri Baghin on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECStoryboardTripleSplitMainSegue.h"
#import "ECTripleSplitViewController.h"

@implementation ECStoryboardTripleSplitMainSegue

@synthesize transition = _transition;

- (void)perform
{
    [[self.sourceViewController tripleSplitViewController] setMainController:self.destinationViewController withTransition:self.transition];
}

@end
