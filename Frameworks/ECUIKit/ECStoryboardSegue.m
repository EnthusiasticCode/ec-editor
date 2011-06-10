//
//  ECStoryboardViewSegue.m
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECStoryboardSegue.h"

static const CGFloat ECStoryboardSegueAnimationDuration = 0.25;

@implementation ECStoryboardSegue

@synthesize exitingView = _exitingView;
@synthesize options = _options;

- (void)perform
{
    REQUIRE_NOT_NULL(self.exitingView);
    UIView *superView = self.exitingView.superview;
    REQUIRE_NOT_NULL(superView);
    [self.exitingView removeFromSuperview];
    [self.destinationViewController view].frame = self.exitingView.frame;
    [superView addSubview:[self.destinationViewController view]];
//    [UIView animateWithDuration:ECStoryboardSegueAnimationDuration delay:0.0 options:0 animations:^(void) {
//        <#code#>
//    } completion:^(BOOL finished) {
//        <#code#>
//    }];
}

@end
