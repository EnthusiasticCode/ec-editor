//
//  ECItemView.m
//  edit
//
//  Created by Uri Baghin on 4/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECItemView.h"

@interface ECItemView ()
{
    @private
    NSMutableArray *_items;
    NSInteger _numberOfItems;
}
- (NSInteger)_contentWidthInCells;
- (NSInteger)_contentHeightInCells;
@end

@implementation ECItemView

@synthesize dataSource = _dataSource;
@synthesize viewInsets = _viewInsets;
@synthesize itemFrame = _itemFrame;
@synthesize itemInsets = _itemInsets;

- (void)dealloc
{
    self.dataSource = nil;
    [_items release];
    [super dealloc];
}

static id init(ECItemView *self)
{
    self->_items = [[NSMutableArray alloc] init];
    self->_viewInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
    self->_itemInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
    self->_itemFrame = CGRectMake(0.0, 0.0, 100.0, 100.0);
    self->_numberOfItems = 0;
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    return init(self);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self)
        return nil;
    return init(self);
}

- (NSInteger)_contentWidthInCells
{
    return (NSInteger)((UIEdgeInsetsInsetRect(self.bounds, _viewInsets)).size.width / _itemFrame.size.width);
}

- (NSInteger)_contentHeightInCells
{
    return (NSInteger)(_numberOfItems / [self _contentWidthInCells]);
}

- (void)layoutSubviews
{
    __block CGRect frame = CGRectZero;
    [_items enumerateObjectsUsingBlock:^(ECItemViewCell *cell, NSUInteger index, BOOL *stop) {
        frame = [self rectForItem:index];
        if (!CGRectEqualToRect(frame, cell.frame))
            cell.frame = frame;
    }];
}

- (void)reloadData
{
    [_items removeAllObjects];
    UIView *oldCell = nil;
    ECItemViewCell *cell = nil;
    NSInteger i;
    for (i = 0; i < _numberOfItems; ++i)
    {
        oldCell = [self viewWithTag:i];
        [oldCell removeFromSuperview];
    }
    for (i = 0; i < [_dataSource numberOfItemsInItemView:self]; ++i)
    {
        cell = [_dataSource itemView:self cellForItem:i];
        cell.tag = i;
        [self addSubview:cell];
        [_items addObject:cell];
    }
    _numberOfItems = i;
    [self setNeedsLayout];
}

- (NSInteger)numberOfItems
{
    return _numberOfItems;
}

- (CGRect)rectForItem:(NSInteger)item
{
    CGRect rect = _itemFrame;
    rect.origin.x += rect.size.width * (NSInteger)(item % [self _contentWidthInCells]);
    rect.origin.y += rect.size.height * (NSInteger)(item / [self _contentWidthInCells]);
    return UIEdgeInsetsInsetRect(rect, _itemInsets);
}

- (NSInteger)itemAtPoint:(CGPoint)point
{
    CGRect itemRect = CGRectZero;
    for (NSInteger i = 0; i < _numberOfItems;)
    {
        itemRect = [self rectForItem:i];
        if (CGRectContainsPoint(itemRect, point))
            return i;
        if (itemRect.origin.y > point.y)
            break;
        if (point.y > itemRect.origin.y + itemRect.size.height)
            i += [self _contentWidthInCells];
        else
            ++i;
    }
    return -1;
}

@end
