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
    BOOL _delegateDidSelectItem;
    BOOL _needsReloadData;
    NSMutableArray *_items;
    NSInteger _numberOfItems;
    NSInteger _isBatchUpdating;
    NSMutableIndexSet *_itemsToInsert;
    NSMutableIndexSet *_itemsToDelete;
    NSMutableIndexSet *_itemsToReload;
    BOOL _isAnimating;
    UITapGestureRecognizer *_tapRecognizer;
    BOOL _isDragging;
    NSMutableArray *_itemsWhileDragging;
}
- (NSInteger)_contentWidthInCells;
- (NSInteger)_contentHeightInCells;
- (void)handleTap:(UITapGestureRecognizer *)tapRecognizer;
@end

@implementation ECItemView

#pragma mark -
#pragma mark Properties and initialization

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize viewInsets = _viewInsets;
@synthesize itemFrame = _itemFrame;
@synthesize itemInsets = _itemInsets;
@synthesize allowsSelection = _allowsSelection;
@synthesize editing = _editing;

- (void)setDelegate:(id<ECItemViewDelegate>)delegate
{
    if (delegate == _delegate)
        return;
    [self willChangeValueForKey:@"delegate"];
    _delegate = delegate;
    _delegateDidSelectItem = [delegate respondsToSelector:@selector(itemView:didSelectItem:)];
    [self didChangeValueForKey:@"delegate"];
}

- (void)setAllowsSelection:(BOOL)allowsSelection
{
    if (allowsSelection == _allowsSelection)
        return;
    [self willChangeValueForKey:@"allowsSelection"];
    _allowsSelection = allowsSelection;
    _tapRecognizer.enabled = allowsSelection;
    [self didChangeValueForKey:@"allowsSelection"];
}

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
    self.delegate = nil;
    [_items release];
    [_tapRecognizer release];
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
    self->_allowsSelection = YES;
    self->_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:self->_tapRecognizer];
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
    void (^layoutItem)(ECItemViewCell *cell, NSUInteger index, BOOL *stop) = ^(ECItemViewCell *cell, NSUInteger index, BOOL *stop){
        frame = [self rectForItem:index];
        if (!CGRectEqualToRect(frame, cell.frame))
            cell.frame = frame;
    };
    if (_isDragging)
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            [_items enumerateObjectsUsingBlock:layoutItem];
        } completion:NULL];
    else
        [_items enumerateObjectsUsingBlock:layoutItem];
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
    _numberOfItems = [_dataSource numberOfItemsInItemView:self];
    for (i = 0; i < _numberOfItems; ++i)
    {
        cell = [_dataSource itemView:self cellForItem:i];
        [self addSubview:cell];
        [_items addObject:cell];
    }
    [self setNeedsLayout];
    _needsReloadData = NO;
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
    NSInteger offset = 0;
    NSMutableArray *cellsToInsert = [NSMutableArray arrayWithCapacity:[_itemsToInsert count]];
    NSMutableArray *cellsToDelete = [NSMutableArray arrayWithCapacity:[_itemsToDelete count]];
    NSMutableArray *cellsToLoad = [NSMutableArray arrayWithCapacity:[_itemsToReload count]];
    NSMutableArray *cellsToUnload = [NSMutableArray arrayWithCapacity:[_itemsToReload count]];
    for (NSInteger index = 0; index < _numberOfItems; ++index)
    {
        ECItemViewCell *cell;
        if ([_itemsToDelete containsIndex:index])
        {
            cell = [_items objectAtIndex:index + offset];
            [cellsToDelete addObject:cell];
            [_items removeObjectAtIndex:index + offset];
            --offset;
        }
        if ([_itemsToInsert containsIndex:index])
        {
            cell = [_dataSource itemView:self cellForItem:index];
            [self addSubview:cell];
            CGRect rect = [self rectForItem:index];
            cell.center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
            cell.alpha = 0.0;
            [cellsToInsert addObject:cell];
            [_items insertObject:cell atIndex:index];
            ++offset;
        }
        if ([_itemsToReload containsIndex:index])
        {
            cell = [_items objectAtIndex:index + offset];
            [cellsToUnload addObject:cell];
            [_items removeObjectAtIndex:index + offset];
            cell = [_dataSource itemView:self cellForItem:index];
            [self addSubview:cell];
            cell.frame = [self rectForItem:index];
            cell.alpha = 0.0;
            [cellsToLoad addObject:cell];
            [_items insertObject:cell atIndex:index];
        }
    }
    [UIView animateWithDuration:3.0 animations:^(void) {
        for (ECItemViewCell *cell in cellsToInsert) {
            cell.bounds = UIEdgeInsetsInsetRect(_itemFrame, _itemInsets);
            cell.alpha = 1.0;
        }
        for (ECItemViewCell *cell in cellsToDelete) {
            cell.bounds = CGRectZero;
            cell.alpha = 0.0;
        }
        for (ECItemViewCell *cell in cellsToLoad) {
            cell.alpha = 1.0;
        }
        for (ECItemViewCell *cell in cellsToUnload ) {
            cell.alpha = 0.0;
        }
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        for (ECItemViewCell *cell in cellsToDelete)
        {
            [cell removeFromSuperview];
        }
        for (ECItemViewCell *cell in cellsToUnload)
        {
            [cell removeFromSuperview];
        }
    }];
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

#pragma mark -
#pragma mark UIGestureRecognizer

- (void)handleTap:(UITapGestureRecognizer *)tapRecognizer
{
    if (_editing)
        return;
    NSInteger itemIndex = [self itemAtPoint:[tapRecognizer locationInView:self]];
    if (itemIndex == -1)
        return;
    if (_delegateDidSelectItem)
        [_delegate itemView:self didSelectItem:itemIndex];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([self itemAtPoint:[touch locationInView:self]] != -1)
        return YES;
    return NO;
}

@end
