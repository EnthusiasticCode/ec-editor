//
//  CodeFileCompletionCell.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFileCompletionCell.h"

@implementation CodeFileCompletionCell
@synthesize kindImageView;
@synthesize typeLabel;
@synthesize definitionLabel;

- (CGFloat)typeLabelSize
{
  return typeLabel.frame.size.width;
}

- (void)setTypeLabelSize:(CGFloat)value
{
  if ((typeLabel.superview != nil) ^ (value == 0) 
      || value == typeLabel.frame.size.width)
    return;
  if (value == 0)
  {
    definitionLabel.frame = CGRectUnion(definitionLabel.frame, typeLabel.frame);
    [typeLabel removeFromSuperview];
  }
  else
  {
    [self addSubview:typeLabel];
    CGRect frame = definitionLabel.frame;
    frame.size.width = value;
    typeLabel.frame = frame;
    frame.origin.x += value + 11;
    frame.size.width = definitionLabel.frame.size.width - value - 11;
    definitionLabel.frame = frame;
  }
}

@end
