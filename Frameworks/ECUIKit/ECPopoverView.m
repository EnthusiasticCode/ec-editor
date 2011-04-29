//
//  ECPopoverView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPopoverView.h"
#import "UIColor+StyleColors.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

#define ARROW_CORNER_RADIUS 3

@interface ECPopoverView () {
@private
    CAShapeLayer *arrowLayer;
    CGFloat arrowOffset;
    CGRect contentRect;
}

- (void)layoutArrow;

@end


@implementation ECPopoverView

#pragma mark -
#pragma mark Properties

@synthesize cornerRadius;

@synthesize contentInsets;

@synthesize arrowDirection;
@synthesize arrowPosition;
@synthesize arrowSize;

- (void)setContentInsets:(UIEdgeInsets)insets
{
    contentInsets = insets;
    contentRect = UIEdgeInsetsInsetRect(self.bounds, insets);
    [self layoutIfNeeded];
}

- (CGSize)contentSize
{
    return contentRect.size;
}

- (void)setContentSize:(CGSize)size
{
    if (CGSizeEqualToSize(size, contentRect.size))
        return;
    
    [self setBounds:(CGRect){ CGPointZero, {
        size.width + contentInsets.left + contentInsets.right,
        size.height + contentInsets.top + contentInsets.bottom
    } }];
}

- (UIView *)contentView
{
    return [self.subviews objectAtIndex:0];
}

- (void)setContentView:(UIView *)contentView
{
    [self.contentView removeFromSuperview];
    [self insertSubview:contentView atIndex:0];
}

- (void)setArrowPosition:(CGFloat)position
{
    if (position < 0 || position > 1) 
        return;

    arrowPosition = position;
    [self layoutArrow];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)direction
{
    if (arrowDirection == direction)
        return;
    
    arrowDirection = direction;
    [self layoutArrow];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    contentRect = UIEdgeInsetsInsetRect(bounds, contentInsets);
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    contentRect = UIEdgeInsetsInsetRect(self.bounds, contentInsets);
}

#pragma mark -
#pragma mark UIView Methods

static void preinit(ECPopoverView *self)
{
    self->arrowSize = 30;
    self->arrowPosition = 0.5;
    self->arrowDirection = UIPopoverArrowDirectionUp;
    self->arrowOffset = self->arrowSize / M_SQRT2 - ARROW_CORNER_RADIUS;
    
    self->cornerRadius = 5;
    
    self->contentInsets = UIEdgeInsetsMake(5, 5, 5, 5);
}

static void init(ECPopoverView *self)
{
    CAShapeLayer *layer = (CAShapeLayer *)self.layer;
    
    self->arrowLayer = [CAShapeLayer new];
    self->arrowLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self->arrowSize, self->arrowSize) cornerRadius:ARROW_CORNER_RADIUS].CGPath;
    self->arrowLayer.transform = CATransform3DMakeRotation(M_PI_4, 0, 0, 1);
    self->arrowLayer.backgroundColor = layer.backgroundColor;
    
    layer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.cornerRadius].CGPath;
    [layer insertSublayer:self->arrowLayer atIndex:0];
    [self layoutArrow];
    
    self->contentRect = UIEdgeInsetsInsetRect(self.bounds, self->contentInsets);
}

- (id)initWithFrame:(CGRect)frame
{
    preinit(self);
    if ((self = [super initWithFrame:frame])) 
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
    preinit(self);
    if ((self = [super initWithCoder:coder])) 
    {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

+ (Class)layerClass
{
    return [CAShapeLayer class];
}

- (void)layoutSubviews
{
    for (UIView *sub in self.subviews) 
    {
        sub.frame = contentRect;
    }
}

- (void)layoutArrow
{
    if (arrowDirection == UIPopoverArrowDirectionUnknown) 
    {
        arrowLayer.hidden = YES;
        return;
    }
    else
    {
        arrowLayer.hidden = NO;
    }
    
    CGFloat offset = arrowOffset;
    if (arrowDirection == UIPopoverArrowDirectionUp || arrowDirection == UIPopoverArrowDirectionLeft)
        offset = -offset;
    
    CGFloat x, y;
    if (arrowDirection == UIPopoverArrowDirectionUp || arrowDirection == UIPopoverArrowDirectionDown)
    {
        x = arrowPosition * (self.bounds.size.width - 2 * arrowSize) + arrowSize;
        y = offset;
    }
    else
    {
        x = offset;
        y = arrowPosition * (self.bounds.size.height - 2 * arrowSize) + arrowSize;
    }
    
    arrowLayer.position = CGPointMake(x, y);
}

@end
