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

@interface ECPopoverView () {
@private
    CAShapeLayer *arrowLayer;
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
@synthesize arrowMargin;
@synthesize arrowCornerRadius;

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
    return [self.subviews count] ? [self.subviews objectAtIndex:0] : nil;
}

- (void)setContentView:(UIView *)contentView
{
    [self.contentView removeFromSuperview];
    [self addSubview:contentView];
}

- (void)setArrowPosition:(CGFloat)position
{
    if (position < 0) 
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
    [(CAShapeLayer *)self.layer setPath:[UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:cornerRadius].CGPath];

    contentRect = UIEdgeInsetsInsetRect(bounds, contentInsets);
    [super setBounds:bounds];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [(CAShapeLayer *)self.layer setPath:[UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:cornerRadius].CGPath];
    contentRect = UIEdgeInsetsInsetRect(self.bounds, contentInsets);
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [(CAShapeLayer *)self.layer setFillColor:backgroundColor.CGColor];
    arrowLayer.fillColor = backgroundColor.CGColor;
}

#pragma mark -
#pragma mark UIView Methods

static void preinit(ECPopoverView *self)
{
    self->arrowSize = 20;
    self->arrowCornerRadius = 1;
    self->arrowPosition = 0.5;
    self->arrowDirection = UIPopoverArrowDirectionUp;
    self->arrowMargin = self->arrowSize / M_SQRT2 - self->arrowCornerRadius;
    
    self->cornerRadius = 5;
    
    self->contentInsets = UIEdgeInsetsMake(5, 5, 5, 5);
}

static void init(ECPopoverView *self)
{
    CAShapeLayer *layer = (CAShapeLayer *)self.layer;
    
    self->arrowLayer = [CAShapeLayer new];
    self->arrowLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self->arrowSize, self->arrowSize) cornerRadius:self->arrowCornerRadius].CGPath;
    self->arrowLayer.transform = CATransform3DMakeRotation(M_PI_4, 0, 0, 1);
    self->arrowLayer.actions = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"position"];
    
    [layer insertSublayer:self->arrowLayer atIndex:0];
    [self layoutArrow];
    
    self->contentRect = UIEdgeInsetsInsetRect(self.bounds, self->contentInsets);
    
    self.backgroundColor = [UIColor styleForegroundColor];
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
    
    //
    CGFloat position = (arrowDirection <= UIPopoverArrowDirectionDown) ? self.bounds.size.width : self.bounds.size.height;
    if (arrowPosition <= 1) 
        position = arrowPosition * (position - 2 * arrowSize) + arrowSize;
    else
    {
        CGFloat maxPosition = MAX(arrowPosition, arrowSize);
        position = MIN(maxPosition, (position - arrowSize));
    }
    
    //
    switch (arrowDirection) 
    {
        case UIPopoverArrowDirectionRight:
            arrowLayer.position = CGPointMake(self.bounds.size.width - self->arrowCornerRadius, position - arrowMargin - arrowCornerRadius);
            break;
            
        case UIPopoverArrowDirectionDown:
            arrowLayer.position = CGPointMake(position, self.bounds.size.height - arrowMargin - 2 * arrowCornerRadius);
            break;
            
        case UIPopoverArrowDirectionLeft:
            arrowLayer.position = CGPointMake(arrowCornerRadius, position - arrowMargin - arrowCornerRadius);
            break;
            
        default:
            arrowLayer.position = CGPointMake(position, -arrowMargin);
            break;
    }
}

@end
