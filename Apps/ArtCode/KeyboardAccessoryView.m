//
//  SplittableAccessoryView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 08/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "KeyboardAccessoryView.h"

#define SPLIT_KEYBOARD_LEFT_SEGMENT_WIDTH 256
#define SPLIT_KEYBOARD_RIGHT_SEGMENT_WIDTH 281
#define PORTRAIT_KEYBOARD_WIDTH 768

@implementation KeyboardAccessoryView

#pragma mark - Properties

@synthesize split, flipped;
@synthesize dockedBackgroundView, splitLeftBackgroundView, splitRightBackgroundView, splitBackgroundViewInsets;

- (void)setDockedBackgroundView:(UIView *)value
{
  if (value == dockedBackgroundView)
    return;
  if (!self.isSplit)
  {
    [dockedBackgroundView removeFromSuperview];
    if (value)
      [self insertSubview:value atIndex:0];
  }
  dockedBackgroundView = value;
}

- (void)setSplit:(BOOL)value
{
  if (value == split)
    return;
  
  split = value;
  if (split)
  {
    [dockedBackgroundView removeFromSuperview];
    [self insertSubview:self.splitLeftBackgroundView atIndex:0];
    [self insertSubview:self.splitRightBackgroundView atIndex:0];
  }
  else
  {
    [splitLeftBackgroundView removeFromSuperview];
    [splitRightBackgroundView removeFromSuperview];
    [self insertSubview:self.dockedBackgroundView atIndex:0];
  }
}

#pragma mark - View Methods

- (void)layoutSubviews
{
  if ([self currentAccessoryPosition] >= KeyboardAccessoryPositionFloating && splitLeftBackgroundView && splitRightBackgroundView)
  {
    CGRect bounds = self.bounds;
    UIEdgeInsets insets = self.splitBackgroundViewInsets;
    if (self.isFlipped)
    {
      self.splitLeftBackgroundView.transform = self.splitRightBackgroundView.transform = CGAffineTransformMakeScale(1, -1);
      insets.top = splitBackgroundViewInsets.bottom;
      insets.bottom = splitBackgroundViewInsets.top;
    }
    else
    {
      self.splitLeftBackgroundView.transform = self.splitRightBackgroundView.transform = CGAffineTransformIdentity;
    }
    self.splitLeftBackgroundView.frame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, SPLIT_KEYBOARD_LEFT_SEGMENT_WIDTH, bounds.size.height), insets);
    self.splitRightBackgroundView.frame = UIEdgeInsetsInsetRect(CGRectMake(bounds.size.width - SPLIT_KEYBOARD_RIGHT_SEGMENT_WIDTH, 0, SPLIT_KEYBOARD_RIGHT_SEGMENT_WIDTH, bounds.size.height), insets);
  }
  else if (self.dockedBackgroundView)
  {
    self.dockedBackgroundView.frame = self.bounds;
  }
}

#pragma mark - Accessory Methods

- (KeyboardAccessoryPosition)currentAccessoryPosition
{
  if (self.isSplit)
    return KeyboardAccessoryPositionFloating;
  if (self.frame.size.width > PORTRAIT_KEYBOARD_WIDTH)
    return KeyboardAccessoryPositionLandscape;
  return KeyboardAccessoryPositionPortrait;
}

@end
