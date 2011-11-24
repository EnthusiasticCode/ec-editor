//
//  ACCodeFileCompletionCell.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileCompletionCell.h"

@implementation ACCodeFileCompletionCell
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
    [self willChangeValueForKey:@"typeLabelSize"];
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
    [self didChangeValueForKey:@"typeLabelSize"];

}

@end
