//
//  ECSwipeGestureRecognizer.m
//  ACUI
//
//  Created by Nicola Peduzzi on 25/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECSwipeGestureRecognizer.h"

@implementation ECSwipeGestureRecognizer

@synthesize numberOfTouchesRequiredImmediatlyOrFailAfterInterval;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    beginTimestamp = [event timestamp];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (numberOfTouchesRequiredImmediatlyOrFailAfterInterval > 0.
        && [touches count] != self.numberOfTouchesRequired
        && [event timestamp] - beginTimestamp >= numberOfTouchesRequiredImmediatlyOrFailAfterInterval)
    {
        for (UITouch *touch in touches)
            [self ignoreTouch:touch forEvent:event];
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    [super touchesMoved:touches withEvent:event];
}

@end
