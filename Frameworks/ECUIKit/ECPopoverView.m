//
//  ECPopoverView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPopoverView.h"
#import <QuartzCore/QuartzCore.h>

@interface ECPopoverView () {
@private
    CGRect contentRect;
}

- (void)updatePath;

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
    [self updatePath];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)direction
{
    if (arrowDirection == direction)
        return;
    
    arrowDirection = direction;
    [self updatePath];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    contentRect = UIEdgeInsetsInsetRect(bounds, contentInsets);
    [self updatePath];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    contentRect = UIEdgeInsetsInsetRect(self.bounds, contentInsets);
    [self updatePath];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [(CAShapeLayer *)self.layer setFillColor:backgroundColor.CGColor];
}

#pragma mark -
#pragma mark UIView Methods

static void preinit(ECPopoverView *self)
{
    self->arrowSize = 20;
    self->arrowCornerRadius = 1;
    self->arrowPosition = 0.5;
    self->arrowDirection = UIPopoverArrowDirectionUp;
    self->arrowMargin = self->arrowSize / M_SQRT2;
    
    self->cornerRadius = 5;
    
    self->contentInsets = UIEdgeInsetsMake(5, 5, 5, 5);
}

static void init(ECPopoverView *self)
{    
    self->contentRect = UIEdgeInsetsInsetRect(self.bounds, self->contentInsets);
    [self updatePath];
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

- (void)updatePath
{
    CGRect rect = self.bounds;
    if (CGRectIsEmpty(rect))
        return;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat localArrowPosition = arrowPosition;
    if (arrowDirection == UIPopoverArrowDirectionDown)
        localArrowPosition = (rect.size.width <= localArrowPosition) ? 0 : (rect.size.width - localArrowPosition);
    else if (arrowDirection == UIPopoverArrowDirectionLeft)
        localArrowPosition = (rect.size.height <= localArrowPosition) ? 0 : (rect.size.height - localArrowPosition);
    
    CGFloat arrowNoCornerSize = arrowSize - arrowCornerRadius;
    CGFloat arrowLength = arrowMargin;
    CGFloat arrowLength2 = arrowLength * 2;
    
    CGRect innerRect = CGRectInset(rect, cornerRadius, cornerRadius);
    
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    
    UIPopoverArrowDirection arrowCorner = 0;
    NSUInteger arrowCornerAtStart = 1UL << 8;
    if (localArrowPosition <= arrowLength2 + cornerRadius)
    {
        arrowCorner = (NSInteger)arrowDirection | arrowCornerAtStart;
    }
    else if (
             (arrowDirection <= UIPopoverArrowDirectionDown && localArrowPosition >= rect.size.width - arrowLength2 - cornerRadius)
             || (arrowDirection > UIPopoverArrowDirectionDown && localArrowPosition >= rect.size.height - arrowLength2 - cornerRadius))
    {
        arrowCorner = (NSInteger)arrowDirection;
    }
    
    // Start position
    if (arrowCorner & UIPopoverArrowDirectionLeft || arrowCorner & UIPopoverArrowDirectionUp)
        CGPathMoveToPoint(path, NULL, outside_left, outside_top);
    else
        CGPathMoveToPoint(path, NULL, innerRect.origin.x, outside_top);
    
    // Up edge
    if (arrowDirection & UIPopoverArrowDirectionUp) 
    {
        if (arrowCorner & UIPopoverArrowDirectionUp)
        {
            if (arrowCorner & arrowCornerAtStart) 
            {
                CGPathAddLineToPoint(path, NULL, outside_left, outside_top - arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_left + arrowLength, outside_top);
                CGPathAddLineToPoint(path, NULL, inside_right, outside_top);
                CGPathAddArcToPoint(path, NULL, outside_right, outside_top, outside_right, inside_top, cornerRadius);
            }
            else
            {
                CGPathAddLineToPoint(path, NULL, outside_right - arrowLength, outside_top);
                CGPathAddLineToPoint(path, NULL, outside_right, outside_top - arrowLength);                    
            }
        }
        else
        {
            CGFloat currentX = outside_left + localArrowPosition - arrowLength;
            CGPathAddLineToPoint(path, NULL, currentX, outside_top);
            CGAffineTransform currentTransform = CGAffineTransformMakeTranslation(currentX, outside_top);
            currentTransform = CGAffineTransformRotate(currentTransform, -M_PI_4);
            CGPathAddLineToPoint(path, &currentTransform, arrowNoCornerSize, 0);
            CGPathAddArcToPoint(path, &currentTransform, arrowSize, 0, arrowSize, arrowCornerRadius, arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, arrowSize, arrowSize);
            CGPathAddLineToPoint(path, NULL, inside_right, outside_top);
            CGPathAddArcToPoint(path, NULL, outside_right, outside_top, outside_right, inside_top, cornerRadius);
        }
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, inside_right, outside_top);
        if (!((arrowCorner & UIPopoverArrowDirectionRight) && (arrowCorner & arrowCornerAtStart)))
            CGPathAddArcToPoint(path, NULL, outside_right, outside_top, outside_right, inside_top, cornerRadius);
    }
    
    // Right edge
    if (arrowDirection & UIPopoverArrowDirectionRight) 
    {
        if (arrowCorner & UIPopoverArrowDirectionRight)
        {
            if (arrowCorner & arrowCornerAtStart) 
            {
                CGPathAddLineToPoint(path, NULL, outside_right + arrowLength, outside_top);
                CGPathAddLineToPoint(path, NULL, outside_right, outside_top + arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_right, inside_bottom);
                CGPathAddArcToPoint(path, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, cornerRadius);                    
            }
            else
            {
                CGPathAddLineToPoint(path, NULL, outside_right, outside_bottom - arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_right + arrowLength, outside_bottom);
            }
        }
        else
        {
            CGFloat currentY = outside_top + localArrowPosition - arrowLength;
            CGPathAddLineToPoint(path, NULL, outside_right, currentY);
            CGAffineTransform currentTransform = CGAffineTransformMakeTranslation(outside_right, currentY);
            currentTransform = CGAffineTransformRotate(currentTransform, M_PI_4);
            CGPathAddLineToPoint(path, &currentTransform, arrowNoCornerSize, 0);
            CGPathAddArcToPoint(path, &currentTransform, arrowSize, 0, arrowSize, arrowCornerRadius, arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, arrowSize, arrowSize);
            CGPathAddLineToPoint(path, NULL, outside_right, inside_bottom);
            CGPathAddArcToPoint(path, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, cornerRadius);
        }
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, outside_right, inside_bottom);
        if (!((arrowCorner & UIPopoverArrowDirectionDown) && (arrowCorner & arrowCornerAtStart)))
            CGPathAddArcToPoint(path, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, cornerRadius);
    }
    
    // Bottom edge
    if (arrowDirection & UIPopoverArrowDirectionDown) 
    {
        if (arrowCorner & UIPopoverArrowDirectionDown)
        {
            if (arrowCorner & arrowCornerAtStart) 
            {
                CGPathAddLineToPoint(path, NULL, outside_right, outside_bottom + arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_right - arrowLength, outside_bottom);
                CGPathAddLineToPoint(path, NULL, innerRect.origin.x, outside_bottom);
                CGPathAddArcToPoint(path, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, cornerRadius);
            }
            else
            {
                CGPathAddLineToPoint(path, NULL, outside_left + arrowLength, outside_bottom);
                CGPathAddLineToPoint(path, NULL, outside_left, outside_bottom + arrowLength);                    
            }
        }
        else
        {
            CGFloat currentX = outside_right - localArrowPosition + arrowLength;
            CGPathAddLineToPoint(path, NULL, currentX, outside_bottom);
            CGAffineTransform currentTransform = CGAffineTransformMakeTranslation(currentX, outside_bottom);
            currentTransform = CGAffineTransformRotate(currentTransform, -M_PI_4);
            CGPathAddLineToPoint(path, &currentTransform, -arrowNoCornerSize, 0);
            CGPathAddArcToPoint(path, &currentTransform, -arrowSize, 0, -arrowSize, -arrowCornerRadius, arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, -arrowSize, -arrowSize);
            CGPathAddLineToPoint(path, NULL, innerRect.origin.x, outside_bottom);
            CGPathAddArcToPoint(path, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, cornerRadius);
        }
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, innerRect.origin.x, outside_bottom);
        if (!((arrowCorner & UIPopoverArrowDirectionLeft) && (arrowCorner & arrowCornerAtStart)))
            CGPathAddArcToPoint(path, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, cornerRadius);
    }
    
    // Left edge
    if (arrowDirection & UIPopoverArrowDirectionLeft) 
    {
        if (arrowCorner & UIPopoverArrowDirectionLeft)
        {
            if (arrowCorner & arrowCornerAtStart) 
            {
                CGPathAddLineToPoint(path, NULL, outside_left - arrowLength, outside_bottom);
                CGPathAddLineToPoint(path, NULL, outside_left, outside_bottom - arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_left, inside_top);
                CGPathAddArcToPoint(path, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, cornerRadius);                    
            }
            else
            {
                CGPathAddLineToPoint(path, NULL, outside_left, outside_top + arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_left - arrowLength, outside_top);
            }
        }
        else
        {
            CGFloat currentY = outside_bottom - localArrowPosition + arrowLength;
            CGPathAddLineToPoint(path, NULL, outside_left, currentY);
            CGAffineTransform currentTransform = CGAffineTransformMakeTranslation(outside_left, currentY);
            currentTransform = CGAffineTransformRotate(currentTransform, M_PI_4);
            CGPathAddLineToPoint(path, &currentTransform, -arrowNoCornerSize, 0);
            CGPathAddArcToPoint(path, &currentTransform, -arrowSize, 0, -arrowSize, -arrowCornerRadius, arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, -arrowSize, -arrowSize);
            CGPathAddLineToPoint(path, NULL, outside_left, inside_top);
            CGPathAddArcToPoint(path, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, cornerRadius); 
        }
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, outside_left, inside_top);
        if (!((arrowCorner & UIPopoverArrowDirectionUp) && (arrowCorner & arrowCornerAtStart)))
            CGPathAddArcToPoint(path, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, cornerRadius);
    }
    
    CGPathCloseSubpath(path);
    
    // Apply path
    CAShapeLayer *layer = (CAShapeLayer *)[self layer];
    layer.path = path;
    
    CGPathRelease(path); 
}

@end
