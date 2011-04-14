//
//  ECMockupButton.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECButton.h"
#import <QuartzCore/QuartzCore.h>


@implementation ECButton

#pragma mark -
#pragma mark Properties

@synthesize arrowSizes;
@synthesize borderColor;

- (void)setArrowSizes:(UIEdgeInsets)sizes
{
    arrowSizes = sizes;
    if (buttonPath) {
        CGPathRelease(buttonPath);
        buttonPath = NULL;
    }
    
    CALayer *layer = self.layer;
    if (UIEdgeInsetsEqualToEdgeInsets(arrowSizes, UIEdgeInsetsZero))
    {
        layer.masksToBounds = YES;
        layer.opaque = NO;
        layer.cornerRadius = 3;
        layer.borderWidth = 1;
        layer.borderColor = borderColor.CGColor;
    }
    else
    {
        layer.borderWidth = 0;
        
        buttonPath = CGPathCreateMutable();
        
        CGRect rect = CGRectInset(self.bounds, 0.5, 0.5);
        
        CGFloat radius = 3;
        CGRect innerRect = CGRectInset(rect, radius, radius);
        
        CGFloat outside_right = rect.origin.x + rect.size.width;
        CGFloat outside_bottom = rect.origin.y + rect.size.height;
        CGFloat inside_left = innerRect.origin.x + arrowSizes.left;
        CGFloat inside_right = innerRect.origin.x + innerRect.size.width - arrowSizes.right;
        CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
        
        CGFloat inside_top = innerRect.origin.y;
        CGFloat outside_top = rect.origin.y;
        CGFloat outside_left = rect.origin.x;
        
        //        CGFloat middle_width = outside_right / 2.0;
        CGFloat middle_height = outside_bottom / 2.0;
        
        // TODO No top arrow for now
        CGPathMoveToPoint(buttonPath, NULL, inside_left, outside_top);
        CGPathAddLineToPoint(buttonPath, NULL, inside_right, outside_top);
        
        // Right arrow
        if (arrowSizes.right > 0) 
        {
            CGFloat arrow_size = arrowSizes.right * 0.3;
            CGFloat inside_arrow = inside_right + arrowSizes.right + radius * 0.7;
            CGFloat arrow_midtop = middle_height - radius / 2;
            CGFloat arrow_midbottom = arrow_midtop + radius;
            CGPathAddCurveToPoint(buttonPath, NULL,
                                  inside_right + arrow_size, outside_top, 
                                  inside_arrow, arrow_midtop, 
                                  inside_arrow, arrow_midtop);
            CGPathAddCurveToPoint(buttonPath, NULL,
                                  outside_right, middle_height, 
                                  outside_right, middle_height, 
                                  inside_arrow, arrow_midbottom);
            CGPathAddCurveToPoint(buttonPath, NULL,
                                  inside_arrow, arrow_midbottom, 
                                  inside_right + arrow_size, outside_bottom, 
                                  inside_right, outside_bottom);
        }
        else
        {
            CGPathAddArcToPoint(buttonPath, NULL, outside_right, outside_top, outside_right, inside_top, radius);
            CGPathAddLineToPoint(buttonPath, NULL, outside_right, inside_bottom);
            CGPathAddArcToPoint(buttonPath, NULL, outside_right, outside_bottom, inside_right, outside_bottom, radius);
        }
        
        // TODO no bottom arrow
        CGPathAddLineToPoint(buttonPath, NULL, inside_left, outside_bottom);
        
        // Left arrow
        if (arrowSizes.left > 0) 
        {
            CGFloat arrow_size = arrowSizes.left * 0.3;
            CGFloat inside_arrow = inside_left - arrowSizes.left - radius * 0.7;
            CGFloat arrow_midtop = middle_height - radius / 2;
            CGFloat arrow_midbottom = arrow_midtop + radius;
            CGPathAddCurveToPoint(buttonPath, NULL,
                                  inside_left - arrow_size, outside_bottom,
                                  inside_arrow, arrow_midbottom,
                                  inside_arrow, arrow_midbottom);
            CGPathAddCurveToPoint(buttonPath, NULL,
                                  outside_left, middle_height, 
                                  outside_left, middle_height, 
                                  inside_arrow, arrow_midtop);
            CGPathAddCurveToPoint(buttonPath, NULL, 
                                  inside_arrow, arrow_midtop, 
                                  inside_left - arrow_size, outside_top, 
                                  inside_left, outside_top);
        }
        else
        {
            CGPathAddArcToPoint(buttonPath, NULL, outside_left, outside_bottom, outside_left, inside_bottom, radius);
            CGPathAddLineToPoint(buttonPath, NULL, outside_left, inside_top);
            CGPathAddArcToPoint(buttonPath, NULL, outside_left, outside_top, inside_left, outside_top, radius);
        }
        
        CGPathCloseSubpath(buttonPath);
    }
    [self.layer setNeedsDisplay];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.arrowSizes = arrowSizes;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    self.arrowSizes = arrowSizes;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (buttonPath)
    {
        [self setNeedsDisplay];
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (buttonPath)
    {
        [self setNeedsDisplay];
    }
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    if (buttonPath)
    {
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark UIButton Methods

static void init(ECButton *self)
{
    self.borderColor = [UIColor colorWithHue:0 saturation:0 brightness:0.01 alpha:1];
    self.arrowSizes = UIEdgeInsetsZero;
    
    self->backgroundColors = [[NSMutableArray arrayWithObjects:
                              [NSNull null], 
                              [UIColor colorWithRed:93.0/255.0 green:94.0/255.0 blue:94.0/255.0 alpha:1.0],
                              [NSNull null],
                              [UIColor colorWithRed:64.0/255.0 green:92.0/255.0 blue:123.0/255.0 alpha:1.0], nil] retain];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    if (buttonPath) {
        CGPathRelease(buttonPath);
    }
    self.borderColor = nil;
    [backgroundColors release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    if (buttonPath)
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Fill
        UIColor *bgcolor;
        if ((NSNull *)(bgcolor = [self backgroundColorForState:self.state]) != [NSNull null])
        {
            [bgcolor setFill];
            CGContextAddPath(context, buttonPath);
            CGContextFillPath(context);
        }
        
        // Stroke
        if (borderColor)
        {
            [borderColor setStroke];
            CGContextAddPath(context, buttonPath);
            CGContextStrokePath(context);
        }
    }
}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    UIColor *bgcolor;
    if (!buttonPath
        && (NSNull *)(bgcolor = [self backgroundColorForState:self.state]) != [NSNull null])
    {
        self.layer.backgroundColor = bgcolor.CGColor;
    }
    else
    {
        self.layer.backgroundColor = NULL;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.hidden)
        return nil;
    if (buttonPath) 
    {
        if (CGPathContainsPoint(buttonPath, NULL, point, NO))
            return self;
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

#pragma mark -
#pragma mark Public methods

- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    NSUInteger index = 0;
    if (state & UIControlStateHighlighted) {
        index = 1;
    }
    else if (state & UIControlStateSelected) {
        index = 3;
    }
    else if (state & UIControlStateDisabled) {
        index = 2;
    }
    [backgroundColors replaceObjectAtIndex:index withObject:color];
}

- (UIColor *)backgroundColorForState:(UIControlState)state
{
    NSUInteger index = 0;
    if (state & UIControlStateHighlighted) {
        index = 1;
    }
    else if (state & UIControlStateSelected) {
        index = 3;
    }
    else if (state & UIControlStateDisabled) {
        index = 2;
    }
    return [backgroundColors objectAtIndex:index];
}

@end
