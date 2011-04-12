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
    BOOL _delegateShouldDragItem;
    BOOL _delegateCanDropItem;
    BOOL _delegateDidDropItem;
    BOOL _needsReloadData;
    NSMutableArray *_items;
    NSInteger _numberOfItems;
    NSInteger _isBatchUpdating;
    NSMutableIndexSet *_itemsToInsert;
    NSMutableIndexSet *_itemsToDelete;
    NSMutableIndexSet *_itemsToReload;
    BOOL _isAnimating;
    UITapGestureRecognizer *_tapRecognizer;
    UIPanGestureRecognizer *_dragRecognizer;
    BOOL _isDragging;
    ECItemViewCell *_draggedItem;
    NSInteger _draggedItemIndex;
    NSInteger _previousDragDestination;
    NSMutableArray *_itemsWhileDragging;
    UIView *_viewToDragIn;
}
- (NSInteger)_contentWidthInCells;
- (NSInteger)_contentHeightInCells;
- (NSInteger)_itemAtPoint:(CGPoint)point includingPadding:(BOOL)includingPadding;
- (NSInteger)_paddedItemAtPoint:(CGPoint)point;
- (CGRect)_paddedRectForItem:(NSInteger)item;
- (CGPoint)_centerForItem:(NSInteger)item;
- (void)_handleTap:(UITapGestureRecognizer *)tapRecognizer;
- (void)_handleDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (void)_beginDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (void)_continueDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (void)_endDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (void)_cancelDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (NSInteger)_receiveDroppedCell:(ECItemViewCell *)cell fromDrag:(UIPanGestureRecognizer *)dragRecognizer;
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
@synthesize allowsDragging = _allowsDragging;
@synthesize editing = _editing;

- (void)setDelegate:(id<ECItemViewDelegate>)delegate
{
    if (delegate == _delegate)
        return;
    [self willChangeValueForKey:@"delegate"];
    _delegate = delegate;
    _delegateDidSelectItem = [delegate respondsToSelector:@selector(itemView:didSelectItem:)];
    _delegateShouldDragItem = [delegate respondsToSelector:@selector(itemView:shouldDragItem:inView:)];
    _delegateCanDropItem = [delegate respondsToSelector:@selector(itemView:canDropItem:inTargetItemView:)];
    _delegateDidDropItem = [delegate respondsToSelector:@selector(itemView:didDropItem:inTargetItemView:atIndex:)];
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

- (void)setAllowsDragging:(BOOL)allowsDragging
{
    if (allowsDragging == _allowsDragging)
        return;
    [self willChangeValueForKey:@"allowsDragging"];
    _allowsDragging = allowsDragging;
    _dragRecognizer.enabled = allowsDragging;
    [self didChangeValueForKey:@"allowsDragging"];
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
    [_dragRecognizer release];
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
    self->_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTap:)];
    self->_tapRecognizer.delegate = self;
    [self addGestureRecognizer:self->_tapRecognizer];
    self->_allowsDragging = YES;
    self->_dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleDrag:)];
    self->_dragRecognizer.cancelsTouchesInView = NO;
    self->_dragRecognizer.delegate = self;
    [self addGestureRecognizer:self->_dragRecognizer];
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

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews
{
    if (_needsReloadData)
        [self reloadData];
    if (_isBatchUpdating)
        [NSException raise:NSInternalInconsistencyException format:@"beginUpdates without corresponding endUpdates"];
    __block CGPoint center = CGPointZero;
    void (^layoutItem)(ECItemViewCell *cell, NSUInteger index, BOOL *stop) = ^(ECItemViewCell *cell, NSUInteger index, BOOL *stop){
        if (_isDragging && cell == _draggedItem)
            return;
        center = [self _centerForItem:index];
        if (!CGPointEqualToPoint(center, cell.center))
            cell.center = center;
    };
    if (_isDragging)
        [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^(void) {
            [_itemsWhileDragging enumerateObjectsUsingBlock:layoutItem];
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
        cell.frame = [self rectForItem:i];
        cell.tag = i;
        [_items addObject:cell];
    }
    _needsReloadData = NO;
}

- (NSInteger)numberOfItems
{
    return _numberOfItems;
}

- (CGRect)_paddedRectForItem:(NSInteger)item
{
    CGRect rect = _itemFrame;
    rect.origin.x += rect.size.width * (NSInteger)(item % [self _contentWidthInCells]);
    rect.origin.y += rect.size.height * (NSInteger)(item / [self _contentWidthInCells]);
    return rect;
}

- (CGRect)rectForItem:(NSInteger)item
{
    CGRect rect = [self _paddedRectForItem:item];
    return UIEdgeInsetsInsetRect(rect, _itemInsets);
}

- (CGPoint)_centerForItem:(NSInteger)item
{
    CGRect rect = [self rectForItem:item];
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

- (NSInteger)_itemAtPoint:(CGPoint)point includingPadding:(BOOL)includingPadding
{
    CGRect itemRect = CGRectZero;
    for (NSInteger i = 0; i < _numberOfItems;)
    {
        if (includingPadding)
            itemRect = [self _paddedRectForItem:i];
        else
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

- (NSInteger)itemAtPoint:(CGPoint)point
{
    return [self _itemAtPoint:point includingPadding:NO];
}

- (NSInteger)_paddedItemAtPoint:(CGPoint)point
{
    return [self _itemAtPoint:point includingPadding:YES];
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

- (void)_handleTap:(UITapGestureRecognizer *)tapRecognizer
{
    if (_editing)
        return;
    NSInteger itemIndex = [self itemAtPoint:[tapRecognizer locationInView:self]];
    if (itemIndex == -1)
        return;
    if (_delegateDidSelectItem)
        [_delegate itemView:self didSelectItem:itemIndex];
}

- (void)_beginDrag:(UIPanGestureRecognizer *) dragRecognizer
{
    _isDragging = YES;
    _itemsWhileDragging = [_items mutableCopy];
    _draggedItemIndex = [self itemAtPoint:[dragRecognizer locationInView:self]];
    _draggedItem = [_items objectAtIndex:_draggedItemIndex];
    _previousDragDestination = _draggedItemIndex;
    [_viewToDragIn addSubview:_draggedItem];
    [_viewToDragIn bringSubviewToFront:_draggedItem];
    _draggedItem.center = [dragRecognizer locationInView:_viewToDragIn];
}

- (void)_continueDrag:(UIPanGestureRecognizer *) dragRecognizer
{
    _draggedItem.center = [dragRecognizer locationInView:_viewToDragIn];
    NSInteger dragDestination = [self _paddedItemAtPoint:[dragRecognizer locationInView:self]];
    if (dragDestination == _previousDragDestination)
        return;
    if (_previousDragDestination != -1)
        [_itemsWhileDragging removeObjectAtIndex:_previousDragDestination];
    if (dragDestination != -1)
        [_itemsWhileDragging insertObject:_draggedItem atIndex:dragDestination];
    _previousDragDestination = dragDestination;
    [self setNeedsLayout];
}

- (void)_endDrag:(UIPanGestureRecognizer *)dragRecognizer
{
    ECItemView *targetView = (ECItemView *)[_viewToDragIn hitTest:[dragRecognizer locationInView:_viewToDragIn] withEvent:nil];
    while ([targetView class] != [ECItemView class])
    {
        if (targetView != _viewToDragIn)
        {
            targetView = (ECItemView *)[targetView superview];
            continue;
        }
        [self _cancelDrag:dragRecognizer];
        return;
    }
    if (![_delegate itemView:self canDropItem:_draggedItemIndex inTargetItemView:targetView])
    {
        [self _cancelDrag:dragRecognizer];
        return;
    }
    if (targetView == self)
    {
        NSInteger dragDestination = [self _paddedItemAtPoint:[dragRecognizer locationInView:self]];
        if (dragDestination == -1)
        {
            [self _cancelDrag:dragRecognizer];
            return;
        }
        [_items removeObjectAtIndex:_draggedItemIndex];
        [_items insertObject:_draggedItem atIndex:dragDestination];
        [UIView animateWithDuration:0.25 animations:^(void) {
            _draggedItem.center = [self convertPoint:[self _centerForItem:dragDestination] toView:_viewToDragIn];
        } completion:^(BOOL finished) {
            [self addSubview:_draggedItem];
        }];
        if (_delegateDidDropItem)
            [_delegate itemView:self didDropItem:_draggedItemIndex inTargetItemView:self atIndex:dragDestination];
    }
    else
    {
        NSInteger dragDestination = [targetView _receiveDroppedCell:_draggedItem fromDrag:dragRecognizer];
        if (dragDestination == -1)
        {
            [self _cancelDrag:dragRecognizer];
            return;
        }
        [_items removeObjectAtIndex:_draggedItemIndex];
        if (_delegateDidDropItem)
            [_delegate itemView:self didDropItem:_draggedItemIndex inTargetItemView:targetView atIndex:dragDestination];
    }
    [_itemsWhileDragging release];
    _itemsWhileDragging = _items;
    [self setNeedsLayout];
    [UIView animateWithDuration:0.25 animations:^(void) {
        [self layoutIfNeeded];
    }];
    _isDragging = NO;
}

- (NSInteger)_receiveDroppedCell:(ECItemViewCell *)cell fromDrag:(UIPanGestureRecognizer *)dragRecognizer
{
    NSInteger dragDestination = [self _paddedItemAtPoint:[dragRecognizer locationInView:self]];
    if (dragDestination == -1)
        return -1;
    [_items insertObject:cell atIndex:dragDestination];
    [UIView animateWithDuration:0.25 animations:^(void) {
        _draggedItem.center = [self convertPoint:[self _centerForItem:dragDestination] toView:_viewToDragIn];
    } completion:^(BOOL finished) {
        [self addSubview:_draggedItem];
    }];
    return dragDestination;
}

- (void)_cancelDrag:(UIPanGestureRecognizer *)dragRecognizer
{
    [_itemsWhileDragging release];
    _itemsWhileDragging = _items;
    [self setNeedsLayout];
    [UIView animateWithDuration:0.25 animations:^(void) {
        [self layoutIfNeeded];
    }];
    [UIView animateWithDuration:0.25 animations:^(void) {
        _draggedItem.center = [self convertPoint:[self _centerForItem:_draggedItemIndex] toView:_viewToDragIn];
    } completion:^(BOOL finished) {
        [self addSubview:_draggedItem];
    }];
    _isDragging = NO;
}

- (void)_handleDrag:(UIPanGestureRecognizer *)dragRecognizer
{
    if ([dragRecognizer state] == UIGestureRecognizerStateBegan)
        [self _beginDrag:dragRecognizer];
    else if ([dragRecognizer state] == UIGestureRecognizerStateChanged)
    {
        ECItemView *targetView = (ECItemView *)[_viewToDragIn hitTest:[dragRecognizer locationInView:_viewToDragIn] withEvent:nil];
        while ([targetView class] != [ECItemView class])
        {
            if (targetView != _viewToDragIn)
            {
                targetView = (ECItemView *)[targetView superview];
                continue;
            }
            [self _continueDrag:dragRecognizer];
            return;
        }
        [targetView _continueDrag:dragRecognizer];   
    }
    else if ([dragRecognizer state] == UIGestureRecognizerStateEnded)
        [self _endDrag:dragRecognizer];
    else
        [self _cancelDrag:dragRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    NSLog(@"should receive");
    if ([self itemAtPoint:[touch locationInView:self]] != -1)
        return YES;
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == _tapRecognizer)
        return YES;
    if (!_delegateShouldDragItem || !_delegateCanDropItem)
        return NO;
    _viewToDragIn = nil;
    NSInteger item = [self itemAtPoint:[_dragRecognizer locationInView:self]];
    if (item == -1)
        return NO;
    BOOL shouldBegin = [_delegate itemView:self shouldDragItem:item inView:&_viewToDragIn];
    if (shouldBegin)
        if (![self isDescendantOfView:_viewToDragIn])
            _viewToDragIn = self;
    return shouldBegin;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    NSLog(@"should recognize simultaneously");
    if ([otherGestureRecognizer.delegate class] == [ECItemView class])
        return YES;
    return NO;
}

@end
