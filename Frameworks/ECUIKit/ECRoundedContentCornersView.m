//
//  ECRoundedContentCornersView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 16/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECRoundedContentCornersView.h"
#import <QuartzCore/QuartzCore.h>


@implementation ECRoundedContentCornersView {
    CAShapeLayer *contentCorners[4];
}

static void updateContentCorners(ECRoundedContentCornersView *self);

#pragma mark - Properties

@synthesize contentCornerRadius, contentInsets, clipContent;

#warning TODO remove content instets. Popover view will need to have one of this view as a subview instead of deriving from it.
- (void)setContentInsets:(UIEdgeInsets)insets
{
    contentInsets = insets;
    [self setNeedsLayout];
}

- (void)setContentCornerRadius:(CGFloat)radius
{
    if (radius == contentCornerRadius)
        return;
    
    contentCornerRadius = radius;
    
    updateContentCorners(self);
}

- (void)setClipContent:(BOOL)value
{
    if (clipContent == value)
        return;
    
    clipContent = value;
    self.layer.masksToBounds = clipContent;
    
    updateContentCorners(self);
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    CGColorRef color = backgroundColor.CGColor;
    if (contentCornerRadius > 0)
    {
        for (int i = 0; i < 4; ++ i)
        {
            contentCorners[i].fillColor = color;
        }
    }
    [super setBackgroundColor:backgroundColor];
}

#pragma mark - View lifecycle

- (void)layoutSubviews
{
    [CALayer layer];
    if (contentCorners[0] != nil)
    {
        CGRect cornersRect = CGRectInset(UIEdgeInsetsInsetRect(self.bounds, contentInsets), -.5, -.5);
        for (int i = 0; i < 4; ++i)
        {
            contentCorners[i].position = (CGPoint){
                (i && i < 3) ? CGRectGetMaxX(cornersRect) : cornersRect.origin.x,
                (i < 2) ? cornersRect.origin.y : CGRectGetMaxY(cornersRect)
            };
        }
    }
}

#pragma mark - Private Functions

static void updateContentCorners(ECRoundedContentCornersView *self)
{
    CGFloat radius = self->contentCornerRadius;
    
    // Remove from layer if no content corner radius or clipping
    if (radius == 0 || self->clipContent)
    {
        // Remove corner layers
        for (int i = 0; i < 4; ++i)
        {
            [self->contentCorners[i] removeFromSuperlayer];
            self->contentCorners[i] = nil;
        }
        
        // Apply clipping
        if (self->clipContent)
        {
            self.layer.cornerRadius = radius;
        }
        
        return;
    }
    else if (!self->clipContent)
    {
        self.layer.cornerRadius = 0;
    }
    
    // Create top left inverse corner shape
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, radius);
    CGPathAddLineToPoint(path, NULL, 0, 0);
    CGPathAddLineToPoint(path, NULL, radius, 0);
    CGPathAddArcToPoint(path, NULL, 0, 0, 0, radius, radius);
    
    CGColorRef backgroundColor = self.backgroundColor.CGColor;
    
    // Create layers
    for (int i = 0; i < 4; ++i)
    {
        if (!self->contentCorners[i])
            self->contentCorners[i] = [CAShapeLayer layer];
        self->contentCorners[i].affineTransform = CGAffineTransformMakeRotation(M_PI_2 * i);
        self->contentCorners[i].path = path;
        self->contentCorners[i].fillColor = backgroundColor;
        self->contentCorners[i].zPosition = 100;
        [self.layer addSublayer:self->contentCorners[i]];
    }
    
    CGPathRelease(path);
    
    [self setNeedsLayout];
}

@end
