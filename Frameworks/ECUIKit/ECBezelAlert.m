//
//  ECBezelAlert.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 23/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECBezelAlert.h"
#import <QuartzCore/QuartzCore.h>

#import "UIImage+BlockDrawing.h"

@implementation ECBezelAlert
@synthesize visibleTimeInterval;

#pragma mark - View Lifecycle

- (void)loadView
{
    // View background image
    CGFloat radius = 10;
    UIImage *bezelBackgroundImage = [[UIImage imageWithSize:CGSizeMake(radius * 2 + 1, radius * 2 + 1) block:^(CGContextRef ctx, CGRect rect) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0 alpha:0.5].CGColor);
        CGContextAddPath(ctx, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius].CGPath);
        CGContextFillPath(ctx);
    }] resizableImageWithCapInsets:UIEdgeInsetsMake(radius, radius, radius, radius)];
    
    // Create view
    UIView *bezelView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, radius * 3, radius * 3)];
    
}

@end
