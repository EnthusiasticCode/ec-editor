//
//  ECBasePopoverView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 09/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ECBasePopoverView.h"

@implementation ECBasePopoverView {
@private
    /// Arrow sizes for meta position: far left, middle, far right.
    CGSize _arrowSizes[3];
}

#pragma mark - Properties

@synthesize contentView, contentInsets;
@synthesize arrowDirection, arrowPosition, arrowInsets;

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

#pragma mark - View's Methods

- (void)layoutSubviews
{
    self.contentView.frame = UIEdgeInsetsInsetRect(self.bounds, self.contentInsets);
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
    return size;
}

- (void)setArrowSize:(CGSize)arrowSize forMetaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
{
    ECASSERT(abs(metaPosition) <= 1);
    _arrowSizes[metaPosition + 1] = arrowSize;
}

- (CGFloat)arrowActualPosition
{
    ECPopoverViewArrowMetaPosition metaPosition = [self currentArrowMetaPosition];
    CGSize arrowSize = CGSizeApplyAffineTransform([self arrowSizeForMetaPosition:metaPosition], [self arrowRotationTransformInDirection:self.arrowDirection metaPosition:metaPosition]);
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

- (CGAffineTransform)arrowRotationTransformInDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition
{
    return CGAffineTransformIdentity;
}

@end
