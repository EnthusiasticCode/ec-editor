//
//  ACCodeFileKeyboardAccessoryPopoverView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryPopoverView.h"
#import <QuartzCore/QuartzCore.h>

@implementation ACCodeFileKeyboardAccessoryPopoverView {
@private
    /// Arrow sizes for meta position: far left, middle, far right.
    CGSize _arrowSizes[3];
    
    /// Array of array filled with NSNull with indexes corresponding to directions: up, down, left, right. Sub arrays has 3 elements: far left, middle, far right.
    NSMutableArray *_arrowDirectionImages;
    BOOL _needsImageAndTransformForArrowView;
}

#pragma mark - Private Methods

- (void)_setNeedsImageAndTransformForArrowView
{
    _needsImageAndTransformForArrowView = YES;
    [self setNeedsLayout];
}

- (CGAffineTransform)_arrowRotationTransformInDirection:(UIPopoverArrowDirection)direction metaPosition:(PopoverViewArrowMetaPosition)metaPosition usedImage:(UIImage **)usedImage
{
    UIImage *image = [self arrowImageForDirection:direction metaPosition:metaPosition];
    CGAffineTransform transform = CGAffineTransformIdentity;
    if (!image)
    {
        NSInteger directionMask = UIPopoverArrowDirectionUp;
        NSUInteger directionIndex = 0;
        while (!(direction & directionMask))
        {
            directionMask <<= 1;
            ++directionIndex;
        }
        
        directionMask = UIPopoverArrowDirectionUp;
        NSUInteger genDirectionIndex = 0;
        do {
            // Get the image from the generation side that can be rotated to fit the destination.
            // Special considerations are taken for edges: far left and right are swapped according to applied rotation.
            image = [self arrowImageForDirection:directionMask metaPosition:((genDirectionIndex % 2 != directionIndex % 2) ? -metaPosition : metaPosition)];
            if (image != nil)
            {
                // Transform the direction indexes in counter-clockwise positions to get the bumber of M_PI_2 to rotate
                NSInteger fromAngleMult = (genDirectionIndex == 1 ? 2 : (genDirectionIndex == 2 ? 1 : genDirectionIndex));
                NSInteger toAngleMult = (directionIndex == 1 ? 2 : (directionIndex == 2 ? 1 : directionIndex));
                NSInteger angleMult = toAngleMult - fromAngleMult;
                transform = CGAffineTransformMakeRotation(-M_PI_2 * (CGFloat)angleMult);
                break;
            }
            directionMask <<= 1;
        } while (++genDirectionIndex < 4);
    }
    
    if (usedImage)
        *usedImage = image;
    
    return transform;
}

#pragma mark - Properties

@synthesize contentView, contentInsets;
@synthesize arrowDirection, arrowPosition, arrowInsets;
@synthesize positioningInsets;
@synthesize arrowView, backgroundView;

- (void)setContentView:(UIView *)value
{
    if (contentView == value)
        return;
    
    [self willChangeValueForKey:@"contentView"];
    [contentView removeFromSuperview];
    contentView = value;
    [self addSubview:contentView];
    [self setNeedsLayout];
    [self didChangeValueForKey:@"contentView"];
}

- (CGSize)contentSize
{
    return UIEdgeInsetsInsetRect(self.bounds, self.contentInsets).size;
}

- (void)setContentSize:(CGSize)contentSize
{
    [self willChangeValueForKey:@"contentSize"];
    contentSize.width += self.contentInsets.left + self.contentInsets.right;
    contentSize.height += self.contentInsets.top + self.contentInsets.bottom;
    self.bounds = (CGRect){ CGPointZero, contentSize };
    [self didChangeValueForKey:@"contentSize"];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)value
{
    if (value == arrowDirection)
        return;
    [self willChangeValueForKey:@"arrowDirection"];
    arrowDirection = value;
    [self _setNeedsImageAndTransformForArrowView];
    [self didChangeValueForKey:@"arrowDirection"];
}

- (void)setArrowPosition:(CGFloat)value
{
    if (value == arrowPosition)
        return;
    [self willChangeValueForKey:@"arrowPosition"];
    arrowPosition = value;
    [self _setNeedsImageAndTransformForArrowView];
    [self didChangeValueForKey:@"arrowPosition"];
}

- (void)setArrowInsets:(UIEdgeInsets)value
{
    if (UIEdgeInsetsEqualToEdgeInsets(value, self.arrowInsets))
        return;
    [self willChangeValueForKey:@"arrowInsets"];
    arrowInsets = value;
    [self setNeedsLayout];
    [self didChangeValueForKey:@"arrowInsets"];
}

- (UIImageView *)arrowView
{
    if (arrowView == nil)
        arrowView = [UIImageView new];
    return arrowView;
}

- (UIImageView *)backgroundView
{
    if (backgroundView == nil)
        backgroundView = [UIImageView new];
    return backgroundView;
}

- (void)setAlpha:(CGFloat)alpha
{
    if (!UIEdgeInsetsEqualToEdgeInsets(self.arrowInsets, UIEdgeInsetsZero))
        self.layer.shouldRasterize = alpha < 1;
    [super setAlpha:alpha];
}

#pragma mark - View's Methods

static void init(ACCodeFileKeyboardAccessoryPopoverView *self)
{
    [self addSubview:self.backgroundView];
    [self addSubview:self.arrowView];
    [self _setNeedsImageAndTransformForArrowView];
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    init(self);
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (!(self = [super initWithCoder:coder]))
        return nil;
    init(self);
    return self;
}

- (id)initWithBackgroundImage:(UIImage *)image
{
    if (!(self = [super initWithFrame:(CGRect){ CGPointZero, image.size }]))
        return nil;
    self.backgroundView.image = image;
    init(self);
    return self;
}

- (void)layoutSubviews
{
    self.contentView.frame = UIEdgeInsetsInsetRect(self.bounds, self.contentInsets);
    
    self.backgroundView.frame = self.bounds;
    
    if (_needsImageAndTransformForArrowView)
    {
        UIImage *arrowImage = nil;
        PopoverViewArrowMetaPosition metaPosition = [self currentArrowMetaPosition];
        self.arrowView.transform = [self _arrowRotationTransformInDirection:self.arrowDirection metaPosition:metaPosition usedImage:&arrowImage];
        self.arrowView.image = arrowImage;
        self.arrowView.bounds = (CGRect){ CGPointZero, [self arrowSizeForMetaPosition:metaPosition] };
        _needsImageAndTransformForArrowView = NO;
    }
    
    switch (self.arrowDirection)
    {
        case UIPopoverArrowDirectionUp:
            self.arrowView.center = CGPointMake([self arrowActualPosition], -self.arrowView.frame.size.height / 2 + self.arrowInsets.top);
            break;
            
        case UIPopoverArrowDirectionDown:
            self.arrowView.center = CGPointMake([self arrowActualPosition], self.bounds.size.height + self.arrowView.frame.size.height / 2 - self.arrowInsets.bottom);
            break;
            
        case UIPopoverArrowDirectionLeft:
            self.arrowView.center = CGPointMake(-self.arrowView.frame.size.width / 2 + self.arrowInsets.left, [self arrowActualPosition]);
            break;
            
        case UIPopoverArrowDirectionRight:
            self.arrowView.center = CGPointMake(self.bounds.size.width + self.arrowView.frame.size.width / 2 - self.arrowInsets.right, [self arrowActualPosition]);
            break;
            
        default:
            ECASSERT(NO && "Invalid arrow direction");
            break;
    }
}

#pragma mark - Arrow Methods

- (PopoverViewArrowMetaPosition)currentArrowMetaPosition
{
    CGFloat relevantSize = [self arrowSizeForMetaPosition:PopoverViewArrowMetaPositionMiddle].width / 2;
    if (self.arrowDirection & (UIPopoverArrowDirectionRight | UIPopoverArrowDirectionLeft))
    {
        if (arrowPosition <= relevantSize + self.arrowInsets.top)
            return PopoverViewArrowMetaPositionFarTop;
        if (arrowPosition >= self.bounds.size.height - relevantSize - self.arrowInsets.bottom)
            return PopoverViewArrowMetaPositionFarBottom;
    }
    else
    {
        if (arrowPosition <= relevantSize + self.arrowInsets.left)
            return PopoverViewArrowMetaPositionFarLeft;
        if (arrowPosition >= self.bounds.size.width - relevantSize - self.arrowInsets.right)
            return PopoverViewArrowMetaPositionFarRight;
    }
    return PopoverViewArrowMetaPositionMiddle;
}

- (CGSize)arrowSizeForMetaPosition:(PopoverViewArrowMetaPosition)metaPosition
{
    ECASSERT(abs(metaPosition) <= 1);
    CGSize size = _arrowSizes[metaPosition + 1];
    if (metaPosition != PopoverViewArrowMetaPositionMiddle && CGSizeEqualToSize(CGSizeZero, size))
        size = _arrowSizes[1];
    
    if (CGSizeEqualToSize(CGSizeZero, size))
        size = [self.arrowView sizeThatFits:size];
    return size;
}

- (void)setArrowSize:(CGSize)arrowSize forMetaPosition:(PopoverViewArrowMetaPosition)metaPosition
{
    ECASSERT(abs(metaPosition) <= 1);
    _arrowSizes[metaPosition + 1] = arrowSize;
    
    [self _setNeedsImageAndTransformForArrowView];
}

- (CGFloat)arrowActualPosition
{
    PopoverViewArrowMetaPosition metaPosition = [self currentArrowMetaPosition];
    CGSize arrowSize = CGSizeApplyAffineTransform([self arrowSizeForMetaPosition:metaPosition], [self arrowRotationTransformInDirection:self.arrowDirection metaPosition:metaPosition]);
    CGFloat relevantSize = 0;
    CGFloat relevantLimit = 0;
    CGFloat relevantInset = 0;
    if (self.arrowDirection & (UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown))
    {
        relevantSize = fabs(arrowSize.width / 2);
        relevantLimit = self.bounds.size.width - relevantSize;
        if (metaPosition == PopoverViewArrowMetaPositionFarLeft)
            relevantInset = self.arrowInsets.left;
        else if (metaPosition == PopoverViewArrowMetaPositionFarRight)
            relevantInset = -self.arrowInsets.right;
    }
    else
    {
        relevantSize = fabs(arrowSize.height / 2);
        relevantLimit = self.bounds.size.height - relevantSize;
        if (metaPosition == PopoverViewArrowMetaPositionFarTop)
            relevantInset = self.arrowInsets.top;
        else if (metaPosition == PopoverViewArrowMetaPositionFarBottom)
            relevantInset = -self.arrowInsets.bottom;
    }
    
    CGFloat position = self.arrowPosition;
    if (position < relevantSize + relevantInset)
        return relevantSize;
    if (position > relevantLimit + relevantInset)
        return relevantLimit;
    return position;
}

- (CGAffineTransform)arrowRotationTransformInDirection:(UIPopoverArrowDirection)direction metaPosition:(PopoverViewArrowMetaPosition)metaPosition
{
    return [self _arrowRotationTransformInDirection:direction metaPosition:metaPosition usedImage:NULL];
}

- (UIImage *)arrowImageForDirection:(UIPopoverArrowDirection)direction metaPosition:(PopoverViewArrowMetaPosition)metaPosition
{
    ECASSERT(direction == UIPopoverArrowDirectionUp || direction == UIPopoverArrowDirectionDown || direction == UIPopoverArrowDirectionLeft || direction == UIPopoverArrowDirectionRight);
    ECASSERT(abs(metaPosition) <= 1);
    
    if (!_arrowDirectionImages)
        return nil;
    
    NSInteger directionMask = UIPopoverArrowDirectionUp;
    NSUInteger directionIndex = 0;
    while (!(direction & directionMask))
    {
        directionMask <<= 1;
        ++directionIndex;
    }
    
    if ([_arrowDirectionImages objectAtIndex:directionIndex] == [NSNull null])
        return nil;
    
    NSMutableArray *arrowPositionImages = (NSMutableArray *)[_arrowDirectionImages objectAtIndex:directionIndex];
    metaPosition += 1;
    if ([arrowPositionImages objectAtIndex:metaPosition] != [NSNull null])
        return [arrowPositionImages objectAtIndex:metaPosition];
    if (metaPosition != 1 && [arrowPositionImages objectAtIndex:1] != [NSNull null])
        return [arrowPositionImages objectAtIndex:1];
    return nil;
}

- (void)setArrowImage:(UIImage *)image forDirection:(UIPopoverArrowDirection)direction metaPosition:(PopoverViewArrowMetaPosition)metaPosition
{
    ECASSERT(abs(metaPosition) <= 1);
    
    if (!_arrowDirectionImages)
        _arrowDirectionImages = [NSMutableArray arrayWithObjects:[NSNull null], [NSNull null], [NSNull null], [NSNull null], nil];
    
    metaPosition += 1;
    NSInteger directionMask = UIPopoverArrowDirectionUp;
    NSUInteger directionIndex = 0;
    do {
        if (direction & directionMask)
        {
            if ([_arrowDirectionImages objectAtIndex:directionIndex] == [NSNull null])
            {
                [_arrowDirectionImages removeObjectAtIndex:directionIndex];
                [_arrowDirectionImages insertObject:[NSMutableArray arrayWithObjects:[NSNull null], [NSNull null], [NSNull null], nil] atIndex:directionIndex];
            }
            
            NSMutableArray *arrowPositionImages = (NSMutableArray *)[_arrowDirectionImages objectAtIndex:directionIndex];
            [arrowPositionImages removeObjectAtIndex:metaPosition];
            [arrowPositionImages insertObject:image atIndex:metaPosition];
        }
        directionMask <<= 1;
    } while (++directionIndex < 4);
    
    [self _setNeedsImageAndTransformForArrowView];
}

@end
