//
//  ECItemView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECItemView.h"
#import <ECUIKit/UIView+ConcurrentAnimation.h>
#import <ECFoundation/ECStackCache.h>
#import <ECFoundation/NSIndexPath+FixedIsEqual.h>

static const CGFloat kECItemViewShortAnimationDuration = 0.15;
static const NSUInteger kECItemViewAreaHeaderBufferSize = 5;
static const NSUInteger kECItemViewGroupSeparatorBufferSize = 20;
static const NSUInteger kECItemViewItemBufferSize = 10;
static const NSString *kECItemViewAreaKey = @"area";
static const NSString *kECItemViewAreaHeaderKey = @"areaHeader";
static const NSString *kECItemViewGroupKey = @"group";
static const NSString *kECItemViewGroupSeparatorKey = @"groupSeparator";
static const NSString *kECItemViewItemKey = @"item";

@interface UIScrollView (MethodsInUIGestureRecognizerDelegateProtocolAppleCouldntBotherDeclaring)
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
@end

@interface ECItemView ()
{
    @private
    struct {
        unsigned int superGestureRecognizerShouldBegin:1;
        unsigned int superGestureRecognizerShouldRecognizeSimultaneously:1;
        unsigned int superGestureRecognizerShouldReceiveTouch:1;
        unsigned int dataSourceNumberOfAreasInItemView:1;
        unsigned int dataSourceNumberOfGroupsForArea:1;
        unsigned int dataSourceNumberOfItemsInGroup:1;
        unsigned int dataSourceViewForItem:1;
        unsigned int dataSourceViewForAreaHeader:1;
        unsigned int dataSourceViewForGroupSeparator:1;
        unsigned int dataSourceCanEditItem:1;
        unsigned int dataSourceCanDeleteItem:1;
        unsigned int dataSourceDeleteItem:1;
        unsigned int dataSourceCanMoveItem:1;
        unsigned int dataSourceMoveItem:1;
        unsigned int dataSourceInsertGroup:1;
        unsigned int dataSourceDeleteGroup:1;
        unsigned int dataSourceMoveGroup:1;
        unsigned int dataSourceMoveArea:1;
        unsigned int delegateWillSelectItem:1;
        unsigned int delegateWillDeselectItem:1;
        unsigned int delegateDidSelectItem:1;
        unsigned int delegateDidDeselectItem:1;
    } _flags;
    NSMutableArray *_areas;
    NSMutableDictionary *_elementCaches;
    NSMutableDictionary *_visibleElements;
    BOOL _isAnimating;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    BOOL _isDragging;
    UIView *_draggedItem;
    NSIndexPath *_draggedItemIndexPath;
    NSIndexPath *_dragDestinationIndexPath;
    BOOL _dragDestinationExists;
    NSTimer *_scrollTimer;
    CGFloat _scrollSpeed;
    UIEdgeInsets _scrollingHotspots;
    NSUInteger _isBatchUpdating;
}

- (void)_setup;

- (void)_enumerateVisibleElementsWithBlock:(void(^)(UIView<ECItemViewElement> *element))block;

- (UIView<ECItemViewElement> *)_loadAreaHeaderForIndex:(NSUInteger)index;
- (UIView<ECItemViewElement> *)_loadGroupSeparatorForIndexPath:(NSIndexPath *)indexPath;
- (UIView<ECItemViewElement> *)_loadItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)_heightForGroupAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)_proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists;

- (void)_layoutAreaHeaders;
- (void)_layoutGroupSeparators;
- (void)_layoutItems;

- (void)_handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)_handleLongPressGesture:(UILongPressGestureRecognizer *)longPressGestureRecognizer;
- (void)_beginDrag:(UILongPressGestureRecognizer *)dragRecognizer;
- (void)_continueDrag:(UILongPressGestureRecognizer *)dragRecognizer;
- (void)_endDrag:(UILongPressGestureRecognizer *)dragRecognizer;
- (void)_cancelDrag:(UILongPressGestureRecognizer *)dragRecognizer;
- (void)_handleTimer:(NSTimer *)timer;
@end

#pragma mark -

@implementation ECItemView

#pragma mark Properties and initialization

@synthesize delegate = __delegate;
@synthesize dataSource = _dataSource;
@synthesize itemHeight = _itemHeight;
@synthesize itemsPerRow = _itemsPerRow;
@synthesize itemInsets = _itemInsets;
@synthesize groupInsets = _groupInsets;
@synthesize groupSeparatorHeight = _groupSeparatorHeight;
@synthesize groupSeparatorInsets = _groupSeparatorInsets;
@synthesize areaHeaderHeight = _areaHeaderHeight;
@synthesize areaHeaderInsets = _areaHeaderInsets;
@synthesize allowsSelection = _allowsSelection;
@synthesize editing = _isEditing;

- (void)setDelegate:(id<ECItemViewDelegate>)delegate
{
    if (delegate == __delegate)
        return;
    [self willChangeValueForKey:@"delegate"];
    __delegate = delegate;
    _flags.delegateWillSelectItem = [delegate respondsToSelector:@selector(itemView:willSelectItemAtIndexPath:)];
    _flags.delegateWillDeselectItem = [delegate respondsToSelector:@selector(itemView:willDeselectItemAtIndexPath:)];
    _flags.delegateDidSelectItem = [delegate respondsToSelector:@selector(itemView:didSelectItemAtIndexPath:)];
    _flags.delegateDidDeselectItem = [delegate respondsToSelector:@selector(itemView:didDeselectItemAtIndexPath:)];
    [self didChangeValueForKey:@"delegate"];
}

- (void)setDataSource:(id<ECItemViewDataSource>)dataSource
{
    if (dataSource == _dataSource)
        return;
    [self willChangeValueForKey:@"dataSource"];
    _dataSource = dataSource;
    _flags.dataSourceNumberOfAreasInItemView = [dataSource respondsToSelector:@selector(numberOfAreasInItemView:)];
    _flags.dataSourceNumberOfGroupsForArea = [dataSource respondsToSelector:@selector(itemView:numberOfGroupsForAreaAtIndex:)];
    _flags.dataSourceNumberOfItemsInGroup = [dataSource respondsToSelector:@selector(itemView:numberOfItemsInGroupAtIndexPath:)];
    _flags.dataSourceViewForItem = [dataSource respondsToSelector:@selector(itemView:viewForItemAtIndexPath:)];
    _flags.dataSourceViewForAreaHeader = [dataSource respondsToSelector:@selector(itemView:viewForAreaHeaderAtIndex:)];
    _flags.dataSourceViewForGroupSeparator = [dataSource respondsToSelector:@selector(itemView:viewForGroupSeparatorAtIndexPath:)];
    _flags.dataSourceCanEditItem = [dataSource respondsToSelector:@selector(itemView:canEditItemAtIndexPath:)];
    _flags.dataSourceCanDeleteItem = [dataSource respondsToSelector:@selector(itemView:canDeleteItemAtIndexPath:)];
    _flags.dataSourceDeleteItem = [dataSource respondsToSelector:@selector(itemView:deleteItemAtIndexPath:)];
    _flags.dataSourceCanMoveItem = [dataSource respondsToSelector:@selector(itemView:canMoveItemAtIndexPath:)];
    _flags.dataSourceMoveItem = [dataSource respondsToSelector:@selector(itemView:moveItemAtIndexPath:toIndexPath:)];
    _flags.dataSourceInsertGroup = [dataSource respondsToSelector:@selector(itemView:insertGroupAtIndexPath:)];
    _flags.dataSourceDeleteGroup = [dataSource respondsToSelector:@selector(itemView:deleteGroupAtIndexPath:)];
    _flags.dataSourceMoveGroup = [dataSource respondsToSelector:@selector(itemView:moveGroupAtIndexPath:toIndexPath:)];
    _flags.dataSourceMoveArea = [dataSource respondsToSelector:@selector(itemView:moveAreaAtIndex:toIndex:)];
    [self didChangeValueForKey:@"dataSource"];
}

- (BOOL)isEditing
{
    return _isEditing;
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (editing == _isEditing)
        return;
    [self willChangeValueForKey:@"editing"];
    [self setNeedsLayout];
    _isEditing = editing;
    [self _enumerateVisibleElementsWithBlock:^(UIView<ECItemViewElement> *element) {
        [element setEditing:editing animated:animated];
    }];
    [self didChangeValueForKey:@"editing"];   
}

- (void)_setup
{
    _itemHeight = 100.0;
    _itemsPerRow = 4;
    _itemInsets = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
    _groupInsets = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
    _groupSeparatorHeight = 30.0;
    _groupSeparatorInsets = UIEdgeInsetsZero;
    _areaHeaderHeight = 60.0;
    _areaHeaderInsets = UIEdgeInsetsMake(20.0, 10.0, 20.0, 10.0);
    _allowsSelection = YES;
    _areas = [[NSMutableArray alloc] init];
    _elementCaches = [[NSMutableDictionary alloc] init];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewAreaHeaderBufferSize] forKey:kECItemViewAreaHeaderKey];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewGroupSeparatorBufferSize] forKey:kECItemViewGroupSeparatorKey];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewItemBufferSize] forKey:kECItemViewItemKey];
    _visibleElements = [[NSMutableDictionary alloc] init];
    [_visibleElements setObject:[NSMutableDictionary dictionary] forKey:kECItemViewAreaHeaderKey];
    [_visibleElements setObject:[NSMutableDictionary dictionary] forKey:kECItemViewGroupSeparatorKey];
    [_visibleElements setObject:[NSMutableDictionary dictionary] forKey:kECItemViewItemKey];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapGesture:)];
    _tapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_tapGestureRecognizer];
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleLongPressGesture:)];
    _longPressGestureRecognizer.minimumPressDuration = 0.5;
    _longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longPressGestureRecognizer];
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    _flags.superGestureRecognizerShouldBegin = [scrollView respondsToSelector:@selector(gestureRecognizerShouldBegin:)];
    _flags.superGestureRecognizerShouldRecognizeSimultaneously = [scrollView respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)];
    _flags.superGestureRecognizerShouldReceiveTouch = [scrollView respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)];
    [scrollView release];
    _scrollSpeed = 30.0;
    _scrollingHotspots = UIEdgeInsetsMake(100.0, 0.0, 100.0, 0.0);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    self.userInteractionEnabled = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self _setup];
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self)
        return nil;
    [self _setup];
    return self;
}

- (void)dealloc
{
    [_areas release];
    [_elementCaches release];
    [_visibleElements release];
    [_tapGestureRecognizer release];
    [_longPressGestureRecognizer release];
    [_draggedItem release];
    [_draggedItemIndexPath release];
    [_dragDestinationIndexPath release];
    [_scrollTimer invalidate];
    [super dealloc];
}

#pragma mark -
#pragma mark Data

- (void)reloadData
{
    [self _enumerateVisibleElementsWithBlock:^(UIView<ECItemViewElement> *element) {
        [element removeFromSuperview];
    }];
    [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] removeAllObjects];
    [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] removeAllObjects];
    [[_visibleElements objectForKey:kECItemViewItemKey] removeAllObjects];
    [self beginUpdates];
    [self endUpdates];
    [self setNeedsLayout];
}

- (void)_enumerateVisibleElementsWithBlock:(void (^)(UIView<ECItemViewElement> *))block
{
    for (NSDictionary *visibleElements in [_visibleElements allValues])
        for (UIView<ECItemViewElement> *element in [visibleElements allValues])
            block(element);
}

- (UIView<ECItemViewElement> *)_loadAreaHeaderForIndex:(NSUInteger)index
{
    if (index >= [_areas count] || !_flags.dataSourceViewForAreaHeader)
        return nil;
    UIView *areaHeader = [_dataSource itemView:self viewForAreaHeaderAtIndex:index];
    return areaHeader;
}

- (UIView<ECItemViewElement> *)_loadGroupSeparatorForIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForGroupSeparator)
        return nil;
    UIView *groupSeparator = [_dataSource itemView:self viewForGroupSeparatorAtIndexPath:indexPath];
    return groupSeparator;
}

- (UIView<ECItemViewElement> *)_loadItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForItem)
        return nil;
    UIView *item = [_dataSource itemView:self viewForItemAtIndexPath:indexPath];
    return item;
}

#pragma mark -
#pragma mark Info

- (NSUInteger)rowsInGroupAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger numCells = [self numberOfItemsInGroupAtIndexPath:indexPath];
    return ceil((CGFloat)numCells / self.itemsPerRow);
}

- (NSUInteger)numberOfAreas
{
    return [_areas count];
}

- (NSUInteger)numberOfGroupsInArea:(NSUInteger)area
{
    return [[_areas objectAtIndex:area] count];
}

- (NSUInteger)numberOfItemsInGroupAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[_areas objectAtIndex:indexPath.area] objectAtIndex:indexPath.group] unsignedIntegerValue];
}

#pragma mark -
#pragma mark Geometry

- (CGRect)rectForArea:(NSUInteger)area
{
    CGFloat x = 0;
    CGFloat y = 0;
    if (area)
    {
        CGRect previousAreaRect = [self rectForArea:area - 1];
        y = previousAreaRect.origin.y + previousAreaRect.size.height;
    }
    CGFloat width = self.bounds.size.width;
    CGFloat height = _areaHeaderHeight;
    NSUInteger numGroups = [self numberOfGroupsInArea:area];
    for (NSUInteger j = 0; j < numGroups; ++j)
        height += [self _heightForGroupAtIndexPath:[NSIndexPath indexPathForPosition:j inArea:area]];
    return CGRectMake(x, y, width, height);
}

- (CGFloat)_heightForGroupAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0;
    height += [self rowsInGroupAtIndexPath:indexPath] * _itemHeight;
    height += _groupInsets.top + _groupInsets.bottom;
    height += _groupSeparatorHeight;
    return height;
}

- (CGRect)rectForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect groupRect = [self rectForGroupAtIndexPath:indexPath];
    CGFloat x = groupRect.origin.x + _groupInsets.left;
    CGFloat y = groupRect.origin.y + groupRect.size.height - _groupInsets.bottom;
    CGFloat width = groupRect.size.width - _groupInsets.left - _groupInsets.right;
    CGFloat height;
    y -= _groupSeparatorHeight;
    height = _groupSeparatorHeight;
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForHeaderInArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    return CGRectMake(areaRect.origin.x, areaRect.origin.y, self.bounds.size.width - _areaHeaderInsets.left - _areaHeaderInsets.right, _areaHeaderHeight);
}

- (CGRect)rectForGroupAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect areaRect = [self rectForArea:indexPath.area];
    CGFloat x = areaRect.origin.x;
    CGFloat y = areaRect.origin.y + _areaHeaderHeight;
    for (NSUInteger i = 0; i < indexPath.group; ++i)
        y += [self _heightForGroupAtIndexPath:indexPath];
    CGFloat width = areaRect.size.width;
    CGFloat height = [self _heightForGroupAtIndexPath:indexPath];
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath)
        return CGRectZero;
    CGFloat x = 0;
    CGFloat y = 0;
    CGRect groupRect = [self rectForGroupAtIndexPath:indexPath];
    x = groupRect.origin.x;
    y = groupRect.origin.y;
    NSUInteger row = indexPath.item / _itemsPerRow;
    NSUInteger column = indexPath.item % _itemsPerRow;
    CGFloat itemWidth = groupRect.size.width - _groupInsets.left - _groupInsets.right / (CGFloat)_itemsPerRow;
    x += column * itemWidth;
    y += row * _itemHeight;
    return CGRectMake(x, y, itemWidth, _itemHeight);
}

#pragma mark -
#pragma mark Index paths

- (NSIndexSet *)indexesForVisibleAreas
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfAreas])];
    return [indexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return CGRectIntersectsRect(self.bounds, [self rectForArea:idx]);
    }];
}

- (NSIndexSet *)indexesForVisibleAreaHeaders
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfAreas])];
    return [indexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return CGRectIntersectsRect(self.bounds, [self rectForHeaderInArea:idx]);
    }];
}

- (NSArray *)visibleAreaHeaders
{
    return [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] allValues];
}

- (UIView<ECItemViewElement> *)areaHeaderAtIndex:(NSUInteger)index
{
    return [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] objectForKey:[NSNumber numberWithUnsignedInteger:index]];
}

- (NSUInteger)indexForAreaHeaderAtPoint:(CGPoint)point
{
    for (NSNumber *index in [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] allKeys])
        if (CGRectContainsPoint([[[_visibleElements objectForKey:kECItemViewAreaHeaderKey] objectForKey:index] frame], point))
            return [index unsignedIntegerValue];
    return NSUIntegerMax;
}

- (NSArray *)indexPathsForVisibleGroups
{
    NSIndexSet *indexes = [self indexesForVisibleAreas];
    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSUInteger numGroups = [self numberOfGroupsInArea:idx];
        for (NSUInteger i = 0; i < numGroups; ++i)
            if (CGRectIntersectsRect(self.bounds, [self rectForGroupAtIndexPath:[NSIndexPath indexPathForPosition:i inArea:idx]]))
                [indexPaths addObject:[NSIndexPath indexPathForPosition:i inArea:idx]];
    }];
    return indexPaths;
}

- (NSArray *)indexPathsForVisibleGroupSeparators
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSIndexPath *indexPath in [self indexPathsForVisibleGroups])
        if (CGRectIntersectsRect(self.bounds, [self rectForGroupSeparatorAtIndexPath:indexPath]))
            [indexPaths addObject:indexPath];
    return indexPaths;
}

- (NSArray *)visibleGroupSeparators
{
    return [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] allValues];
}

- (UIView<ECItemViewElement> *)groupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    return [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] objectForKey:indexPath];
}

- (NSIndexPath *)indexPathForGroupSeparatorAtPoint:(CGPoint)point
{
    for (NSIndexPath *indexPath in [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] allKeys])
        if (CGRectContainsPoint([[[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] objectForKey:indexPath] frame], point))
            return indexPath;
    return nil;
}

- (NSArray *)indexPathsForVisibleItems
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSIndexPath *groupIndexPath in [self indexPathsForVisibleGroups])
    {
        NSUInteger numItems = [self numberOfItemsInGroupAtIndexPath:groupIndexPath];
        for (NSUInteger k = 0; k < numItems; ++k)
        {
            CGRect itemRect = [self rectForItemAtIndexPath:[NSIndexPath indexPathForItem:k inGroup:groupIndexPath.position inArea:groupIndexPath.area]];
            if (!CGRectIntersectsRect(self.bounds, itemRect))
                continue;
            [indexPaths addObject:[NSIndexPath indexPathForItem:k inGroup:groupIndexPath.position inArea:groupIndexPath.area]];
        }
    }
    return indexPaths;
}

- (NSArray *)visibleItems
{
    return [[_visibleElements objectForKey:kECItemViewItemKey] allValues];
}

- (UIView<ECItemViewElement> *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return [[_visibleElements objectForKey:kECItemViewItemKey] objectForKey:indexPath];
}

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
    for (NSIndexPath *indexPath in [[_visibleElements objectForKey:kECItemViewItemKey] allKeys])
        if (CGRectContainsPoint([[[_visibleElements objectForKey:kECItemViewItemKey] objectForKey:indexPath] frame], point))
            return indexPath;
    return nil;
}

- (NSIndexPath *)_proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists
{
    if (exists)
        *exists = NO;
    NSUInteger areaHeader = [self indexForAreaHeaderAtPoint:point];
    if (areaHeader != NSUIntegerMax)
        return [NSIndexPath indexPathForItem:0 inGroup:0 inArea:areaHeader];
    NSIndexPath *indexPath = [self indexPathForGroupSeparatorAtPoint:point];
    if (indexPath)
        return [NSIndexPath indexPathForItem:0 inGroup:indexPath.position + 1 inArea:indexPath.position];
    indexPath = [self indexPathForItemAtPoint:point];
    if (indexPath)
    {
        if (exists)
            *exists = YES;
        return indexPath;
    }
    for (NSIndexPath *groupIndexPath in [self indexPathsForVisibleGroups])
        if (CGRectContainsPoint(UIEdgeInsetsInsetRect([self rectForGroupAtIndexPath:groupIndexPath], _groupInsets), point))
            if (groupIndexPath.area == _draggedItemIndexPath.area && groupIndexPath.position == _draggedItemIndexPath.group)
            {
                if (exists)
                    *exists = YES;
                return [NSIndexPath indexPathForItem:[self numberOfItemsInGroupAtIndexPath:groupIndexPath] - 1 inGroup:groupIndexPath.position inArea:groupIndexPath.area];
            }
            else
                return [NSIndexPath indexPathForItem:[self numberOfItemsInGroupAtIndexPath:groupIndexPath] inGroup:groupIndexPath.position inArea:groupIndexPath.area];
    return nil;
}

#pragma mark -
#pragma mark Item insertion/deletion/reloading

- (void)beginUpdates
{
    if (!_isBatchUpdating)
    {
//        _batchUpdatingStores = [[NSMutableArray alloc] init];
    }
//    [_batchUpdatingStores addObject:[ECItemViewBatchUpdatingStore store]];
    ++_isBatchUpdating;
}

- (void)endUpdates
{
    if (!_isBatchUpdating)
        [NSException raise:NSInternalInconsistencyException format:@"endUpdates without corresponding beginUpdates"];
    --_isBatchUpdating;
    NSUInteger numAreas = 1;
    if (_flags.dataSourceNumberOfAreasInItemView)
        numAreas = [_dataSource numberOfAreasInItemView:self];
    [_areas release];
    _areas = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        NSUInteger numGroups = 0;
        if (_flags.dataSourceNumberOfGroupsForArea)
            numGroups = [_dataSource itemView:self numberOfGroupsForAreaAtIndex:i];
        NSMutableArray *groups = [NSMutableArray arrayWithCapacity:numGroups];
        for (NSUInteger j = 0; j < numGroups; ++j)
        {
            NSUInteger numItems = 0;
            if (_flags.dataSourceNumberOfItemsInGroup)
                numItems = [_dataSource itemView:self numberOfItemsInGroupAtIndexPath:[NSIndexPath indexPathForPosition:j inArea:i]];
            [groups addObject:[NSNumber numberWithUnsignedInteger:numItems]];
        }
        [_areas addObject:groups];
    }
    if (!_isBatchUpdating)
    {
//        [_batchUpdatingStores release];
//        _batchUpdatingStores = nil;
    }
    //    [_batchUpdatingStores removeLastObject];
    if (!numAreas)
        self.contentSize = CGSizeMake(0.0, 0.0);
    CGRect lastAreaFrame = [self rectForArea:numAreas - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self setNeedsLayout];
}

#pragma mark -
#pragma mark Recycling

- (UIView<ECItemViewElement> *)dequeueReusableAreaHeader
{
    if (![[_elementCaches objectForKey:kECItemViewAreaHeaderKey] count])
        return nil;
    return [[_elementCaches objectForKey:kECItemViewAreaHeaderKey] pop];
}

- (UIView<ECItemViewElement> *)dequeueReusableGroupSeparator
{
    if (![[_elementCaches objectForKey:kECItemViewGroupSeparatorKey] count])
        return nil;
    return [[_elementCaches objectForKey:kECItemViewGroupSeparatorKey] pop];
}

- (UIView<ECItemViewElement> *)dequeueReusableItem
{
    if (![[_elementCaches objectForKey:kECItemViewItemKey] count])
        return nil;
    return [[_elementCaches objectForKey:kECItemViewItemKey] pop];
}

#pragma mark -
#pragma mark UIView

- (void)_layoutAreaHeaders
{
    NSMutableDictionary *newVisibleAreaHeaders = [NSMutableDictionary dictionary];
    [[self indexesForVisibleAreaHeaders] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        UIView *header = [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] objectForKey:[NSNumber numberWithUnsignedInteger:idx]];
        if (header)
            [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] removeObjectForKey:[NSNumber numberWithUnsignedInteger:idx]];
        else
        {
            header = [self _loadAreaHeaderForIndex:idx];
            if (!header)
                return;
            [self addSubview:header];
            [self sendSubviewToBack:header];
        }
        header.frame = UIEdgeInsetsInsetRect([self rectForHeaderInArea:idx], _areaHeaderInsets);
        [newVisibleAreaHeaders setObject:header forKey:[NSNumber numberWithUnsignedInteger:idx]];
    }];
    for (UILabel *header in [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] allValues])
    {
        [header removeFromSuperview];
        [[_elementCaches objectForKey:kECItemViewAreaHeaderKey] push:header];
    }
    [_visibleElements setObject:newVisibleAreaHeaders forKey:kECItemViewAreaHeaderKey];
}

- (void)_layoutGroupSeparators
{
    NSMutableDictionary *newVisibleGroupSeparators = [NSMutableDictionary dictionary];
    for (NSIndexPath *indexPath in [self indexPathsForVisibleGroupSeparators])
    {
        UIView *separator = [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] objectForKey:indexPath];
        if (separator)
            [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] removeObjectForKey:indexPath];
        else
        {
            separator = [self _loadGroupSeparatorForIndexPath:indexPath];
            if (!separator)
                continue;
            [self addSubview:separator];
            [self sendSubviewToBack:separator];
        }
        separator.frame = UIEdgeInsetsInsetRect([self rectForGroupSeparatorAtIndexPath:indexPath], _groupSeparatorInsets);
        [newVisibleGroupSeparators setObject:separator forKey:indexPath];
    }
    for (UIView *separator in [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] allValues])
    {
        [separator removeFromSuperview];
        [[_elementCaches objectForKey:kECItemViewGroupSeparatorKey] push:separator];
    }
    [_visibleElements setObject:newVisibleGroupSeparators forKey:kECItemViewGroupSeparatorKey];
}

- (void)_layoutCells
{
    NSMutableDictionary *newVisibleItems = [NSMutableDictionary dictionary];
    for (NSIndexPath *indexPath in [self indexPathsForVisibleItems])
    {
        UIView *item = [[_visibleElements objectForKey:kECItemViewItemKey] objectForKey:indexPath];
        if (item)
            [[_visibleElements objectForKey:kECItemViewItemKey] removeObjectForKey:indexPath];
        else
        {
            item = [self _loadItemAtIndexPath:indexPath];
            if (!item)
                continue;
            [self addSubview:item];
            [self sendSubviewToBack:item];
        }
        item.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:indexPath], _itemInsets);
        [newVisibleItems setObject:item forKey:indexPath];
    }
    for (UIView *cell in [[_visibleElements objectForKey:kECItemViewItemKey] allValues])
    {
        [cell removeFromSuperview];
        [[_elementCaches objectForKey:kECItemViewItemKey] push:cell];
    }
    [_visibleElements setObject:newVisibleItems forKey:kECItemViewItemKey];
}

- (void)layoutSubviews
{
    [self _layoutAreaHeaders];
    [self _layoutGroupSeparators];
    [self _layoutCells];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == _tapGestureRecognizer)
        if (!_isEditing && [self indexPathForItemAtPoint:[touch locationInView:self]])
            return YES;
        else
            return NO;
    if (gestureRecognizer == _longPressGestureRecognizer)
        if (_isEditing && [self indexPathForItemAtPoint:[touch locationInView:self]])
            return YES;
        else
        {
            return NO;
        }
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && !_isEditing && [self indexPathForItemAtPoint:[touch locationInView:self]])
        return NO;
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && _isEditing && [self indexPathForItemAtPoint:[touch locationInView:self]])
        return NO;
    if (_flags.superGestureRecognizerShouldReceiveTouch)
        return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == _longPressGestureRecognizer)
        if (_flags.dataSourceCanMoveItem && _flags.dataSourceMoveItem && [self indexPathForItemAtPoint:[gestureRecognizer locationInView:self]] && [_dataSource itemView:self canMoveItemAtIndexPath:[self indexPathForItemAtPoint:[gestureRecognizer locationInView:self]]])
            return YES;
        else
            return NO;
    if (_flags.superGestureRecognizerShouldBegin)
        return [super gestureRecognizerShouldBegin:gestureRecognizer];
    return YES;
}

- (void)_handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (!_flags.delegateDidSelectItem)
        return;
    if (_isEditing)
        return;
    if (![tapGestureRecognizer state] == UIGestureRecognizerStateEnded)
        return;
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:[tapGestureRecognizer locationInView:self]];
    [__delegate itemView:self didSelectItemAtIndexPath:indexPath];
}

- (void)_handleLongPressGesture:(UILongPressGestureRecognizer *)longPressGestureRecognizer
{
    if ([longPressGestureRecognizer state] == UIGestureRecognizerStateBegan)
        [self _beginDrag:longPressGestureRecognizer];
    else if ([longPressGestureRecognizer state] == UIGestureRecognizerStateChanged)
        [self _continueDrag:longPressGestureRecognizer];
    else if ([longPressGestureRecognizer state] == UIGestureRecognizerStateEnded)
        [self _endDrag:longPressGestureRecognizer];
    else if ([longPressGestureRecognizer state] == UIGestureRecognizerStateCancelled)
        [self _cancelDrag:longPressGestureRecognizer];
}

- (void)_beginDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _isDragging = YES;
    _draggedItemIndexPath = [[self indexPathForItemAtPoint:[dragRecognizer locationInView:self]] retain];
    _dragDestinationIndexPath = [_draggedItemIndexPath retain];
    _draggedItem = [self itemAtIndexPath:_draggedItemIndexPath];
    _draggedItem.center = [dragRecognizer locationInView:self];
    [self bringSubviewToFront:_draggedItem];
}

- (void)_continueDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _draggedItem.center = [dragRecognizer locationInView:self];
    if (CGRectContainsPoint(self.bounds, _draggedItem.center) && !CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, _scrollingHotspots), _draggedItem.center))
    {
        if (!_scrollTimer)
        {
            _scrollTimer = [NSTimer timerWithTimeInterval:1.0/60.0 target:self selector:@selector(_handleTimer:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:_scrollTimer forMode:NSDefaultRunLoopMode];
        }
        return;
    }
    else if (_scrollTimer)
    {
        [_scrollTimer invalidate];
        _scrollTimer = nil;
    }
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:[dragRecognizer locationInView:self]];
    if ([indexPath isEqual:_draggedItemIndexPath])
        return;
    [_dragDestinationIndexPath release];
    _dragDestinationIndexPath = [indexPath retain];
    [self setNeedsLayout];
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:kECItemViewShortAnimationDuration animations:^(void) {
        [self layoutIfNeeded];
    } completion:NULL];
}

- (void)_endDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    BOOL proposedIndexPathExists;
    NSIndexPath *proposedIndexPath = [self _proposedIndexPathForItemAtPoint:[dragRecognizer locationInView:self] exists:&proposedIndexPathExists];
    if (!proposedIndexPath)
        [self _cancelDrag:dragRecognizer];
    if (!proposedIndexPathExists && !proposedIndexPath.item)
        if (_flags.dataSourceInsertGroup)
        {
            [_dataSource itemView:self insertGroupAtIndexPath:[NSIndexPath indexPathForPosition:proposedIndexPath.group inArea:proposedIndexPath.area]];
            if (_draggedItemIndexPath.area == proposedIndexPath.area && _draggedItemIndexPath.group >= proposedIndexPath.group)
            {
                NSIndexPath *adjustedDraggedItemIndexPath = [[NSIndexPath indexPathForItem:_draggedItemIndexPath.item inGroup:_draggedItemIndexPath.group + 1 inArea:_draggedItemIndexPath.area] retain];
                [_draggedItemIndexPath release];
                _draggedItemIndexPath = adjustedDraggedItemIndexPath;
            }
            
        }
        else
            [self _cancelDrag:dragRecognizer];
    
    _isDragging = NO;
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    [_dragDestinationIndexPath release];
    _dragDestinationIndexPath = proposedIndexPath;
    if (_flags.dataSourceMoveItem)
        [_dataSource itemView:self moveItemAtIndexPath:_draggedItemIndexPath toIndexPath:_dragDestinationIndexPath];
    if (_flags.dataSourceNumberOfItemsInGroup)
        if (![_dataSource itemView:self numberOfItemsInGroupAtIndexPath:_draggedItemIndexPath])
            if (_flags.dataSourceDeleteGroup)
                [_dataSource itemView:self deleteGroupAtIndexPath:[NSIndexPath indexPathForPosition:_draggedItemIndexPath.group inArea:_draggedItemIndexPath.area]];
    [self reloadData];
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:kECItemViewShortAnimationDuration animations:^(void) {
        _draggedItem.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:_dragDestinationIndexPath], _itemInsets);
    } completion:NULL];
    [_draggedItemIndexPath release];
    _draggedItemIndexPath = nil;
    _dragDestinationIndexPath = nil;
    _draggedItem = nil;
}

- (void)_cancelDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _isDragging = NO;
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    [self setNeedsLayout];
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:kECItemViewShortAnimationDuration animations:^(void) {
        _draggedItem.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:_draggedItemIndexPath], _itemInsets);
        [self layoutIfNeeded];
    } completion:NULL];
    [_draggedItemIndexPath release];
    _draggedItemIndexPath = nil;
    [_dragDestinationIndexPath release];
    _dragDestinationIndexPath = nil;
    _draggedItem = nil;
}

- (void)_handleTimer:(NSTimer *)timer
{
    CGPoint offset = [self contentOffset];
    CGPoint center = _draggedItem.center;
    if (_draggedItem.center.y < self.bounds.origin.y + _scrollingHotspots.top && self.bounds.origin.y > 0.0)
    {
        offset.y -= _scrollSpeed;
        center.y -= _scrollSpeed;
    }
    else if (_draggedItem.center.y > self.bounds.origin.y + self.bounds.size.height - _scrollingHotspots.bottom && self.bounds.origin.y < self.contentSize.height - self.bounds.size.height)
    {
        offset.y += _scrollSpeed;
        center.y += _scrollSpeed;
    }
    [self setContentOffset:offset animated:NO];
    _draggedItem.center = center;
 }

@end

#pragma mark -

@implementation NSIndexPath (ECItemView)

- (NSUInteger)area
{
    return [self indexAtPosition:0];
}

- (NSUInteger)group
{
    return [self indexAtPosition:1];
}

- (NSUInteger)item
{
    return [self indexAtPosition:2];
}

- (NSUInteger)position
{
    return [self indexAtPosition:1];
}

+ (NSIndexPath *)indexPathForItem:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [self indexPathWithIndexes:(NSUInteger[3]){area, group, item} length:3];
}

+ (NSIndexPath *)indexPathForPosition:(NSUInteger)position inArea:(NSUInteger)area
{
    return [self indexPathWithIndexes:(NSUInteger[2]){area, position} length:2];
}

@end
