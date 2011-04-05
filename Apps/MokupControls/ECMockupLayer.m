//
//  ECMockupLayer.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECMockupLayer.h"


@interface ECMockupLayer () {
    CGMutablePathRef borderPath;
    CGFloat savedBorderWidth;
}

- (void)updateBorderPath;

@end

@implementation ECMockupLayer

@synthesize leftArrowSize, rightArrowSize;

- (void)setLeftArrowSize:(CGFloat)size
{
    leftArrowSize = size;
    [self updateBorderPath];
}

- (void)setRightArrowSize:(CGFloat)size
{
    rightArrowSize = size;
    [self updateBorderPath];
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    [super setCornerRadius:cornerRadius];
    [self updateBorderPath];
}

- (void)setBorderColor:(CGColorRef)borderColor
{
    [super setBorderColor:borderColor];
    [self updateBorderPath];
}

- (void)setBorderWidth:(CGFloat)borderWidth
{
    savedBorderWidth = borderWidth;
    [self updateBorderPath];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    [self updateBorderPath];
}

- (void)dealloc
{
    if (borderPath)
        CGPathRelease(borderPath);
    [super dealloc];
}

- (void)updateBorderPath
{
    // Release old path
    if (borderPath) {
        CGPathRelease(borderPath);
        borderPath = NULL;
    }
    
    if (leftArrowSize == 0 && rightArrowSize == 0)
    {
        [super setBorderWidth:savedBorderWidth];
    }
    else
    {
        [super setBorderWidth:0];
        
        CGFloat halfBorderWidth = savedBorderWidth / 2.0;
        CGRect rect = CGRectInset(self.bounds, halfBorderWidth, halfBorderWidth);
        if (CGRectIsEmpty(rect))
            return;
        
        borderPath = CGPathCreateMutable();
        
        CGFloat radius = self.cornerRadius;
        CGRect innerRect = CGRectInset(rect, radius, radius);
        
        CGFloat outside_right = rect.origin.x + rect.size.width;
        CGFloat outside_bottom = rect.origin.y + rect.size.height;
        CGFloat inside_left = innerRect.origin.x + leftArrowSize;
        CGFloat inside_right = innerRect.origin.x + innerRect.size.width - rightArrowSize;
        CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
        
        CGFloat inside_top = innerRect.origin.y;
        CGFloat outside_top = rect.origin.y;
        CGFloat outside_left = rect.origin.x;
        
        CGFloat middle_height = outside_bottom / 2.0;
        
        // TODO No top arrow for now
        CGPathMoveToPoint(borderPath, NULL, inside_left, outside_top);
        CGPathAddLineToPoint(borderPath, NULL, inside_right, outside_top);
        
        // Right arrow
        if (rightArrowSize > 0) 
        {
            CGFloat arrow_size = rightArrowSize * 0.3;
            CGFloat inside_arrow = inside_right + rightArrowSize + radius * 0.7;
            CGFloat arrow_midtop = middle_height - radius / 2;
            CGFloat arrow_midbottom = arrow_midtop + radius;
            CGPathAddCurveToPoint(borderPath, NULL,
                                  inside_right + arrow_size, outside_top, 
                                  inside_arrow, arrow_midtop, 
                                  inside_arrow, arrow_midtop);
            CGPathAddCurveToPoint(borderPath, NULL,
                                  outside_right, middle_height, 
                                  outside_right, middle_height, 
                                  inside_arrow, arrow_midbottom);
            CGPathAddCurveToPoint(borderPath, NULL,
                                  inside_arrow, arrow_midbottom, 
                                  inside_right + arrow_size, outside_bottom, 
                                  inside_right, outside_bottom);
        }
        else
        {
            CGPathAddArcToPoint(borderPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
            CGPathAddLineToPoint(borderPath, NULL, outside_right, inside_bottom);
            CGPathAddArcToPoint(borderPath, NULL, outside_right, outside_bottom, inside_right, outside_bottom, radius);
        }
        
        // TODO no bottom arrow
        CGPathAddLineToPoint(borderPath, NULL, inside_left, outside_bottom);
        
        // Left arrow
        if (leftArrowSize > 0) 
        {
            CGFloat arrow_size = leftArrowSize * 0.3;
            CGFloat inside_arrow = inside_left - leftArrowSize - radius * 0.7;
            CGFloat arrow_midtop = middle_height - radius / 2;
            CGFloat arrow_midbottom = arrow_midtop + radius;
            CGPathAddCurveToPoint(borderPath, NULL,
                                  inside_left - arrow_size, outside_bottom,
                                  inside_arrow, arrow_midbottom,
                                  inside_arrow, arrow_midbottom);
            CGPathAddCurveToPoint(borderPath, NULL,
                                  outside_left, middle_height, 
                                  outside_left, middle_height, 
                                  inside_arrow, arrow_midtop);
            CGPathAddCurveToPoint(borderPath, NULL, 
                                  inside_arrow, arrow_midtop, 
                                  inside_left - arrow_size, outside_top, 
                                  inside_left, outside_top);
        }
        else
        {
            CGPathAddArcToPoint(borderPath, NULL, outside_left, outside_bottom, outside_left, inside_bottom, radius);
            CGPathAddLineToPoint(borderPath, NULL, outside_left, inside_top);
            CGPathAddArcToPoint(borderPath, NULL, outside_left, outside_top, inside_left, outside_top, radius);
        }
        
        CGPathCloseSubpath(borderPath);
    }
    [self setNeedsDisplay];
}

- (void)drawInContext:(CGContextRef)ctx
{
    if (borderPath) 
    {
        CGColorRef color = self.backgroundColor;
        if (color) {
            CGContextSetFillColorWithColor(ctx, color);
            CGContextAddPath(ctx, borderPath);
            CGContextFillPath(ctx);
        }
        
        color = self.borderColor;
        if (color)
        {
            CGContextSetLineWidth(ctx, savedBorderWidth);
            CGContextSetStrokeColorWithColor(ctx, color);
            CGContextAddPath(ctx, borderPath);
            CGContextStrokePath(ctx);
        }
    }
}

- (CALayer *)hitTest:(CGPoint)p
{
    if (borderPath) 
    {
        if (CGPathContainsPoint(borderPath, NULL, p, NO))
            return self;
        return nil;
    }
    return [super hitTest:p];
}

@end
