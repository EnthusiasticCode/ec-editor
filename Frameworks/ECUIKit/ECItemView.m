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
    BOOL _needsReloadData;
    NSMutableArray *_items;
    NSInteger _numberOfItems;
    NSInteger _isBatchUpdating;
    NSMutableIndexSet *_itemsToInsert;
    NSMutableIndexSet *_itemsToDelete;
    NSMutableIndexSet *_itemsToReload;
    BOOL _isAnimating;
}
- (NSInteger)_contentWidthInCells;
- (NSInteger)_contentHeightInCells;
@end

@implementation ECItemView

#pragma mark -
#pragma mark Properties and initialization

@synthesize dataSource = _dataSource;
@synthesize viewInsets = _viewInsets;
@synthesize itemFrame = _itemFrame;
@synthesize itemInsets = _itemInsets;
@synthesize editing = _editing;

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (editing == _editing)
    return;
    [self willChangeValueForKey:@"editing"];
    [self setNeedsLayout];
    _editing = editing;
    if (animated && !_isBatchUpdating)
    {
        if (!_isAnimating)
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self layoutIfNeeded];
            } completion:^(BOOL finished){
                if (finished)
                    _isAnimating = NO;
            }];
        else
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
                [self layoutIfNeeded];
            }completion:^(BOOL finished){
                if (finished)
                    _isAnimating = NO;
            }];
        _isAnimating = YES;
    }
    [self didChangeValueForKey:@"editing"];   
}

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
    self->_needsReloadData = YES;
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

#pragma mark -
#pragma mark Private methods

- (NSInteger)_contentWidthInCells
{
    return (NSInteger)((UIEdgeInsetsInsetRect(self.bounds, _viewInsets)).size.width / _itemFrame.size.width);
}

- (NSInteger)_contentHeightInCells
{
    return (NSInteger)(_numberOfItems / [self _contentWidthInCells]);
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews
{
    if (_needsReloadData)
        [self reloadData];
    if (_isBatchUpdating)
        [NSException raise:NSInternalInconsistencyException format:@"beginUpdates without corresponding endUpdates"];
    __block CGRect frame = CGRectZero;
    [_items enumerateObjectsUsingBlock:^(ECItemViewCell *cell, NSUInteger index, BOOL *stop) {
        frame = [self rectForItem:index];
        if (!CGRectEqualToRect(frame, cell.frame))
            cell.frame = frame;
    }];
}

#pragma mark -
#pragma mark Public methods

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

- (void)beginUpdates
{
    ++_isBatchUpdating;
    [self setNeedsLayout];
    if (_needsReloadData)
        [self reloadData];
    _itemsToInsert = [NSMutableIndexSet indexSet];
    _itemsToDelete = [NSMutableIndexSet indexSet];
    _itemsToReload = [NSMutableIndexSet indexSet];
}

- (void)endUpdates
{
    --_isBatchUpdating;
    if (_isBatchUpdating < 0)
        [NSException raise:NSInternalInconsistencyException format:@"endUpdates called too many times"];
    _numberOfItems += [_itemsToInsert count];
    _numberOfItems -= [_itemsToDelete count];
    if (_numberOfItems != [_dataSource numberOfItemsInItemView:self])
        [NSException raise:NSInternalInconsistencyException format:@"numberOfItems != old numberOfItems +insertedItems -deletedItems"];
    ECItemViewCell *cell;
    NSInteger offset = 0;
    for (NSInteger index = 0; index < _numberOfItems; ++index)
    {
        if ([_itemsToDelete containsIndex:index])
        {
            cell = [_items objectAtIndex:index + offset];
            [cell removeFromSuperview];
            [_items removeObjectAtIndex:index + offset];
            --offset;
        }
        if ([_itemsToInsert containsIndex:index])
        {
            cell = [_dataSource itemView:self cellForItem:index];
            [self addSubview:cell];
            [_items insertObject:cell atIndex:index];
            ++offset;
        }
        if ([_itemsToReload containsIndex:index])
        {
            cell = [_items objectAtIndex:index + offset];
            [cell removeFromSuperview];
            [_items removeObjectAtIndex:index + offset];
            cell = [_dataSource itemView:self cellForItem:index];
            [self addSubview:cell];
            [_items insertObject:cell atIndex:index];
        }
    }
}

- (void)insertItems:(NSIndexSet *)items
{
    [_itemsToInsert addIndexes:items];
}

- (void)deleteItems:(NSIndexSet *)items
{
    [_itemsToDelete addIndexes:items];
}

- (void)reloadItems:(NSIndexSet *)items
{
    [_itemsToReload addIndexes:items];
}

@end
