//
//  ECTexturedPopoverView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTexturedPopoverView.h"
#import <QuartzCore/QuartzCore.h>

@implementation ECTexturedPopoverView {
    /// Array of array filled with NSNull with indexes corresponding to directions: up, down, left, right. Sub arrays has 3 elements: far left, middle, far right.
    NSMutableArray *_arrowDirectionImages;
    
    /// Arrow sizes for meta position: far left, middle, far right.
    CGSize _arrowSizes[3];
    
    BOOL _needsImageAndTransformForArrowView;
}

@synthesize arrowDirection, arrowPosition, arrowInsets, arrowView;

#pragma mark - Private Methods

- (void)_setNeedsImageAndTransformForArrowView
{
    _needsImageAndTransformForArrowView = YES;
    [self setNeedsLayout];
}

- (CGAffineTransform)_transformForArrowViewInDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition usedImage:(UIImage **)usedImage
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
    if (UIEdgeInsetsEqualToEdgeInsets(value, arrowInsets))
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

- (void)setAlpha:(CGFloat)alpha
{
    if (!UIEdgeInsetsEqualToEdgeInsets(self.arrowInsets, UIEdgeInsetsZero))
        self.layer.shouldRasterize = alpha < 1;
    [super setAlpha:alpha];
}

#pragma mark - View Methods

static void init(ECTexturedPopoverView *self)
{
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

- (id)initWithImage:(UIImage *)image
{
    if (!(self = [super initWithImage:image]))
        return nil;
    init(self);
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_needsImageAndTransformForArrowView)
    {
        UIImage *arrowImage = nil;
        ECPopoverViewArrowMetaPosition metaPosition = [self currentArrowMetaPosition];
        self.arrowView.transform = [self _transformForArrowViewInDirection:self.arrowDirection metaPosition:metaPosition usedImage:&arrowImage];
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

- (ECPopoverViewArrowMetaPosition)currentArrowMetaPosition
{
    CGFloat relevantSize = [self arrowSizeForMetaPosition:ECPopoverViewArrowMetaPositionMiddle].width / 2;
    if (self.arrowDirection & (UIPopoverArrowDirectionRight | UIPopoverArrowDirectionLeft))
    {
        if (arrowPosition <= relevantSize + self.arrowInsets.top)
            return ECPopoverViewArrowMetaPositionFarTop;
        if (arrowPosition >= self.bounds.size.height - relevantSize - self.arrowInsets.bottom)
            return ECPopoverViewArrowMetaPositionFarBottom;
    }
    else
    {
        if (arrowPosition <= relevantSize + self.arrowInsets.left)
            return ECPopoverViewArrowMetaPositionFarLeft;
        if (arrowPosition >= self.bounds.size.width - relevantSize - self.arrowInsets.right)
            return ECPopoverViewArrowMetaPositionFarRight;
    }
    return ECPopoverViewArrowMetaPositionMiddle;
}

- (CGSize)arrowSizeForMetaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
{
    ECASSERT(abs(metaPosition) <= 1);
    CGSize size = _arrowSizes[metaPosition + 1];
    if (metaPosition != ECPopoverViewArrowMetaPositionMiddle && CGSizeEqualToSize(CGSizeZero, size))
        size = _arrowSizes[1];
    if (CGSizeEqualToSize(CGSizeZero, size))
        size = [self.arrowView sizeThatFits:size];
    return size;
}

- (void)setArrowSize:(CGSize)arrowSize forMetaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
{
    ECASSERT(abs(metaPosition) <= 1);
    _arrowSizes[metaPosition + 1] = arrowSize;
    [self _setNeedsImageAndTransformForArrowView];
}

- (CGFloat)arrowActualPosition
{
    ECPopoverViewArrowMetaPosition metaPosition = [self currentArrowMetaPosition];
    CGSize arrowSize = CGSizeApplyAffineTransform([self arrowSizeForMetaPosition:metaPosition], [self _transformForArrowViewInDirection:self.arrowDirection metaPosition:metaPosition usedImage:NULL]);
    CGFloat relevantSize = 0;
    CGFloat relevantLimit = 0;
    CGFloat relevantInset = 0;
    if (self.arrowDirection & (UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown))
    {
        relevantSize = fabs(arrowSize.width / 2);
        relevantLimit = self.bounds.size.width - relevantSize;
        if (metaPosition == ECPopoverViewArrowMetaPositionFarLeft)
            relevantInset = self.arrowInsets.left;
        else if (metaPosition == ECPopoverViewArrowMetaPositionFarRight)
            relevantInset = -self.arrowInsets.right;
    }
    else
    {
        relevantSize = fabs(arrowSize.height / 2);
        relevantLimit = self.bounds.size.height - relevantSize;
        if (metaPosition == ECPopoverViewArrowMetaPositionFarTop)
            relevantInset = self.arrowInsets.top;
        else if (metaPosition == ECPopoverViewArrowMetaPositionFarBottom)
            relevantInset = -self.arrowInsets.bottom;
    }
    
    CGFloat position = self.arrowPosition;
    if (position < relevantSize + relevantInset)
        return relevantSize;
    if (position > relevantLimit + relevantInset)
        return relevantLimit;
    return position;
}

- (UIImage *)arrowImageForDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
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

- (void)setArrowImage:(UIImage *)image forDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
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
