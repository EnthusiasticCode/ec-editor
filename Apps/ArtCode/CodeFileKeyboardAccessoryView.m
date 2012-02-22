//
//  CodeFileKeyboardAccessoryView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CodeFileKeyboardAccessoryView.h"
#import "InstantGestureRecognizer.h"
#import <objc/message.h>

// TODO see http://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html#//apple_ref/doc/uid/TP40009542-CH12-SW1 for input clicks

static const void *itemContext;

@implementation CodeFileKeyboardAccessoryView {
    UIEdgeInsets _itemInsets[3];
    CGFloat _itemWidth[4];
    UIEdgeInsets _contentIntets[3];
    InstantGestureRecognizer *_itemPopoverViewDismissRecognizer;
}

#pragma mark - Private Methods

- (void)_handleDismissRecognizer:(InstantGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        [self dismissPopoverForItemAnimated:YES];
    }
}

- (InstantGestureRecognizer *)_itemPopoverViewDismissRecognizer
{
    if (!_itemPopoverViewDismissRecognizer)
    {
        _itemPopoverViewDismissRecognizer = [[InstantGestureRecognizer alloc] initWithTarget:self action:@selector(_handleDismissRecognizer:)];
        _itemPopoverViewDismissRecognizer.passTroughViews = [NSArray arrayWithObject:self.itemPopoverView.contentView];
    }
    return _itemPopoverViewDismissRecognizer;
}

#pragma mark - Properties

@synthesize items, itemBackgroundImage, itemPopoverView;

- (void)setItemBackgroundImage:(UIImage *)value
{
    if (value == itemBackgroundImage)
        return;
    itemBackgroundImage = value;
    for (UIBarButtonItem *item in self.items)
    {
        [(UIButton *)item.customView setBackgroundImage:itemBackgroundImage forState:UIControlStateNormal];
    }
}

- (CodeFileKeyboardAccessoryPopoverView *)itemPopoverView
{
    if (!itemPopoverView)
    {
        itemPopoverView = [CodeFileKeyboardAccessoryPopoverView new];
        itemPopoverView.alpha = 0;
    }
    return itemPopoverView;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &itemContext)
    {
        UIBarButtonItem *item = (UIBarButtonItem *)object;
        if ([keyPath isEqualToString:@"title"])
            [(UIButton *)item.customView setTitle:item.title forState:UIControlStateNormal];
        else if ([keyPath isEqualToString:@"image"])
            [(UIButton *)item.customView setImage:item.image forState:UIControlStateNormal];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
    KeyboardAccessoryPosition currentPosition = [self currentAccessoryPosition];
    UIEdgeInsets contentInsets = [self contentInsetsForAccessoryPosition:currentPosition];
    UIEdgeInsets itemInsets = [self itemInsetsForAccessoryPosition:currentPosition];
    if (currentPosition >= KeyboardAccessoryPositionFloating)
    {
        // Items
        __block CGRect itemFrame = CGRectMake(contentInsets.left + itemInsets.left, contentInsets.top + itemInsets.top, [self itemDefaultWidthForAccessoryPosition:currentPosition], bounds.size.height - contentInsets.top - contentInsets.bottom - itemInsets.top - itemInsets.bottom);
        [self.items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
            if ([item isKindOfClass:[CodeFileKeyboardAccessoryItem class]] 
                && [(CodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition])
                itemFrame.size.width = [(CodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition];
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
            if ([item isKindOfClass:[CodeFileKeyboardAccessoryItem class]] 
                && [(CodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition])
                itemFrame.size.width = [(CodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition];
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
            if ([item isKindOfClass:[CodeFileKeyboardAccessoryItem class]] 
                && [(CodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition])
                itemFrame.size.width = [(CodeFileKeyboardAccessoryItem *)item widthForAccessoryPosition:currentPosition];
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
    for (UIBarButtonItem *item in items)
    {
        [item.customView removeFromSuperview];
        [item removeObserver:self forKeyPath:@"title" context:&itemContext];
        [item removeObserver:self forKeyPath:@"image" context:&itemContext];
    }
    items = [value copy];
    [items enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger itemIndex, BOOL *stop) {
        // Creating button for item
        UIButton *itemButton = [UIButton new];
        itemButton.tag = itemIndex;
        [itemButton addTarget:self action:@selector(_itemButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [itemButton setBackgroundImage:self.itemBackgroundImage forState:UIControlStateNormal];
        [itemButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        itemButton.titleLabel.font = [UIFont systemFontOfSize:21];
        item.customView = itemButton;
        [self addSubview:item.customView];
        // Adding observers
        [item addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&itemContext];
        [item addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&itemContext];
    }];
}

- (void)setItemDefaultWidth:(CGFloat)width forAccessoryPosition:(KeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _itemWidth[position] = width;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (CGFloat)itemDefaultWidthForAccessoryPosition:(KeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _itemWidth[position];
}

- (void)setContentInsets:(UIEdgeInsets)insets forAccessoryPosition:(KeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _contentIntets[position] = insets;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (UIEdgeInsets)contentInsetsForAccessoryPosition:(KeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _contentIntets[position];
}

- (void)setItemInsets:(UIEdgeInsets)insets forAccessoryPosition:(KeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _itemInsets[position] = insets;
    if ([self currentAccessoryPosition] == position)
        [self setNeedsLayout];
}

- (UIEdgeInsets)itemInsetsForAccessoryPosition:(KeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _itemInsets[position];
}

#pragma mark - Popover Methods

@synthesize willPresentPopoverForItemBlock, willDismissPopoverForItemBlock;

- (void)presentPopoverForItemAtIndex:(NSUInteger)index permittedArrowDirection:(UIPopoverArrowDirection)direction animated:(BOOL)animated
{
    ECASSERT(index < [self.items count]);
    
    UIView *itemView = [[self.items objectAtIndex:index] customView];
    if (!itemView)
        return;
    
    // Get popover size
    UIEdgeInsets popoverContentInsets = self.itemPopoverView.contentInsets;
    CGSize popoverSize = self.itemPopoverView.contentSize;
    popoverSize.width += popoverContentInsets.left + popoverContentInsets.right;
    popoverSize.height += popoverContentInsets.top + popoverContentInsets.bottom;
    CGSize popoverSize_2 = CGSizeMake(popoverSize.width / 2.0, popoverSize.height / 2.0);
    
    // Set popover center
    UIEdgeInsets positioningInsets = self.itemPopoverView.positioningInsets;
    CGPoint center = itemView.center;
    center.x = MAX(popoverSize_2.width + positioningInsets.left, MIN(self.frame.size.width - popoverSize_2.width - positioningInsets.right, center.x));
    if (direction & UIPopoverArrowDirectionUp)
    {
        self.itemPopoverView.arrowDirection = UIPopoverArrowDirectionUp;
        center.y = CGRectGetMaxY(itemView.frame) + popoverSize_2.height - positioningInsets.top;
    }
    else
    {
        self.itemPopoverView.arrowDirection = UIPopoverArrowDirectionDown;
        center.y = itemView.frame.origin.y - popoverSize_2.height + positioningInsets.bottom;
    }

    // Dismiss popover if already visible
    BOOL shouldHidePopoverFirst = (self.itemPopoverView.superview != nil);
    if (shouldHidePopoverFirst && self.willDismissPopoverForItemBlock)
        self.willDismissPopoverForItemBlock(self, 0.25);
    
    // Present popover
    [self insertSubview:self.itemPopoverView belowSubview:itemView];
    [UIView animateWithDuration:shouldHidePopoverFirst ? 0.25 : 0 animations:^{
        self.itemPopoverView.alpha = 0;
    } completion:^(BOOL finished) {
        // Setup view
        self.itemPopoverView.center = center;
        self.itemPopoverView.arrowPosition = itemView.center.x - self.itemPopoverView.frame.origin.x;
        // Inform handler
        if (self.willPresentPopoverForItemBlock)
            self.willPresentPopoverForItemBlock(self, index, self.itemPopoverView.contentView.frame, 0.25);
        // Present
        [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
            self.itemPopoverView.alpha = 1;
        } completion:^(BOOL finished) {
            [self.window addGestureRecognizer:[self _itemPopoverViewDismissRecognizer]];
        }];
    }];    
}

- (void)dismissPopoverForItemAnimated:(BOOL)animated
{
    if (itemPopoverView.superview == nil)
        return;
    
    [self.window removeGestureRecognizer:[self _itemPopoverViewDismissRecognizer]];
    
    if (self.willDismissPopoverForItemBlock)
        self.willDismissPopoverForItemBlock(self, 0.25);
    
    [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
        itemPopoverView.alpha = 0;
    } completion:^(BOOL finished) {
        [itemPopoverView removeFromSuperview];
    }];
}

@end

@implementation CodeFileKeyboardAccessoryItem {
@private
    CGFloat _widthForPosition[3];
}

- (void)setWidth:(CGFloat)width forAccessoryPosition:(KeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    _widthForPosition[position] = width;
}

- (CGFloat)widthForAccessoryPosition:(KeyboardAccessoryPosition)position
{
    ECASSERT(position >= 0 && position < 3);
    return _widthForPosition[position];
}

@end
