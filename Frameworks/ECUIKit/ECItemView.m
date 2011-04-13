//
//  ECItemView.m
//  edit
//
//  Created by Uri Baghin on 4/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECItemView.h"
#import "UIView+ConcurrentAnimation.h"

const NSUInteger ECItemViewItemNotFound = NSUIntegerMax;

@interface ECItemViewDragContainer : UIView
@property (nonatomic, retain) UIView *view;
- (id)initWithView:(UIView *)view;
+ (id)containerWithView:(UIView *)view;
@end

#pragma mark -

@implementation ECItemViewDragContainer

@synthesize view = _view;

- (void)setView:(UIView *)view
{
    if (view == _view)
        return;
    [self willChangeValueForKey:@"view"];
    if ([_view superview] == self)
        [_view removeFromSuperview];        
    [_view release];
    _view = [view retain];
    if (_view)
    {
        self.frame = _view.frame;
        [self addSubview:_view];
        _view.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    }
}

- (void)dealloc
{
    self.view = nil;
    [super dealloc];
}

- (id)initWithView:(UIView *)view
{
    self = [super init];
    if (!self)
        return nil;
    self.view = view;
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return NO;
}

+ (id)containerWithView:(UIView *)view
{
    id container = [self alloc];
    container = [container initWithView:view];
    return [container autorelease];
}

@end

#pragma mark -

@interface ECItemView ()
{
    @private
    BOOL _delegateDidSelectItem;
    BOOL _delegateShouldDragItem;
    BOOL _delegateCanDropItem;
    BOOL _delegateDidDropItem;
    NSMutableArray *_items;
    NSUInteger _isBatchUpdating;
    NSMutableDictionary *_itemsToInsert;
    NSMutableDictionary *_itemsToDelete;
    NSMutableDictionary *_itemsToReload;
    BOOL _isAnimating;
    UITapGestureRecognizer *_tapRecognizer;
    UIPanGestureRecognizer *_dragRecognizer;
    BOOL _isDragging;
    ECItemViewDragContainer *_draggedItemContainer;
    NSUInteger _draggedItemIndex;
    NSUInteger _currentDragDestination;
    ECItemView *_currentDragTarget;
    UIView *_viewToDragIn;
    void (^_layoutItem)(UIView *item, NSUInteger index, BOOL *stop);
    void (^_enterEditingAnimation)(void);
    void (^_exitEditingAnimation)(void);
}
- (void)_setup;
- (NSUInteger)columns;
- (NSUInteger)rows;
- (NSUInteger)_itemAtPoint:(CGPoint)point includingPadding:(BOOL)includingPadding;
- (CGRect)_paddedRectForItem:(NSUInteger)item;
- (CGPoint)_centerForItem:(NSUInteger)item;
- (void)_handleTap:(UITapGestureRecognizer *)tapRecognizer;
- (void)_handleDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (void)_beginDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (void)_continueDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (BOOL)_endDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (void)_cancelDrag:(UIPanGestureRecognizer *)dragRecognizer;
- (ECItemView *)_targetForDrop:(UIPanGestureRecognizer *)dragRecognizer;
- (NSUInteger)_indexOfDropAtPoint:(CGPoint)point;
- (void)_receiveDroppedItemContainer:(ECItemViewDragContainer *)itemContainer forItem:(NSUInteger)item;
@end

#pragma mark -

@implementation ECItemView

static const CGFloat ECItemViewShortAnimationDuration = 0.15;
static const CGFloat ECItemViewLongAnimationDuration = 5.0;

#pragma mark Properties and initialization

@synthesize delegate = _delegate;
@synthesize items = _items;
@synthesize viewInsets = _viewInsets;
@synthesize itemBounds = _itemBounds;
@synthesize itemInsets = _itemInsets;
@synthesize animatesChanges = _animatesChanges;
@synthesize allowsSelection = _allowsSelection;
@synthesize allowsDragging = _allowsDragging;
@synthesize editing = _isEditing;

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

- (void)setItems:(NSArray *)items
{
    if (items == _items)
        return;
    [self willChangeValueForKey:@"items"];
    [_items release];
    _items = [items mutableCopy];
    for (UIView *item in _items) {
        [self addSubview:item];
        item.bounds = UIEdgeInsetsInsetRect(_itemBounds, _itemInsets);
    }
    [self setNeedsLayout];
    [self didChangeValueForKey:@"items"];
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
    if (editing == _isEditing)
        return;
    [self willChangeValueForKey:@"editing"];
    [self setNeedsLayout];
    _isEditing = editing;
    if (_animatesChanges)
        if (editing)
            [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:_enterEditingAnimation completion:NULL];
        else
            [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:_exitEditingAnimation completion:NULL];
    [self didChangeValueForKey:@"editing"];  
}

- (void)dealloc
{
    self.delegate = nil;
    self.items = nil;
    [_tapRecognizer release];
    [_dragRecognizer release];
    [_layoutItem release];
    [_enterEditingAnimation release];
    [_exitEditingAnimation release];
    [super dealloc];
}

- (void)_setup
{
    _viewInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
    _itemInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
    _itemBounds = CGRectMake(0.0, 0.0, 100.0, 100.0);
    _animatesChanges = YES;
    _allowsSelection = YES;
    _allowsDragging = YES;
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTap:)];
    _tapRecognizer.delegate = self;
    [self addGestureRecognizer:_tapRecognizer];
    _dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_handleDrag:)];
    _dragRecognizer.delegate = self;
    [self addGestureRecognizer:_dragRecognizer];
    _currentDragDestination = ECItemViewItemNotFound;
    _currentDragTarget = self;
    _draggedItemIndex = ECItemViewItemNotFound;
    _layoutItem = [^(UIView *cell, NSUInteger index, BOOL *stop){
        if (index == _draggedItemIndex)
            return;
        if (index > _draggedItemIndex)
            --index;
        if (index >= _currentDragDestination)
            ++index;
        CGPoint center = [self _centerForItem:index];
        if (!CGPointEqualToPoint(center, cell.center))
            cell.center = center;
    } copy];
    _enterEditingAnimation = [^{
        [self layoutIfNeeded];
    } copy];
    _exitEditingAnimation = [^{
        [self layoutIfNeeded];
    } copy];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews
{
    if (_isBatchUpdating)
        [NSException raise:NSInternalInconsistencyException format:@"beginUpdates without corresponding endUpdates"];
    if (_animatesChanges)
        [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:^(void) {
            [_items enumerateObjectsUsingBlock:_layoutItem];
        } completion:NULL];
    else
        [_items enumerateObjectsUsingBlock:_layoutItem];
}

#pragma mark -
#pragma mark Public methods

- (NSUInteger)columns
{
    return (NSUInteger)((UIEdgeInsetsInsetRect(self.bounds, _viewInsets)).size.width / _itemBounds.size.width);
}

- (NSUInteger)rows
{
    return (NSUInteger)([_items count] / [self columns]);
}

- (CGRect)_paddedRectForItem:(NSUInteger)item
{
    CGRect rect = _itemBounds;
    rect.origin.x += _viewInsets.left;
    rect.origin.y += _viewInsets.top;
    rect.origin.x += rect.size.width * (NSUInteger)(item % [self columns]);
    rect.origin.y += rect.size.height * (NSUInteger)(item / [self columns]);
    return rect;
}

- (CGRect)rectForItem:(NSUInteger)item
{
    CGRect rect = [self _paddedRectForItem:item];
    return UIEdgeInsetsInsetRect(rect, _itemInsets);
}

- (CGPoint)_centerForItem:(NSUInteger)item
{
    CGRect rect = [self rectForItem:item];
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

- (NSUInteger)_itemAtPoint:(CGPoint)point includingPadding:(BOOL)includingPadding
{
    CGRect itemRect = CGRectZero;
    NSUInteger numItems = [_items count];
    for (NSUInteger i = 0; i < numItems;)
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
            i += [self columns];
        else
            ++i;
    }
    return ECItemViewItemNotFound;
}

- (NSUInteger)itemAtPoint:(CGPoint)point
{
    return [self _itemAtPoint:point includingPadding:NO];
}

/*- (void)beginUpdates
{
    if (!_isBatchUpdating)
    {
        _itemsToInsert = [NSMutableDictionary dictionary];
        _itemsToDelete = [NSMutableDictionary dictionary];
        _itemsToReload = [NSMutableDictionary dictionary];
    }
    ++_isBatchUpdating;
}

- (void)endUpdates
{
    if (!_isBatchUpdating)
        [NSException raise:NSInternalInconsistencyException format:@"endUpdates without corresponding beginUpdates"];
    --_isBatchUpdating;
    NSUInteger offset = 0;
    NSMutableArray *cellsToInsert = [NSMutableArray arrayWithCapacity:[_itemsToInsert count]];
    NSMutableArray *cellsToDelete = [NSMutableArray arrayWithCapacity:[_itemsToDelete count]];
    NSMutableArray *cellsToLoad = [NSMutableArray arrayWithCapacity:[_itemsToReload count]];
    NSMutableArray *cellsToUnload = [NSMutableArray arrayWithCapacity:[_itemsToReload count]];
    for (NSUInteger index = 0; index < _numberOfItems; ++index)
    {
        UIView *cell;
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
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewLongAnimationDuration animations:^(void) {
//    [UIView animateWithDuration:ECItemViewShortAnimationDuration animations:^(void) {
        for (UIView *cell in cellsToInsert) {
            cell.bounds = UIEdgeInsetsInsetRect(_itemBounds, _itemInsets);
            cell.alpha = 1.0;
        }
        for (UIView *cell in cellsToDelete) {
            cell.bounds = CGRectZero;
            cell.alpha = 0.0;
        }
        for (UIView *cell in cellsToLoad) {
            cell.alpha = 1.0;
        }
        for (UIView *cell in cellsToUnload ) {
            cell.alpha = 0.0;
        }
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        for (UIView *cell in cellsToDelete)
        {
            [cell removeFromSuperview];
        }
        for (UIView *cell in cellsToUnload)
        {
            [cell removeFromSuperview];
        }
    }];
    if (!_isBatchUpdating)
    {
        [_itemsToInsert release];
        [_itemsToDelete release];
        [_itemsToReload release];
    }
}*/

#pragma mark -
#pragma mark UIGestureRecognizer

- (void)_handleTap:(UITapGestureRecognizer *)tapRecognizer
{
    if (_isEditing)
        return;
    NSUInteger itemIndex = [self itemAtPoint:[tapRecognizer locationInView:self]];
    if (itemIndex == ECItemViewItemNotFound)
        return;
    if (_delegateDidSelectItem)
        [_delegate itemView:self didSelectItem:itemIndex];
}

- (void)_beginDrag:(UIPanGestureRecognizer *) dragRecognizer
{
    _isDragging = YES;
    _draggedItemIndex = [self itemAtPoint:[dragRecognizer locationInView:self]];
    _draggedItemContainer = [[ECItemViewDragContainer alloc] initWithView:[_items objectAtIndex:_draggedItemIndex]];
    _currentDragDestination = _draggedItemIndex;
    [_viewToDragIn addSubview:_draggedItemContainer];
    _draggedItemContainer.center = [dragRecognizer locationInView:_viewToDragIn];
}

- (void)_continueDrag:(UIPanGestureRecognizer *) dragRecognizer
{
    _draggedItemContainer.center = [dragRecognizer locationInView:_viewToDragIn];
    NSUInteger dragDestination = [self _indexOfDropAtPoint:[dragRecognizer locationInView:self]];
    if (dragDestination == _currentDragDestination)
        return;
    _currentDragDestination = dragDestination;
    [self setNeedsLayout];
}

- (BOOL)_endDrag:(UIPanGestureRecognizer *)dragRecognizer
{
    ECItemView *targetView = [self _targetForDrop:dragRecognizer];
    NSUInteger dragDestination = [targetView _indexOfDropAtPoint:[dragRecognizer locationInView:targetView]];
    if (dragDestination == ECItemViewItemNotFound)
    {
        return NO;
    }
    if (![_delegate itemView:self canDropItem:_draggedItemIndex inTargetItemView:targetView])
    {
        return NO;
    }
    [_items removeObjectAtIndex:_draggedItemIndex];
    [targetView _receiveDroppedItemContainer:_draggedItemContainer forItem:dragDestination];
    if (_delegateDidDropItem)
        [_delegate itemView:self didDropItem:_draggedItemIndex inTargetItemView:targetView atIndex:dragDestination];
    _draggedItemIndex = ECItemViewItemNotFound;
    _isDragging = NO;
    [_draggedItemContainer release];
    _draggedItemContainer = nil;
    [self setNeedsLayout];
    return YES;
}

- (void)_cancelDrag:(UIPanGestureRecognizer *)dragRecognizer
{
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:^(void) {
        _draggedItemContainer.center = [self convertPoint:[self _centerForItem:_draggedItemIndex] toView:_viewToDragIn];
    } completion:^(BOOL finished) {
        [self addSubview:_draggedItemContainer.view];
        _draggedItemContainer.view.center = [self _centerForItem:_draggedItemIndex];
        _draggedItemIndex = ECItemViewItemNotFound;
        _isDragging = NO;
        [_draggedItemContainer release];
        _draggedItemContainer = nil;
        _currentDragDestination = ECItemViewItemNotFound;
        [self setNeedsLayout];
    }];
}

- (ECItemView *)_targetForDrop:(UIPanGestureRecognizer *)dragRecognizer
{
    UIView *targetView = [_viewToDragIn hitTest:[dragRecognizer locationInView:_viewToDragIn] withEvent:nil];
    if (![targetView isDescendantOfView:_viewToDragIn])
        return self;
    while ([targetView class] != [self class])
    {
        if (targetView != _viewToDragIn)
        {
            targetView = [targetView superview];
            continue;
        }
        return self;
    }
    return (ECItemView *)targetView;
}

- (NSUInteger)_indexOfDropAtPoint:(CGPoint)point
{
    if (!CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, _viewInsets), point))
        return ECItemViewItemNotFound;
    NSUInteger index = [self _itemAtPoint:point includingPadding:YES];
    if (index == ECItemViewItemNotFound)
        if (_isDragging)
            return [_items count] - 1;
        else
            return [_items count];
    return index;
}

- (void)_receiveDroppedItemContainer:(ECItemViewDragContainer *)itemContainer forItem:(NSUInteger)item
{
    if (item == ECItemViewItemNotFound)
        return;
    [itemContainer retain];
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:^(void) {
        itemContainer.center = [self convertPoint:[self _centerForItem:item] toView:[itemContainer superview]];
    } completion:^(BOOL finished) {
        [_items insertObject:itemContainer.view atIndex:item];
        [self addSubview:itemContainer.view];
        itemContainer.view.center = [self _centerForItem:item];
        [itemContainer release];
        _currentDragDestination = ECItemViewItemNotFound;
        [self setNeedsLayout];
    }];
}

- (void)_handleDrag:(UIPanGestureRecognizer *)dragRecognizer
{
    if ([dragRecognizer state] == UIGestureRecognizerStateBegan)
        [self _beginDrag:dragRecognizer];
    else if ([dragRecognizer state] == UIGestureRecognizerStateChanged)
    {
        ECItemView *targetView = [self _targetForDrop:dragRecognizer];
        if (targetView != _currentDragTarget)
        {
            _currentDragTarget->_currentDragDestination = ECItemViewItemNotFound;
            [_currentDragTarget setNeedsLayout];
            _currentDragTarget = targetView;
        }
        [targetView _continueDrag:dragRecognizer];
        [self _continueDrag:dragRecognizer];
    }
    else if ([dragRecognizer state] == UIGestureRecognizerStateEnded)
        if (![self _endDrag:dragRecognizer])
            [self _cancelDrag:dragRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([self itemAtPoint:[touch locationInView:self]] != ECItemViewItemNotFound)
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
    NSUInteger item = [self itemAtPoint:[_dragRecognizer locationInView:self]];
    if (item == ECItemViewItemNotFound)
        return NO;
    BOOL shouldBegin = [_delegate itemView:self shouldDragItem:item inView:&_viewToDragIn];
    if (shouldBegin)
        if (![self isDescendantOfView:_viewToDragIn])
            _viewToDragIn = self;
    return shouldBegin;
}

@end
