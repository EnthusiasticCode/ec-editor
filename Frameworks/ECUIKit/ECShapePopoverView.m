//
//  ECPopoverView.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECShapePopoverView.h"
#import "ECRoundedContentCornersView.h"
#import <QuartzCore/QuartzCore.h>

#define BARVIEW_HEIGHT 44

@implementation ECShapePopoverView {
    ECRoundedContentCornersView *_contentWrapView;
}

static void updatePath(ECShapePopoverView *self);

#pragma mark - Properties

@synthesize contentWrapView = _contentWrapView;
@synthesize barView = _barView;
@synthesize cornerRadius, shadowOffsetForArrowDirectionUpToAutoOrient;
@synthesize arrowCornerRadius;

- (void)setContentView:(UIView *)contentView
{
    if (contentView == self.contentView)
        return;
    
    [super setContentView:contentView];
    [self.contentView removeFromSuperview];
    [self.contentWrapView addSubview:self.contentView];
}

- (CGSize)contentSize
{
    CGSize contentSize = [super contentSize];
    if (self.barView)
        contentSize.height -= BARVIEW_HEIGHT;
    return contentSize;
}

- (UIView *)contentWrapView
{
    if (!_contentWrapView)
    {
        _contentWrapView = [ECRoundedContentCornersView new];
    }
    return _contentWrapView;
}

- (CGFloat)contentWrapCornerRadius
{
    return [(ECRoundedContentCornersView *)self.contentWrapView contentCornerRadius];
}

- (void)setContentWrapCornerRadius:(CGFloat)contentWrapCornerRadius
{
    [(ECRoundedContentCornersView *)self.contentWrapView setContentCornerRadius:contentWrapCornerRadius];
}

- (void)setBarView:(UIView *)barView
{
    if (barView == _barView)
        return;
    
    [self willChangeValueForKey:@"barView"];
    [_barView removeFromSuperview];
    _barView = barView;
    [self addSubview:_barView];
    [self didChangeValueForKey:@"barView"];
}

- (void)setArrowPosition:(CGFloat)position
{
    if (position == self.arrowPosition)
        return;

    [super setArrowPosition:position];
    updatePath(self);
}

- (void)setArrowDirection:(UIPopoverArrowDirection)direction
{
    if (self.arrowDirection == direction)
        return;
    
    [super setArrowDirection:direction];
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
    
    self.contentWrapView.backgroundColor = backgroundColor;
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

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    if (CGRectEqualToRect(bounds, self.bounds))
        return;
    updatePath(self);
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (CGSizeEqualToSize(frame.size, self.frame.size))
        return;
    updatePath(self);
}

#pragma mark - UIView Methods

static void init(ECShapePopoverView *self)
{
    [self setArrowSize:CGSizeMake(20, 20) forMetaPosition:ECPopoverViewArrowMetaPositionMiddle];
    self->arrowCornerRadius = 2;
    self->cornerRadius = 5;
    
    self.contentInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    
    updatePath(self);
    
    [self addSubview:self.contentWrapView];
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
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
    CGRect bounds = UIEdgeInsetsInsetRect(self.bounds, self.contentInsets);

    if (self.barView)
    {
        self.barView.frame = (CGRect){ bounds.origin, CGSizeMake(bounds.size.width, BARVIEW_HEIGHT) };
        bounds.origin.y += BARVIEW_HEIGHT;
        bounds.size.height -= BARVIEW_HEIGHT;
    }

    self.contentWrapView.frame = bounds;
    self.contentView.frame = self.contentWrapView.bounds;
}

#pragma mark - Private Methods

// TODO: NIK fix drawing of arrow based on arrowLength
static void updatePath(ECShapePopoverView *self)
{
    CGRect rect = self.bounds;
    if (CGRectIsEmpty(rect))
        return;
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat localArrowPosition = self.arrowPosition;
    if (self.arrowDirection == UIPopoverArrowDirectionDown)
        localArrowPosition = (rect.size.width <= localArrowPosition) ? 0 : (rect.size.width - localArrowPosition);
    else if (self.arrowDirection == UIPopoverArrowDirectionLeft)
        localArrowPosition = (rect.size.height <= localArrowPosition) ? 0 : (rect.size.height - localArrowPosition);
    
    CGFloat arrowSize = [self arrowSizeForMetaPosition:self.currentArrowMetaPosition].height;
    CGFloat arrowNoCornerSize = arrowSize - self->arrowCornerRadius;
    CGFloat arrowLength2 = [self arrowSizeForMetaPosition:self.currentArrowMetaPosition].width;
    CGFloat arrowLength = arrowLength2 / 2;
    
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
        arrowCorner = (NSInteger)self.arrowDirection | arrowCornerAtStart;
    }
    else if (
             (self.arrowDirection <= UIPopoverArrowDirectionDown && localArrowPosition >= rect.size.width - arrowLength2 - self->cornerRadius)
             || (self.arrowDirection > UIPopoverArrowDirectionDown && localArrowPosition >= rect.size.height - arrowLength2 - self->cornerRadius))
    {
        arrowCorner = (NSInteger)self.arrowDirection;
    }
    
    // Start position
    if (arrowCorner & UIPopoverArrowDirectionLeft || arrowCorner & UIPopoverArrowDirectionUp)
        CGPathMoveToPoint(path, NULL, outside_left, outside_top);
    else
        CGPathMoveToPoint(path, NULL, innerRect.origin.x, outside_top);
    
    // Up edge
    if (self.arrowDirection & UIPopoverArrowDirectionUp) 
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
            CGPathAddArcToPoint(path, &currentTransform, arrowSize, 0, arrowSize, self->arrowCornerRadius, self->arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, arrowSize, arrowSize);
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
    if (self.arrowDirection & UIPopoverArrowDirectionRight) 
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
            CGPathAddArcToPoint(path, &currentTransform, arrowSize, 0, arrowSize, self->arrowCornerRadius, self->arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, arrowSize, arrowSize);
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
    if (self.arrowDirection & UIPopoverArrowDirectionDown) 
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
            CGPathAddArcToPoint(path, &currentTransform, -arrowSize, 0, -arrowSize, -self->arrowCornerRadius, self->arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, -arrowSize, -arrowSize);
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
    if (self.arrowDirection & UIPopoverArrowDirectionLeft) 
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
            CGPathAddArcToPoint(path, &currentTransform, -arrowSize, 0, -arrowSize, -self->arrowCornerRadius, self->arrowCornerRadius);
            CGPathAddLineToPoint(path, &currentTransform, -arrowSize, -arrowSize);
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
            switch (self.arrowDirection) {
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
