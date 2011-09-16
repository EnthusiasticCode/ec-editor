//
//  ECPopoverView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPopoverView.h"
#import <QuartzCore/QuartzCore.h>


@implementation ECPopoverView {
    CGRect contentRect;
}

static void updatePath(ECPopoverView *self);

#pragma mark - Properties

@synthesize cornerRadius, shadowOffsetForArrowDirectionUpToAutoOrient;
@synthesize arrowDirection, arrowPosition, arrowSize, arrowMargin, arrowCornerRadius;

- (void)setContentInsets:(UIEdgeInsets)insets
{
    contentRect = UIEdgeInsetsInsetRect(self.bounds, insets);
    [super setContentInsets:insets];
}

- (CGSize)contentSize
{
    return contentRect.size;
}

- (void)setContentSize:(CGSize)size
{
    if (CGSizeEqualToSize(size, contentRect.size))
        return;
    
    UIEdgeInsets contentInsets = self.contentInsets;
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
    ECASSERT(position >= 0);
    
    if (position == arrowPosition)
        return;

    arrowPosition = position;
    updatePath(self);
}

- (void)setArrowDirection:(UIPopoverArrowDirection)direction
{
    if (arrowDirection == direction)
        return;
    
    arrowDirection = direction;
    updatePath(self);
}

- (void)setBounds:(CGRect)bounds
{
    if (CGRectEqualToRect(bounds, self.bounds))
        return;
    
    [super setBounds:bounds];
    contentRect = UIEdgeInsetsInsetRect(bounds, self.contentInsets);
    updatePath(self);
}

- (void)setFrame:(CGRect)frame
{
    if (CGRectEqualToRect(frame, self.frame))
        return;
    
    [super setFrame:frame];
    contentRect = UIEdgeInsetsInsetRect(self.bounds, self.contentInsets);
    updatePath(self);
}

- (UIColor *)backgroundColor
{
    return [UIColor colorWithCGColor:[(CAShapeLayer *)self.layer fillColor]];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    CGColorRef color = backgroundColor.CGColor;
    [(CAShapeLayer *)self.layer setFillColor:color];
    
    [super setBackgroundColor:backgroundColor];
}

- (CGFloat)shadowRadius
{
    return self.layer.shadowRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    self.layer.shadowRadius = shadowRadius;
}

- (CGFloat)shadowOpacity
{
    return self.layer.shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity
{
    self.layer.shadowOpacity = shadowOpacity;
}

- (void)setShadowOffsetForArrowDirectionUpToAutoOrient:(CGSize)offset
{
    shadowOffsetForArrowDirectionUpToAutoOrient = offset;
    updatePath(self);
}

#pragma mark - UIView Methods

static void preinit(ECPopoverView *self)
{
    self->arrowSize = 20;
    self->arrowCornerRadius = 2;
    self->arrowPosition = 0.5;
    self->arrowDirection = UIPopoverArrowDirectionUp;
    self->arrowMargin = self->arrowSize / M_SQRT2;
    
    self->cornerRadius = 5;
    
    self.contentInsets = UIEdgeInsetsMake(5, 5, 5, 5);
}

static void init(ECPopoverView *self)
{    
    self->contentRect = UIEdgeInsetsInsetRect(self.bounds, self.contentInsets);
    updatePath(self);
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
    
    [super layoutSubviews];
}

#pragma mark - Private Methods

static void updatePath(ECPopoverView *self)
{
    CGRect rect = self.bounds;
    if (CGRectIsEmpty(rect))
        return;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat localArrowPosition = self->arrowPosition;
    if (self->arrowDirection == UIPopoverArrowDirectionDown)
        localArrowPosition = (rect.size.width <= localArrowPosition) ? 0 : (rect.size.width - localArrowPosition);
    else if (self->arrowDirection == UIPopoverArrowDirectionLeft)
        localArrowPosition = (rect.size.height <= localArrowPosition) ? 0 : (rect.size.height - localArrowPosition);
    
    CGFloat arrowNoCornerSize = self->arrowSize - self->arrowCornerRadius;
    CGFloat arrowLength = self->arrowMargin;
    CGFloat arrowLength2 = arrowLength * 2;
    
    CGRect innerRect = CGRectInset(rect, self->cornerRadius, self->cornerRadius);
    
    CGFloat inside_right = innerRect.origin.x + innerRect.size.width;
    CGFloat outside_right = rect.origin.x + rect.size.width;
    CGFloat inside_bottom = innerRect.origin.y + innerRect.size.height;
    CGFloat outside_bottom = rect.origin.y + rect.size.height;
    
    CGFloat inside_top = innerRect.origin.y;
    CGFloat outside_top = rect.origin.y;
    CGFloat outside_left = rect.origin.x;
    
    UIPopoverArrowDirection arrowCorner = 0;
    NSUInteger arrowCornerAtStart = 1UL << 8;
    if (localArrowPosition <= arrowLength2 + self->cornerRadius)
    {
        arrowCorner = (NSInteger)self->arrowDirection | arrowCornerAtStart;
    }
    else if (
             (self->arrowDirection <= UIPopoverArrowDirectionDown && localArrowPosition >= rect.size.width - arrowLength2 - self->cornerRadius)
             || (self->arrowDirection > UIPopoverArrowDirectionDown && localArrowPosition >= rect.size.height - arrowLength2 - self->cornerRadius))
    {
        arrowCorner = (NSInteger)self->arrowDirection;
    }
    
    // Start position
    if (arrowCorner & UIPopoverArrowDirectionLeft || arrowCorner & UIPopoverArrowDirectionUp)
        CGPathMoveToPoint(path, NULL, outside_left, outside_top);
    else
        CGPathMoveToPoint(path, NULL, innerRect.origin.x, outside_top);
    
    // Up edge
    if (self->arrowDirection & UIPopoverArrowDirectionUp) 
    {
        if (arrowCorner & UIPopoverArrowDirectionUp)
        {
            if (arrowCorner & arrowCornerAtStart) 
            {
                CGPathAddLineToPoint(path, NULL, outside_left, outside_top - arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_left + arrowLength, outside_top);
                CGPathAddLineToPoint(path, NULL, inside_right, outside_top);
                CGPathAddArcToPoint(path, NULL, outside_right, outside_top, outside_right, inside_top, self->cornerRadius);
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
            CGPathAddArcToPoint(path, &currentTransform, self->arrowSize, 0, self->arrowSize, self->arrowCornerRadius, self->arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, self->arrowSize, self->arrowSize);
            CGPathAddLineToPoint(path, NULL, inside_right, outside_top);
            CGPathAddArcToPoint(path, NULL, outside_right, outside_top, outside_right, inside_top, self->cornerRadius);
        }
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, inside_right, outside_top);
        if (!((arrowCorner & UIPopoverArrowDirectionRight) && (arrowCorner & arrowCornerAtStart)))
            CGPathAddArcToPoint(path, NULL, outside_right, outside_top, outside_right, inside_top, self->cornerRadius);
    }
    
    // Right edge
    if (self->arrowDirection & UIPopoverArrowDirectionRight) 
    {
        if (arrowCorner & UIPopoverArrowDirectionRight)
        {
            if (arrowCorner & arrowCornerAtStart) 
            {
                CGPathAddLineToPoint(path, NULL, outside_right + arrowLength, outside_top);
                CGPathAddLineToPoint(path, NULL, outside_right, outside_top + arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_right, inside_bottom);
                CGPathAddArcToPoint(path, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, self->cornerRadius);                    
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
            CGPathAddArcToPoint(path, &currentTransform, self->arrowSize, 0, self->arrowSize, self->arrowCornerRadius, self->arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, self->arrowSize, self->arrowSize);
            CGPathAddLineToPoint(path, NULL, outside_right, inside_bottom);
            CGPathAddArcToPoint(path, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, self->cornerRadius);
        }
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, outside_right, inside_bottom);
        if (!((arrowCorner & UIPopoverArrowDirectionDown) && (arrowCorner & arrowCornerAtStart)))
            CGPathAddArcToPoint(path, NULL,  outside_right, outside_bottom, inside_right, outside_bottom, self->cornerRadius);
    }
    
    // Bottom edge
    if (self->arrowDirection & UIPopoverArrowDirectionDown) 
    {
        if (arrowCorner & UIPopoverArrowDirectionDown)
        {
            if (arrowCorner & arrowCornerAtStart) 
            {
                CGPathAddLineToPoint(path, NULL, outside_right, outside_bottom + arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_right - arrowLength, outside_bottom);
                CGPathAddLineToPoint(path, NULL, innerRect.origin.x, outside_bottom);
                CGPathAddArcToPoint(path, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, self->cornerRadius);
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
            CGPathAddArcToPoint(path, &currentTransform, -self->arrowSize, 0, -self->arrowSize, -self->arrowCornerRadius, self->arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, -self->arrowSize, -self->arrowSize);
            CGPathAddLineToPoint(path, NULL, innerRect.origin.x, outside_bottom);
            CGPathAddArcToPoint(path, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, self->cornerRadius);
        }
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, innerRect.origin.x, outside_bottom);
        if (!((arrowCorner & UIPopoverArrowDirectionLeft) && (arrowCorner & arrowCornerAtStart)))
            CGPathAddArcToPoint(path, NULL,  outside_left, outside_bottom, outside_left, inside_bottom, self->cornerRadius);
    }
    
    // Left edge
    if (self->arrowDirection & UIPopoverArrowDirectionLeft) 
    {
        if (arrowCorner & UIPopoverArrowDirectionLeft)
        {
            if (arrowCorner & arrowCornerAtStart) 
            {
                CGPathAddLineToPoint(path, NULL, outside_left - arrowLength, outside_bottom);
                CGPathAddLineToPoint(path, NULL, outside_left, outside_bottom - arrowLength);
                CGPathAddLineToPoint(path, NULL, outside_left, inside_top);
                CGPathAddArcToPoint(path, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, self->cornerRadius);                    
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
            CGPathAddArcToPoint(path, &currentTransform, -self->arrowSize, 0, -self->arrowSize, -self->arrowCornerRadius, self->arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, -self->arrowSize, -self->arrowSize);
            CGPathAddLineToPoint(path, NULL, outside_left, inside_top);
            CGPathAddArcToPoint(path, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, self->cornerRadius); 
        }
    }
    else
    {
        CGPathAddLineToPoint(path, NULL, outside_left, inside_top);
        if (!((arrowCorner & UIPopoverArrowDirectionUp) && (arrowCorner & arrowCornerAtStart)))
            CGPathAddArcToPoint(path, NULL,  outside_left, outside_top, innerRect.origin.x, outside_top, self->cornerRadius);
    }
    
    CGPathCloseSubpath(path);
    
    // Apply path
    CAShapeLayer *layer = (CAShapeLayer *)[self layer];
    layer.path = path;
    
    // Apply path to shadow
    if (layer.shadowOpacity > 0.)
    {
        layer.shadowPath = path;
        
        if (!CGSizeEqualToSize(self->shadowOffsetForArrowDirectionUpToAutoOrient, CGSizeZero))
        {
            switch (self->arrowDirection) {
                case UIPopoverArrowDirectionDown:
                {
                    layer.shadowOffset = CGSizeMake(self->shadowOffsetForArrowDirectionUpToAutoOrient.width, -self->shadowOffsetForArrowDirectionUpToAutoOrient.height);
                    break;
                }
                    
                case UIPopoverArrowDirectionLeft:
                {
                    layer.shadowOffset = CGSizeMake(self->shadowOffsetForArrowDirectionUpToAutoOrient.height, self->shadowOffsetForArrowDirectionUpToAutoOrient.width);
                    break;
                }
                    
                case UIPopoverArrowDirectionRight:
                {
                    layer.shadowOffset = CGSizeMake(-self->shadowOffsetForArrowDirectionUpToAutoOrient.height, self->shadowOffsetForArrowDirectionUpToAutoOrient.width);
                    break;
                }
                    
                default:
                {
                    layer.shadowOffset = self->shadowOffsetForArrowDirectionUpToAutoOrient;
                    break;
                }
            }
        }
    }
    
    CGPathRelease(path); 
}

@end
