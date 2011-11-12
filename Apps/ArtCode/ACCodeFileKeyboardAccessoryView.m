//
//  ACCodeFileKeyboardAccessoryView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryView.h"
#import <objc/message.h>

// TODO see http://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html#//apple_ref/doc/uid/TP40009542-CH12-SW1 for input clicks

@implementation ACCodeFileKeyboardAccessoryView {
    UIEdgeInsets _itemInsets[3];
    CGFloat _itemWidth[4];
    UIEdgeInsets _contentIntets[3];
}

#pragma mark - Properties

@synthesize items, itemBackgroundImage;

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

#pragma mark - View Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    
    self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    // Setup backgrounds
    self.dockedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundDocked"]];
    UIImageView *splitBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundSplitLeftTop"]];
    splitBackgroundView.contentMode = UIViewContentModeTopLeft;
    self.splitLeftBackgroundView = splitBackgroundView;
    splitBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"accessoryView_backgroundSplitRightTop"]];
    splitBackgroundView.contentMode = UIViewContentModeTopRight;
    self.splitRightBackgroundView = splitBackgroundView;
    self.splitBackgroundViewInsets = UIEdgeInsetsMake(-10, 0, 0, 0);
    
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // This will make touches to pass through when the accessory is splitted but,
    // unlike userInteractionEnabled = NO, let subviews handle touches.
    UIView *hitTestView = [super hitTest:point withEvent:event];
    if (hitTestView == self)
        return nil;
    return hitTestView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect bounds = self.bounds;
    ECKeyboardAccessoryPosition currentPosition = [self currentAccessoryPosition];
    UIEdgeInsets contentInsets = [self contentInsetsForAccessoryPosition:currentPosition];
    UIEdgeInsets itemInsets = [self itemInsetsForAccessoryPosition:currentPosition];
    if (currentPosition >= ECKeyboardAccessoryPositionFloating)
    {
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
    if (tag < [self.items count])
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
    items = [value copy];
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

- (void)setItemDefaultWidth:(CGFloat)width forAccessoryPosition:(ECKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _itemWidth[position] = width;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (CGFloat)itemDefaultWidthForAccessoryPosition:(ECKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _itemWidth[position];
}

- (void)setContentInsets:(UIEdgeInsets)insets forAccessoryPosition:(ECKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _contentIntets[position] = insets;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (UIEdgeInsets)contentInsetsForAccessoryPosition:(ECKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _contentIntets[position];
}

- (void)setItemInsets:(UIEdgeInsets)insets forAccessoryPosition:(ECKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _itemInsets[position] = insets;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (UIEdgeInsets)itemInsetsForAccessoryPosition:(ECKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _itemInsets[position];
}

@end

@implementation ACCodeFileKeyboardAccessoryItem {
@private
    CGFloat _widthForPosition[3];
}

- (void)setWidth:(CGFloat)width forAccessoryPosition:(ECKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _widthForPosition[position] = width;
}

- (CGFloat)widthForAccessoryPosition:(ECKeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _widthForPosition[position];
}

@end
