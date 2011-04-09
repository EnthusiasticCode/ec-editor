//
//  ECPopoverView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPopoverView.h"
#import "UIImage+BlockDrawing.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

void CGPathAddRoundedRect(CGMutablePathRef path, CGAffineTransform *transform, CGRect rect, CGFloat radius)
{
    CGRect innerRect = CGRectInset(rect, radius, radius);
    
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    
    CGPathMoveToPoint(path, transform, innerRect.origin.x, outside_top);
    
    CGPathAddLineToPoint(path, transform, inside_right, outside_top);
    CGPathAddArcToPoint(path, transform, outside_right, outside_top, outside_right, inside_top, radius);
    CGPathAddLineToPoint(path, transform, outside_right, inside_bottom);
    CGPathAddArcToPoint(path, transform,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
    
    CGPathAddLineToPoint(path, transform, innerRect.origin.x, outside_bottom);
    CGPathAddArcToPoint(path, transform,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
    CGPathAddLineToPoint(path, transform, outside_left, inside_top);
    CGPathAddArcToPoint(path, transform,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
    
    CGPathCloseSubpath(path);
}

void CGContextAddRoundedRect(CGContextRef context, CGRect rect, CGFloat radius)
{
    CGRect innerRect = CGRectInset(rect, radius, radius);
    
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    
    CGContextMoveToPoint(context, innerRect.origin.x, outside_top);
    
    CGContextAddLineToPoint(context, inside_right, outside_top);
    CGContextAddArcToPoint(context, outside_right, outside_top, outside_right, inside_top, radius);
    CGContextAddLineToPoint(context, outside_right, inside_bottom);
    CGContextAddArcToPoint(context,  outside_right, outside_bottom, inside_right, outside_bottom, radius);
    
    CGContextAddLineToPoint(context, innerRect.origin.x, outside_bottom);
    CGContextAddArcToPoint(context,  outside_left, outside_bottom, outside_left, inside_bottom, radius);
    CGContextAddLineToPoint(context, outside_left, inside_top);
    CGContextAddArcToPoint(context,  outside_left, outside_top, innerRect.origin.x, outside_top, radius);
    
    CGContextClosePath(context);
}

@implementation ECPopoverView

#pragma mark -
#pragma mark Properties

@synthesize arrowDirection;
@synthesize arrowPosition;
@synthesize arrowSize;
@synthesize contentRect;

#pragma mark -
#pragma mark UIView Methods

static void init(ECPopoverView *self)
{
    self.arrowSize = 30;
    self.arrowPosition = 0;
    
    self.arrowDirection = UIPopoverArrowDirectionUp;
    self.backgroundColor = nil;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    const CGFloat inset = 2.0;
    rect = CGRectInset(rect, inset, inset);

    // Adding arrow
    if (arrowDirection > 0 && arrowDirection < UIPopoverArrowDirectionAny) 
    {
        CGRect arrowRect = CGRectMake(0, 0, arrowSize, arrowSize);
        CGPoint position;
        CGFloat rotation = M_PI_4;
        CGFloat arrowSize_2 = arrowSize / 2.0;
        CGFloat arrowInset = inset;
        if (arrowDirection <= UIPopoverArrowDirectionDown) 
        {
            rect.size.height -= arrowSize_2;
            if (arrowDirection & UIPopoverArrowDirectionDown)
            {
                arrowInset = rect.size.height - arrowSize_2 * M_SQRT2 - inset * 2;
            }
            else 
            {
                rect.origin.y += arrowSize_2;
            }
            if (arrowPosition < 1.0)
                position = CGPointMake(rect.size.width * arrowPosition, arrowInset);
            else if (arrowPosition >= rect.size.width)
                position = CGPointMake(rect.size.width - arrowSize * M_SQRT2 - inset * 2, arrowInset);
        }
        else
        {
            rotation = -M_PI_4;
            rect.size.width -= arrowSize_2;
            if (arrowDirection & UIPopoverArrowDirectionRight) 
            {
                arrowInset = rect.size.width - arrowSize_2 * M_SQRT2 - inset * 2;
            }
            else
            {
                rect.origin.x += arrowSize_2;
            }
            if (arrowPosition < 1.0)
                position = CGPointMake(arrowInset, rect.size.height * arrowPosition);
            else if (arrowPosition >= rect.size.height)
                position = CGPointMake(arrowInset, rect.size.height - arrowSize * M_SQRT2 - inset * 2);
        }
        CGAffineTransform arrowTransform = CGAffineTransformConcat(CGAffineTransformMakeRotation(rotation), CGAffineTransformMakeTranslation(position.x, position.y));
        CGPathAddRoundedRect(path, &arrowTransform, arrowRect, 3);
    }

    
    // Adding main rect
    CGPathAddRoundedRect(path, NULL, rect, 3);
    
    // Filling outiline
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:88.0/255.0 green:89.0/255.0 blue:91.0/255.0 alpha:0.3].CGColor);
    CGContextSetLineWidth(context, inset * 2);
    CGContextAddPath(context, path);
    CGContextStrokePath(context);
    
    // Fill main color
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:26.0/255.0 green:26.0/255.0 blue:26.0/255.0 alpha:1].CGColor);
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    
    // Calculate content rect
    contentRect = CGRectInset(rect, 4, 4);
    [self setNeedsLayout];
//    CGContextSetFillColorWithColor(context, self.superview.backgroundColor.CGColor);
//    CGContextAddRoundedRect(context, contentRect, 2);
//    CGContextFillPath(context);
//    
//    rect = CGRectInset(contentRect, 1, 1);
//    CGContextSetStrokeColorWithColor(context, [UIColor colorWithHue:0 saturation:0 brightness:0.7 alpha:0.5].CGColor);
//    CGContextAddRoundedRect(context, rect, 2);
//    CGContextSetLineWidth(context, 2);
//    CGContextStrokePath(context);
    
    CGPathRelease(path);
}

- (void)layoutSubviews
{
    for (UIView *sub in self.subviews) 
    {
        sub.frame = contentRect;
    }
}

@end
