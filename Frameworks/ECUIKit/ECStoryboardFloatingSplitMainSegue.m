//
//  ECStoryboardFloatingSplitMainSegue.m
//  edit
//
//  Created by Uri Baghin on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECStoryboardFloatingSplitMainSegue.h"
#import "ECFloatingSplitViewController.h"

@implementation ECStoryboardFloatingSplitMainSegue

@synthesize transition = _transition;

- (void)perform
{
    UIViewController *ancestor = self.sourceViewController;
    while (![ancestor floatingSplitViewController] && [ancestor parentViewController])
        ancestor = [ancestor parentViewController];
    [[ancestor floatingSplitViewController] setMainController:self.destinationViewController withTransition:self.transition];
}

@end
