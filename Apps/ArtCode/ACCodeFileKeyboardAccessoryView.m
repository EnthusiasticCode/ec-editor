//
//  ACCodeFileInputAccessoryView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryView.h"

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
    ACCodeFileKeyboardAccessoryItemSize currentSize = [self currentItemSize];
    UIEdgeInsets contentInsets = [self contentInsetsForItemSize:currentSize];
    UIEdgeInsets itemInsets = [self itemInsetsForItemSize:currentSize];
    if (currentSize >= ACCodeFileKeyboardAccessoryItemSizeSmall)
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
        __block CGRect itemFrame = CGRectMake(contentInsets.left + itemInsets.left, contentInsets.top + itemInsets.top, [self itemWidthForItemSize:ACCodeFileKeyboardAccessoryItemSizeSmallImportant], bounds.size.height - contentInsets.top - contentInsets.bottom - itemInsets.top - itemInsets.bottom);
        [self.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
            // Layout and move to next
            item.customView.frame = itemFrame;
            if (itemIndex == 4)
                *stop = YES;
            else
                itemFrame.origin.x += itemFrame.size.width + itemInsets.right + itemInsets.left;
            itemFrame.size.width = [self itemWidthForItemSize:ACCodeFileKeyboardAccessoryItemSizeSmall];
        }];
        itemFrame.origin.x = bounds.size.width - contentInsets.right - itemInsets.right;
        itemFrame.size.width = [self itemWidthForItemSize:ACCodeFileKeyboardAccessoryItemSizeSmallImportant];
        [self.items enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
            if (itemIndex <= 4)
            {
                *stop = YES;
                return;
            }
            
            // Layout and move to next
            itemFrame.origin.x -= itemFrame.size.width;
            item.customView.frame = itemFrame;
            itemFrame.origin.x -= itemInsets.right + itemInsets.left;
            itemFrame.size.width = [self itemWidthForItemSize:ACCodeFileKeyboardAccessoryItemSizeSmall];
        }];
    }
    else if (self.dockedBackgroundView)
    {
        self.dockedBackgroundView.frame = bounds;
        
        // Items
        CGRect itemFrame = CGRectMake(contentInsets.left + itemInsets.left, contentInsets.top + itemInsets.top, [self itemWidthForItemSize:currentSize], bounds.size.height - contentInsets.top - contentInsets.bottom - itemInsets.top - itemInsets.bottom);
        for (UIBarButtonItem *item in self.items)
        {
            if (item.width != 0)
                itemFrame.size.width = item.width;
            item.customView.frame = itemFrame;
            itemFrame.origin.x += itemFrame.size.width + itemInsets.right + itemInsets.left;
        }
    }
}

#pragma mark - Items Methods

- (void)setItems:(NSArray *)value
{
    [self setItems:value animated:NO];
}

- (void)setItems:(NSArray *)value animated:(BOOL)animated
{
    if (items == value)
        return;
    [self willChangeValueForKey:@"items"];
    // TODO animate
    for (UIBarButtonItem *item in items)
    {
        [item.customView removeFromSuperview];
    }
    items = value;
    for (UIBarButtonItem *item in items)
    {
        UIButton *itemButton = [UIButton new];
        [itemButton setBackgroundImage:self.itemBackgroundImage forState:UIControlStateNormal];
        [itemButton setTitle:item.title forState:UIControlStateNormal];
        // TODO initialize item
        item.customView = itemButton;
        [self addSubview:item.customView];
    }
    [self didChangeValueForKey:@"items"];
}

- (void)setItemWidth:(CGFloat)width forItemSize:(ACCodeFileKeyboardAccessoryItemSize)size;
{
    ECASSERT(size >= 0 && size < 4);
    _itemWidth[size] = width;
    if (self.currentItemSize == size)
        [self setNeedsLayout];
}

- (CGFloat)itemWidthForItemSize:(ACCodeFileKeyboardAccessoryItemSize)size;
{
    ECASSERT(size >= 0 && size < 4);
    return _itemWidth[size];
}

- (void)setContentInsets:(UIEdgeInsets)insets forItemSize:(ACCodeFileKeyboardAccessoryItemSize)size
{
    ECASSERT(size >= 0 && size < 3);
    _contentIntets[size] = insets;
    if (self.currentItemSize == size)
        [self setNeedsLayout];
}

- (UIEdgeInsets)contentInsetsForItemSize:(ACCodeFileKeyboardAccessoryItemSize)size
{
    ECASSERT(size >= 0 && size < 3);
    return _contentIntets[size];
}

- (void)setItemInsets:(UIEdgeInsets)insets forItemSize:(ACCodeFileKeyboardAccessoryItemSize)size
{
    ECASSERT(size >= 0 && size < 3);
    _itemInsets[size] = insets;
    if (self.currentItemSize == size)
        [self setNeedsLayout];
}

- (UIEdgeInsets)itemInsetsForItemSize:(ACCodeFileKeyboardAccessoryItemSize)size
{
    ECASSERT(size >= 0 && size < 3);
    return _itemInsets[size];
}

- (ACCodeFileKeyboardAccessoryItemSize)currentItemSize
{
    if (self.isSplit)
        return ACCodeFileKeyboardAccessoryItemSizeSmall;
    if (self.bounds.size.width > PORTRAIT_KEYBOARD_WIDTH)
        return ACCodeFileKeyboardAccessoryItemSizeBig;
    return ACCodeFileKeyboardAccessoryItemSizeNormal;
}

@end
