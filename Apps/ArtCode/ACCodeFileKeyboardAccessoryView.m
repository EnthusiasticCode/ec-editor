//
//  ACCodeFileInputAccessoryView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryView.h"
#import <objc/message.h>

#define SPLIT_KEYBOARD_LEFT_SEGMENT_WIDTH 256
#define SPLIT_KEYBOARD_RIGHT_SEGMENT_WIDTH 281
#define PORTRAIT_KEYBOARD_WIDTH 768

@implementation ACCodeFileKeyboardAccessoryView {
    UIEdgeInsets _itemInsets[3];
    CGFloat _itemWidth[4];
    UIEdgeInsets _contentIntets[3];
}

// TODO see http://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html#//apple_ref/doc/uid/TP40009542-CH12-SW1 for input clicks
#pragma mark - Properties

@synthesize split, flipped;
@synthesize dockedBackgroundView, splitLeftBackgroundView, splitRightBackgroundView, splitBackgroundViewInsets;
@synthesize items, itemBackgroundImage;

- (void)setDockedBackgroundView:(UIView *)value
{
    if (value == dockedBackgroundView)
        return;
    [self willChangeValueForKey:@"dockedBackgroundView"];
    if (!self.isSplit)
    {
        [dockedBackgroundView removeFromSuperview];
        if (value)
            [self insertSubview:value atIndex:0];
    }
    dockedBackgroundView = value;
    [self didChangeValueForKey:@"dockedBackgroundView"];
}

- (void)setSplit:(BOOL)value
{
    if (value == split)
        return;
    
    [self willChangeValueForKey:@"split"];
    split = value;
    if (split)
    {
        [dockedBackgroundView removeFromSuperview];
        [self insertSubview:self.splitLeftBackgroundView atIndex:0];
        [self insertSubview:self.splitRightBackgroundView atIndex:0];
    }
    else
    {
        [splitLeftBackgroundView removeFromSuperview];
        [splitRightBackgroundView removeFromSuperview];
        [self insertSubview:self.dockedBackgroundView atIndex:0];
    }
    [self didChangeValueForKey:@"split"];
}

- (void)setItemBackgroundImage:(UIImage *)value
{
    if (value == itemBackgroundImage)
        return;
    [self willChangeValueForKey:@"itemBackgroundImage"];
    itemBackgroundImage = value;
    for (UIBarButtonItem *item in self.items)
    {
        [(UIButton *)item.customView setBackgroundImage:itemBackgroundImage forState:UIControlStateNormal];
    }
    [self didChangeValueForKey:@"itemBackgroundImage"];
}

#pragma mark - View's Methods

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    ACCodeFileKeyboardAccessoryPosition currentPosition = [self currentAccessoryPosition];
    UIEdgeInsets contentInsets = [self contentInsetsForAccessoryPosition:currentPosition];
    UIEdgeInsets itemInsets = [self itemInsetsForAccessoryPosition:currentPosition];
    if (currentPosition >= ACCodeFileKeyboardAccessoryPositionFloating)
    {
        // Background
        if (splitLeftBackgroundView && splitRightBackgroundView)
        {
            UIEdgeInsets insets = self.splitBackgroundViewInsets;
            if (self.isFlipped)
            {
                self.splitLeftBackgroundView.transform = self.splitRightBackgroundView.transform = CGAffineTransformMakeScale(1, -1);
                insets.top = splitBackgroundViewInsets.bottom;
                insets.bottom = splitBackgroundViewInsets.top;
            }
            else
            {
                self.splitLeftBackgroundView.transform = self.splitRightBackgroundView.transform = CGAffineTransformIdentity;
            }
            self.splitLeftBackgroundView.frame = UIEdgeInsetsInsetRect(CGRectMake(0, 0, SPLIT_KEYBOARD_LEFT_SEGMENT_WIDTH, bounds.size.height), insets);
            self.splitRightBackgroundView.frame = UIEdgeInsetsInsetRect(CGRectMake(bounds.size.width - SPLIT_KEYBOARD_RIGHT_SEGMENT_WIDTH, 0, SPLIT_KEYBOARD_RIGHT_SEGMENT_WIDTH, bounds.size.height), insets);
        }
        // Items
        __block CGRect itemFrame = CGRectMake(contentInsets.left + itemInsets.left, contentInsets.top + itemInsets.top, [self itemDefaultWidthForAccessoryPosition:currentPosition], bounds.size.height - contentInsets.top - contentInsets.bottom - itemInsets.top - itemInsets.bottom);
        [self.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
            if ([item isKindOfClass:[ACCodeFileKeyboardAccessoryItem class]] 
                && [(ACCodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition])
                itemFrame.size.width = [(ACCodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition];
            else
                itemFrame.size.width = [self itemDefaultWidthForAccessoryPosition:currentPosition];
            // Layout and move to next
            item.customView.frame = itemFrame;
            if (itemIndex == 4)
                *stop = YES;
            else
                itemFrame.origin.x += itemFrame.size.width + itemInsets.right + itemInsets.left;
        }];
        itemFrame.origin.x = bounds.size.width - contentInsets.right - itemInsets.right;
        [self.items enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
            if (itemIndex <= 4)
            {
                *stop = YES;
                return;
            }
            if ([item isKindOfClass:[ACCodeFileKeyboardAccessoryItem class]] 
                && [(ACCodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition])
                itemFrame.size.width = [(ACCodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition];
            else
                itemFrame.size.width = [self itemDefaultWidthForAccessoryPosition:currentPosition];
            
            // Layout and move to next
            itemFrame.origin.x -= itemFrame.size.width;
            item.customView.frame = itemFrame;
            itemFrame.origin.x -= itemInsets.right + itemInsets.left;
        }];
    }
    else if (self.dockedBackgroundView)
    {
        self.dockedBackgroundView.frame = bounds;
        
        // Items
        CGRect itemFrame = CGRectMake(contentInsets.left + itemInsets.left, contentInsets.top + itemInsets.top, 0, bounds.size.height - contentInsets.top - contentInsets.bottom - itemInsets.top - itemInsets.bottom);
        for (UIBarButtonItem *item in self.items)
        {
            if ([item isKindOfClass:[ACCodeFileKeyboardAccessoryItem class]] 
                && [(ACCodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition])
                itemFrame.size.width = [(ACCodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition];
            else
                itemFrame.size.width = [self itemDefaultWidthForAccessoryPosition:currentPosition];
            item.customView.frame = itemFrame;
            itemFrame.origin.x += itemFrame.size.width + itemInsets.right + itemInsets.left;
        }
    }
}

#pragma mark - Items Methods

- (void)_itemButtonAction:(UIButton *)sender
{
    NSUInteger tag = sender.tag;
    if (tag > 0 && tag < [self.items count])
    {
        UIBarButtonItem *item = [self.items objectAtIndex:tag];
        if (item.target && item.action)
            objc_msgSend(item.target, item.action, item);
    }
}

- (void)setItems:(NSArray *)value
{
    if (items == value)
        return;
    [self willChangeValueForKey:@"items"];
    for (UIBarButtonItem *item in items)
    {
        [item.customView removeFromSuperview];
    }
    items = value;
    [items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
        UIButton *itemButton = [UIButton new];
        itemButton.tag = itemIndex;
        [itemButton addTarget:self action:@selector(_itemButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [itemButton setBackgroundImage:self.itemBackgroundImage forState:UIControlStateNormal];
        if (item.title)
            [itemButton setTitle:item.title forState:UIControlStateNormal];
        if (item.image) // TODO listen to image change
            [itemButton setImage:item.image forState:UIControlStateNormal];
        // TODO initialize item
        item.customView = itemButton;
        [self addSubview:item.customView]; 
    }];
    [self didChangeValueForKey:@"items"];
}

- (void)setItemDefaultWidth:(CGFloat)width forAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _itemWidth[position] = width;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (CGFloat)itemDefaultWidthForAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _itemWidth[position];
}

- (void)setContentInsets:(UIEdgeInsets)insets forAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _contentIntets[position] = insets;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (UIEdgeInsets)contentInsetsForAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _contentIntets[position];
}

- (void)setItemInsets:(UIEdgeInsets)insets forAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _itemInsets[position] = insets;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (UIEdgeInsets)itemInsetsForAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _itemInsets[position];
}

- (ACCodeFileKeyboardAccessoryPosition)currentAccessoryPosition
{
    if (self.isSplit)
        return ACCodeFileKeyboardAccessoryPositionFloating;
    if (self.bounds.size.width > PORTRAIT_KEYBOARD_WIDTH)
        return ACCodeFileKeyboardAccessoryPositionLandscape;
    return ACCodeFileKeyboardAccessoryPositionPortrait;
}

@end

@implementation ACCodeFileKeyboardAccessoryItem {
@private
    CGFloat _widthForPosition[3];
}

- (void)setWidth:(CGFloat)width forAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _widthForPosition[position] = width;
}

- (CGFloat)widthForAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _widthForPosition[position];
}

@end
