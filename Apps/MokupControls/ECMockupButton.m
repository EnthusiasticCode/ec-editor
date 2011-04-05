//
//  ECMockupButton.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECMockupButton.h"
#import <QuartzCore/QuartzCore.h>


@implementation ECMockupButton

#pragma mark -
#pragma mark Properties

@synthesize arrowSizes;
@synthesize borderColor;

- (void)setArrowSizes:(UIEdgeInsets)sizes
{
    arrowSizes = sizes;
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
    }
    [self.layer setNeedsDisplay];
}

#pragma mark -
#pragma mark UIButton Methods

static void init(ECMockupButton *self)
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

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if (layer == self.layer && !UIEdgeInsetsEqualToEdgeInsets(arrowSizes, UIEdgeInsetsZero))
    {
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
        CGContextMoveToPoint(context, inside_left, outside_top);
        CGContextAddLineToPoint(context, inside_right, outside_top);
        
        // Right arrow
        if (arrowSizes.right > 0) 
        {
            CGFloat arrow_size = arrowSizes.right * 0.3;
            CGFloat inside_arrow = inside_right + arrowSizes.right + radius * 0.7;
            CGFloat arrow_midtop = middle_height - radius / 2;
            CGFloat arrow_midbottom = arrow_midtop + radius;
            CGContextAddCurveToPoint(context, 
                                     inside_right + arrow_size, outside_top, 
                                     inside_arrow, arrow_midtop, 
                                     inside_arrow, arrow_midtop);
            CGContextAddCurveToPoint(context, 
                                     outside_right, middle_height, 
                                     outside_right, middle_height, 
                                     inside_arrow, arrow_midbottom);
            CGContextAddCurveToPoint(context, 
                                     inside_arrow, arrow_midbottom, 
                                     inside_right + arrow_size, outside_bottom, 
                                     inside_right, outside_bottom);
        }
        else
        {
            CGContextAddArcToPoint(context, outside_right, outside_top, outside_right, inside_top, radius);
            CGContextAddLineToPoint(context, outside_right, inside_bottom);
            CGContextAddArcToPoint(context, outside_right, outside_bottom, inside_right, outside_bottom, radius);
        }
        
        // TODO no bottom arrow
        CGContextAddLineToPoint(context, inside_left, outside_bottom);
        
        // Left arrow
        if (arrowSizes.left > 0) 
        {
            CGFloat arrow_size = arrowSizes.left * 0.3;
            CGFloat inside_arrow = inside_left - arrowSizes.left - radius * 0.7;
            CGFloat arrow_midtop = middle_height - radius / 2;
            CGFloat arrow_midbottom = arrow_midtop + radius;
            CGContextAddCurveToPoint(context, 
                                     inside_left - arrow_size, outside_bottom,
                                     inside_arrow, arrow_midbottom,
                                     inside_arrow, arrow_midbottom);
            CGContextAddCurveToPoint(context, 
                                     outside_left, middle_height, 
                                     outside_left, middle_height, 
                                     inside_arrow, arrow_midtop);
            CGContextAddCurveToPoint(context, 
                                     inside_arrow, arrow_midtop, 
                                     inside_left - arrow_size, outside_top, 
                                     inside_left, outside_top);
        }
        else
        {
            CGContextAddArcToPoint(context, outside_left, outside_bottom, outside_left, inside_bottom, radius);
            CGContextAddLineToPoint(context, outside_left, inside_top);
            CGContextAddArcToPoint(context, outside_left, outside_top, inside_left, outside_top, radius);
        }
        
        CGContextClosePath(context);
        
        [borderColor setStroke];
        CGContextStrokePath(context);
    }
    else 
    {
        //[super drawLayer:layer inContext:context];
    }
}

- (void)layoutSubviews 
{
    [super layoutSubviews];
    
    UIColor *bgcolor = [self backgroundColorForState:self.state];
    if ((NSNull *)bgcolor == [NSNull null])
    {
        self.layer.backgroundColor = NULL;
    }
    else
    {
        self.layer.backgroundColor = bgcolor.CGColor;
    }
}

- (void)dealloc
{
    self.borderColor = nil;
    [backgroundColors release];
    [super dealloc];
}

#pragma mark -
#pragma mark Public methods

- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state
{
    NSUInteger index;
    switch (state) {
        case UIControlStateHighlighted:
            index = 1;
            break;
        case UIControlStateDisabled:
            index = 2;
            break;
            
        case UIControlStateSelected:
            index = 3;
            break;
            
        default:
            index = 0;
            break;
    }
    [backgroundColors replaceObjectAtIndex:index withObject:color];
}

- (UIColor *)backgroundColorForState:(UIControlState)state
{
    NSUInteger index;
    switch (state) {
        case UIControlStateHighlighted:
            index = 1;
            break;
        case UIControlStateDisabled:
            index = 2;
            break;
            
        case UIControlStateSelected:
            index = 3;
            break;
            
        default:
            index = 0;
            break;
    }
    return [backgroundColors objectAtIndex:index];
}

@end
