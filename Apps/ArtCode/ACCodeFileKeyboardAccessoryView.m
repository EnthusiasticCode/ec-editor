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

@implementation ACCodeFileKeyboardAccessoryView {
    UIImage *_itemBackgroundImages[4];
    UIEdgeInsets _itemsInsets[3];
}

// TODO see http://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html#//apple_ref/doc/uid/TP40009542-CH12-SW1 for input clicks
#pragma mark - Properties

@synthesize split, flipped;
@synthesize dockedBackgroundView, splitLeftBackgroundView, splitRightBackgroundView, splitBackgroundViewInsets;
@synthesize items;

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

#pragma mark - View's Methods

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    if (self.isSplit && self.splitLeftBackgroundView)
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
        
        // Items
        UIEdgeInsets itemsInsets = [self itemsInsetsForItemSize:self.currentItemSize];
        __block CGRect itemFrame = CGRectMake(itemsInsets.left, 
                                              itemsInsets.top, 44, 
                                              bounds.size.height - itemsInsets.top - itemsInsets.bottom);
        [self.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
            item.customView.frame = itemFrame;
            if (itemIndex == 4)
                itemFrame.origin.x = bounds.size.width - SPLIT_KEYBOARD_RIGHT_SEGMENT_WIDTH + itemsInsets.left;
            else
                itemFrame.origin.x += itemFrame.size.width + 7;
            itemFrame.size.width = itemIndex == 10 ? 44 : 36;
        }];
    }
    else if (self.dockedBackgroundView)
    {
        self.dockedBackgroundView.frame = bounds;
        
        // Items
        UIEdgeInsets itemsInsets = [self itemsInsetsForItemSize:self.currentItemSize];
        CGFloat itemGap = self.currentItemSize == ACCodeFileKeyboardAccessoryItemSizeNormal ? 10 : 12;
        CGRect itemFrame = CGRectMake(itemsInsets.left, 
                                      itemsInsets.top, 
                                      self.currentItemSize == ACCodeFileKeyboardAccessoryItemSizeNormal ? 59 : 81,
                                      bounds.size.height - itemsInsets.top - itemsInsets.bottom);
        for (UIBarButtonItem *item in self.items)
        {
            item.customView.frame = itemFrame;
            itemFrame.origin.x += itemFrame.size.width + itemGap;
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
    UIImage *itemImage = [self buttonItemBackgroundImageForItemSize:self.currentItemSize];
    for (UIBarButtonItem *item in items)
    {
        UIButton *itemButton = [UIButton new];
        [itemButton setBackgroundImage:itemImage forState:UIControlStateNormal];
        [itemButton setTitle:item.title forState:UIControlStateNormal];
        // TODO initialize item
        item.customView = itemButton;
        [self addSubview:item.customView];
    }
    [self didChangeValueForKey:@"items"];
}

- (void)setButtonItemBackgroundImage:(UIImage *)image forItemSize:(ACCodeFileKeyboardAccessoryItemSize)size
{
    ECASSERT(size >= 0 && size < 4);
    _itemBackgroundImages[size] = image;
    if (self.currentItemSize == size)
    {
        for (UIBarButtonItem *item in self.items)
        {
            [(UIButton *)item.customView setBackgroundImage:image forState:UIControlStateNormal];
        }
    }
}

- (UIImage *)buttonItemBackgroundImageForItemSize:(ACCodeFileKeyboardAccessoryItemSize)size
{
    ECASSERT(size >= 0 && size < 4);
    return _itemBackgroundImages[size];
}

- (void)setItemsInsets:(UIEdgeInsets)insets forItemSize:(ACCodeFileKeyboardAccessoryItemSize)size
{
    ECASSERT(size >= 0 && size < 3);
    _itemsInsets[size] = insets;
    if (self.currentItemSize == size)
        [self setNeedsLayout];
}

- (UIEdgeInsets)itemsInsetsForItemSize:(ACCodeFileKeyboardAccessoryItemSize)size
{
    ECASSERT(size >= 0 && size < 3);
    return _itemsInsets[size];
}

- (ACCodeFileKeyboardAccessoryItemSize)currentItemSize
{
    if (self.isSplit)
        return ACCodeFileKeyboardAccessoryItemSizeSmall;
    if (self.bounds.size.width > 768)
        return ACCodeFileKeyboardAccessoryItemSizeBig;
    return ACCodeFileKeyboardAccessoryItemSizeNormal;
}

@end
