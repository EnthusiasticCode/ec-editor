//
//  ACTabButton.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 14/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTabButton.h"
#import "AppStyle.h"

@implementation ACTabButton

@synthesize closeButton;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        closeButton = [UIButton new];
        closeButton.frame = CGRectMake(65, 0, 35, 40);
        closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        static UIImage *closeImageNormal = nil;
        if (!closeImageNormal)
            closeImageNormal = [UIImage styleCloseImageWithColor:[UIColor styleBackgroundColor] outlineColor:[UIColor styleForegroundColor] shadowColor:nil];
        [closeButton setImage:closeImageNormal forState:UIControlStateNormal];
        static UIImage *closeImageHighlighted = nil;
        if (!closeImageHighlighted)
            closeImageHighlighted = [UIImage styleCloseImageWithColor:[UIColor styleForegroundColor] outlineColor:[UIColor styleBackgroundColor] shadowColor:nil];
        [closeButton setImage:closeImageHighlighted forState:UIControlStateHighlighted];
        
        [self addSubview:closeButton];
    }
    return self;
}

@end
