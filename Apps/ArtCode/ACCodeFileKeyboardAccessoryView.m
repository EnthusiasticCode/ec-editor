//
//  ACCodeFileKeyboardAccessoryView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryView.h"

@implementation ACCodeFileKeyboardAccessoryView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    
    // Setup backgrounds
    self.dockedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundDocked"]];
    UIImageView *splitBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundSplitLeftTop"]];
    splitBackgroundView.contentMode = UIViewContentModeTopLeft;
    self.splitLeftBackgroundView = splitBackgroundView;
    splitBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundSplitRightTop"]];
    splitBackgroundView.contentMode = UIViewContentModeTopRight;
    self.splitRightBackgroundView = splitBackgroundView;
    self.splitBackgroundViewInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
    
    return self;
}


@end
