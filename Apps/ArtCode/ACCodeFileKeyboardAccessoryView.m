//
//  ACCodeFileKeyboardAccessoryView.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACCodeFileKeyboardAccessoryView.h"
#import <ECUIKit/ECInstantGestureRecognizer.h>
#import <objc/message.h>

// TODO see http://developer.apple.com/library/ios/#documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html#//apple_ref/doc/uid/TP40009542-CH12-SW1 for input clicks

static const void *itemContext;

@implementation ACCodeFileKeyboardAccessoryView {
    UIEdgeInsets _itemInsets[3];
    CGFloat _itemWidth[4];
    UIEdgeInsets _contentIntets[3];
    ECInstantGestureRecognizer *_itemPopoverViewDismissRecognizer;
}

#pragma mark - Private Methods

- (void)_handleDismissRecognizer:(ECInstantGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        [self dismissPopoverForItemAnimated:YES];
    }
}

- (ECInstantGestureRecognizer *)_itemPopoverViewDismissRecognizer
{
    if (!_itemPopoverViewDismissRecognizer)
    {
        _itemPopoverViewDismissRecognizer = [[ECInstantGestureRecognizer alloc] initWithTarget:self action:@selector(_handleDismissRecognizer:)];
//        _itemPopoverViewDismissRecognizer.cancelsTouchesInView = NO;
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
    [self willChangeValueForKey:@"itemBackgroundImage"];
    itemBackgroundImage = value;
    for (UIBarButtonItem *item in self.items)
    {
        [(UIButton *)item.customView setBackgroundImage:itemBackgroundImage forState:UIControlStateNormal];
    }
    [self didChangeValueForKey:@"itemBackgroundImage"];
}

- (ACCodeFileKeyboardAccessoryPopoverView *)itemPopoverView
{
    if (!itemPopoverView)
    {
        itemPopoverView = [ACCodeFileKeyboardAccessoryPopoverView new];
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
        item.customView = itemButton;
        [self addSubview:item.customView];
        // Adding observers
        [item addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&itemContext];
        [item addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&itemContext];
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
