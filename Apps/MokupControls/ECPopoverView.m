//
//  ECPopoverView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPopoverView.h"
#import "UIImage+BlockDrawing.h"

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

static UIImage *defaultFillImage = nil;

#pragma mark -
#pragma mark UIView Methods

static void init(ECPopoverView *self)
{
    if (!defaultFillImage)
    {
        defaultFillImage = [[[UIImage imageWithSize:(CGSize){ 11, 11 } block:^(CGContextRef ctx, CGRect rect) {
            CGMutablePathRef path = CGPathCreateMutable();
            CGPathAddRoundedRect(path, NULL, rect, 3);
            
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.5 alpha:0.3].CGColor);
            CGContextAddPath(ctx, path);
            CGContextFillPath(ctx);
            
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithHue:0 saturation:0 brightness:0.1 alpha:1].CGColor);
            CGContextTranslateCTM(ctx, 2, 2);
            CGContextScaleCTM(ctx, 2.0/3.0, 2.0/3.0);
            CGContextAddPath(ctx, path);
            CGContextFillPath(ctx);
            
            CGPathRelease(path);
        }] stretchableImageWithLeftCapWidth:5 topCapHeight:5] retain];
    }

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
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGContextDrawImage(context, rect, defaultFillImage.CGImage);
    [defaultFillImage drawInRect:rect];
}

@end
