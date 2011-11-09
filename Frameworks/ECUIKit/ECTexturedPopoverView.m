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
    BOOL _needsImageAndTransformForArrowView;
}

@synthesize arrowView, backgroundView;

#pragma mark - Private Methods

- (void)_setNeedsImageAndTransformForArrowView
{
    _needsImageAndTransformForArrowView = YES;
    [self setNeedsLayout];
}

- (CGAffineTransform)_arrowRotationTransformInDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition usedImage:(UIImage **)usedImage
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
    if (value == self.arrowDirection)
        return;
    [super setArrowDirection:value];
    [self _setNeedsImageAndTransformForArrowView];
}

- (void)setArrowPosition:(CGFloat)value
{
    if (value == self.arrowPosition)
        return;
    [super setArrowPosition:value];
    [self _setNeedsImageAndTransformForArrowView];
}

- (void)setArrowInsets:(UIEdgeInsets)value
{
    if (UIEdgeInsetsEqualToEdgeInsets(value, self.arrowInsets))
        return;
    [super setArrowInsets:value];
    [self setNeedsLayout];
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

#pragma mark - View Methods

static void init(ECTexturedPopoverView *self)
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
    [super layoutSubviews];
    
    self.backgroundView.frame = self.bounds;
    
    if (_needsImageAndTransformForArrowView)
    {
        UIImage *arrowImage = nil;
        ECPopoverViewArrowMetaPosition metaPosition = [self currentArrowMetaPosition];
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

- (CGSize)arrowSizeForMetaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
{
    CGSize size = [super arrowSizeForMetaPosition:metaPosition];
    if (CGSizeEqualToSize(CGSizeZero, size))
        size = [self.arrowView sizeThatFits:size];
    return size;
}

- (void)setArrowSize:(CGSize)arrowSize forMetaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
{
    [super setArrowSize:arrowSize forMetaPosition:metaPosition];
    [self _setNeedsImageAndTransformForArrowView];
}

- (CGAffineTransform)arrowRotationTransformInDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
{
    return [self _arrowRotationTransformInDirection:direction metaPosition:metaPosition usedImage:NULL];
}

@end
