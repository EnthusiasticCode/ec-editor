//
//  ACHighlightTableViewCell.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACHighlightTableViewCell.h"

@implementation ACHighlightTableViewCell

@synthesize highlightLabel;

- (ACHighlightLabel *)highlightLabel
{
    if (!highlightLabel)
    {
        highlightLabel = [ACHighlightLabel new];
        highlightLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        highlightLabel.frame = CGRectInset([self.contentView bounds], 40, 0);
        highlightLabel.backgroundColor = [UIColor clearColor];
        highlightLabel.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:highlightLabel];
    }
    return highlightLabel;
}

- (UILabel *)textLabel
{
    return self.highlightLabel;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    [self.highlightLabel setHighlighted:highlighted];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self.highlightLabel setHighlighted:selected];
}

@end
