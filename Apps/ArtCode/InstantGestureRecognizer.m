//
//  InstantGestureRecognizer.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "InstantGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation InstantGestureRecognizer

@synthesize passTroughViews;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  UITouch *touch = [touches anyObject];
  for (UIView *view in self.passTroughViews)
  {
    if (CGRectContainsPoint(view.bounds, [touch locationInView:view]))
    {
      [self ignoreTouch:touch forEvent:event];
      return;
    }
  }
  self.state = UIGestureRecognizerStateRecognized;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
  return YES;
}

- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
  return NO;
}

@end
