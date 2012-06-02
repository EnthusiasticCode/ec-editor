//
//  ShapeBackgroundPopoverView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 25/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ShapePopoverBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@implementation ShapePopoverBackgroundView

static void updatePath(ShapePopoverBackgroundView *self);

+ (CGFloat)arrowBase
{
  return 38;
}

+ (CGFloat)arrowHeight
{
  return 18;
}

+ (UIEdgeInsets)contentViewInsets
{
  return UIEdgeInsetsMake(5, 5, 5, 5);
}

#pragma mark - Properties

@synthesize arrowOffset, arrowDirection;
@synthesize cornerRadius, shadowOffsetForArrowDirectionUpToAutoOrient;
@synthesize arrowCornerRadius;

- (void)setArrowOffset:(CGFloat)value
{
  if (value == arrowOffset)
    return;
  
  arrowOffset = value;
  [self setNeedsLayout];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)value
{
  if (value == arrowDirection)
    return;
  arrowDirection = value;
  [self setNeedsLayout];
}

- (UIColor *)backgroundColor
{
  return [UIColor colorWithCGColor:[(CAShapeLayer *)self.layer fillColor]];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
  CGColorRef color = backgroundColor.CGColor;
  [(CAShapeLayer *)self.layer setFillColor:color];
}

- (UIColor *)strokeColor
{
  return [UIColor colorWithCGColor:[(CAShapeLayer *)self.layer strokeColor]];
}

- (void)setStrokeColor:(UIColor *)strokeColor
{
  CGColorRef color = strokeColor.CGColor;
  [(CAShapeLayer *)self.layer setStrokeColor:color];
}

- (CGFloat)shadowRadius
{
  return self.layer.shadowRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
  self.layer.shadowRadius = shadowRadius;
  [self setNeedsLayout];
}

- (CGFloat)shadowOpacity
{
  return self.layer.shadowOpacity;
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity
{
  self.layer.shadowOpacity = shadowOpacity;
  [self setNeedsLayout];
}

- (void)setShadowOffsetForArrowDirectionUpToAutoOrient:(CGSize)offset
{
  shadowOffsetForArrowDirectionUpToAutoOrient = offset;
  [self setNeedsLayout];
}

#pragma mark - UIView Methods

static void init(ShapePopoverBackgroundView *self)
{
  self->arrowCornerRadius = 2;
  self->cornerRadius = 5;
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
  [super layoutSubviews];
  
  updatePath(self);
}

#pragma mark - Private Methods

static void updatePath(ShapePopoverBackgroundView *self)
{
  CGRect rect = self.bounds;
  if (CGRectIsEmpty(rect))
    return;
  
  CGFloat localArrowPosition = self.arrowOffset;
  switch (self.arrowDirection)
  {
    case UIPopoverArrowDirectionUp:
      rect.origin.y += [[self class] arrowHeight];
      localArrowPosition += self->cornerRadius * 2;
    case UIPopoverArrowDirectionDown:
      rect.size.height -= [[self class] arrowHeight];
      localArrowPosition += rect.size.width / 2.0 - self->cornerRadius;
      break;
      
    case UIPopoverArrowDirectionLeft:
      rect.origin.x += [[self class] arrowHeight];
    case UIPopoverArrowDirectionRight:
      rect.size.width -= [[self class] arrowHeight];
      localArrowPosition += rect.size.height / 2.0 - self->cornerRadius;
      break;
  }
  
  CGMutablePathRef path = CGPathCreateMutable();
  
  if (self.arrowDirection == UIPopoverArrowDirectionDown)
    localArrowPosition = (rect.size.width <= localArrowPosition) ? 0 : (rect.size.width - localArrowPosition);
  else if (self.arrowDirection == UIPopoverArrowDirectionLeft)
    localArrowPosition = (rect.size.height <= localArrowPosition) ? 0 : (rect.size.height - localArrowPosition);
  
  CGFloat arrowSize = [[self class] arrowHeight];
  CGFloat arrowNoCornerSize = arrowSize - self->arrowCornerRadius;
  CGFloat arrowLength2 = [[self class] arrowBase];
  CGFloat arrowLength = arrowLength2 / 2.0;
  
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
//  if (localArrowPosition < arrowLength)
//  {
//    arrowCorner = (NSInteger)self.arrowDirection | arrowCornerAtStart;
//  }
//  else if (
//           (self.arrowDirection <= UIPopoverArrowDirectionDown && localArrowPosition > rect.size.width - arrowLength)
//           || (self.arrowDirection > UIPopoverArrowDirectionDown && localArrowPosition > rect.size.height - arrowLength))
//  {
//    arrowCorner = (NSInteger)self.arrowDirection;
//  }
  
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
  if (layer.shadowOpacity > 0)
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

@implementation ShapePopoverController

- (id)initWithContentViewController:(UIViewController *)viewController
{
  if (!(self = [super initWithContentViewController:viewController]))
    return nil;
  self.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
  return self;
}

@end
