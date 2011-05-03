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
#import "ECItemViewElement.h"

static const CGFloat kECItemViewShortAnimationDuration = 0.15;
static const NSUInteger kECItemViewAreaHeaderBufferSize = 5;
static const NSUInteger kECItemViewGroupSeparatorBufferSize = 20;
static const NSUInteger kECItemViewItemBufferSize = 10;
const NSString *kECItemViewAreaKey = @"area";
const NSString *kECItemViewAreaHeaderKey = @"areaHeader";
const NSString *kECItemViewGroupKey = @"group";
const NSString *kECItemViewGroupSeparatorKey = @"groupSeparator";
const NSString *kECItemViewItemKey = @"item";

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
        unsigned int dataSourceNumberOfGroupsInArea:1;
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
    NSUInteger _cachedAreaRectArea;
    CGRect _cachedAreaRectRect;
    NSUInteger _cachedGroupRectArea;
    NSUInteger _cachedGroupRectGroup;
    CGRect _cachedGroupRectRect;
    NSMutableDictionary *_visibleElements;
    BOOL _isAnimating;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    ECItemViewElementKey _selectedElementsType;
    NSMutableSet *_selectedElements;
    BOOL _isDragging;
    ECItemViewElement *_caret;
    NSTimer *_scrollTimer;
    CGFloat _scrollSpeed;
    UIEdgeInsets _scrollingHotspots;
    NSUInteger _isBatchUpdating;
}

- (void)_setup;

#pragma mark Data
- (void)_enumerateVisibleElementsWithBlock:(void(^)(ECItemViewElement *element))block;
- (ECItemViewElement *)_loadAreaHeaderAtIndexPath:(NSIndexPath *)indexPath;
- (ECItemViewElement *)_loadGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath;
- (ECItemViewElement *)_loadItemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Info
- (NSUInteger)_numberOfGroupsInAreaAtIndex:(NSUInteger)area;
- (NSUInteger)_numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area;
- (NSUInteger)_rowsInGroup:(NSUInteger)group inArea:(NSUInteger)area;

#pragma mark Geometry
- (CGRect)_rectForAreaAtIndex:(NSUInteger)area;
- (CGRect)_rectForAreaAtIndexPath:(NSIndexPath *)indexPath;
- (CGRect)_rectForAreaHeaderAtIndex:(NSUInteger)area;
- (CGFloat)_heightForGroupAtIndex:(NSUInteger)group inArea:(NSUInteger)area;
- (CGRect)_rectForGroupAtIndexPath:(NSIndexPath *)indexPath;
- (CGRect)_rectForGroupAtIndex:(NSUInteger)group inArea:(NSUInteger)area;
- (CGRect)_rectForGroupSeparatorAtIndex:(NSUInteger)group inArea:(NSUInteger)area;
- (CGRect)_rectForItemAtIndex:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area;

#pragma mark Index paths
- (NSIndexPath *)_indexPathForElementAtPoint:(CGPoint)point type:(ECItemViewElementKey *)elementType;

#pragma mark UIView
- (void)_layoutAreaHeaders;
- (void)_layoutGroupSeparators;
- (void)_layoutItems;

#pragma mark UIGestureRecognizer
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
@synthesize multipleSelection = _multipleSelection;
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
    _flags.dataSourceNumberOfGroupsInArea = [dataSource respondsToSelector:@selector(itemView:numberOfGroupsInAreaAtIndexPath:)];
    _flags.dataSourceNumberOfItemsInGroup = [dataSource respondsToSelector:@selector(itemView:numberOfItemsInGroupAtIndexPath:)];
    _flags.dataSourceViewForItem = [dataSource respondsToSelector:@selector(itemView:viewForItemAtIndexPath:)];
    _flags.dataSourceViewForAreaHeader = [dataSource respondsToSelector:@selector(itemView:viewForAreaHeaderAtIndexPath:)];
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
    [self _enumerateVisibleElementsWithBlock:^(ECItemViewElement *element) {
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
    _multipleSelection = YES;
    _areas = [[NSMutableArray alloc] init];
    _elementCaches = [[NSMutableDictionary alloc] init];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewAreaHeaderBufferSize] forKey:kECItemViewAreaHeaderKey];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewGroupSeparatorBufferSize] forKey:kECItemViewGroupSeparatorKey];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewItemBufferSize] forKey:kECItemViewItemKey];
    _cachedAreaRectArea = NSUIntegerMax;
    _cachedGroupRectArea = NSUIntegerMax;
    _cachedGroupRectGroup = NSUIntegerMax;
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
    _selectedElements = [[NSMutableSet alloc] init];
    _caret = [[ECItemViewElement alloc] init];
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
    [_selectedElements release];
    [_caret release];
    [_scrollTimer invalidate];
    [super dealloc];
}

#pragma mark -
#pragma mark Data

- (void)reloadData
{
    [self _enumerateVisibleElementsWithBlock:^(ECItemViewElement *element) {
        [element removeFromSuperview];
    }];
    [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] removeAllObjects];
    [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] removeAllObjects];
    [[_visibleElements objectForKey:kECItemViewItemKey] removeAllObjects];
    [self beginUpdates];
    [self endUpdates];
    [self setNeedsLayout];
}

- (void)_enumerateVisibleElementsWithBlock:(void (^)(ECItemViewElement *))block
{
    for (NSDictionary *visibleElements in [_visibleElements allValues])
        for (ECItemViewElement *element in [visibleElements allValues])
            block(element);
}

- (ECItemViewElement *)_loadAreaHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.area >= [_areas count] || !_flags.dataSourceViewForAreaHeader)
        return nil;
    ECItemViewElement *areaHeader = [_dataSource itemView:self viewForAreaHeaderAtIndexPath:indexPath];
    return areaHeader;
}

- (ECItemViewElement *)_loadGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForGroupSeparator)
        return nil;
    ECItemViewElement *groupSeparator = [_dataSource itemView:self viewForGroupSeparatorAtIndexPath:indexPath];
    return groupSeparator;
}

- (ECItemViewElement *)_loadItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForItem)
        return nil;
    ECItemViewElement *item = [_dataSource itemView:self viewForItemAtIndexPath:indexPath];
    return item;
}

#pragma mark -
#pragma mark Info

- (NSUInteger)numberOfAreas
{
    return [_areas count];
}

- (NSUInteger)_numberOfGroupsInAreaAtIndex:(NSUInteger)area
{
    return [[_areas objectAtIndex:area] count];
}

- (NSUInteger)numberOfGroupsInAreaAtIndexPath:(NSIndexPath *)indexPath
{
    return [[_areas objectAtIndex:indexPath.area] count];
}

- (NSUInteger)_numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [[[_areas objectAtIndex:area] objectAtIndex:group] unsignedIntegerValue];
}

- (NSUInteger)numberOfItemsInGroupAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[_areas objectAtIndex:indexPath.area] objectAtIndex:indexPath.group] unsignedIntegerValue];
}

- (NSUInteger)_rowsInGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    NSUInteger numCells = [self _numberOfItemsInGroup:group inArea:area];
    return ceil((CGFloat)numCells / self.itemsPerRow);
}

#pragma mark -
#pragma mark Geometry

- (CGRect)_rectForAreaAtIndex:(NSUInteger)area
{
    CGFloat x = 0;
    CGFloat y = 0;
    if (area == _cachedAreaRectArea)
        return _cachedAreaRectRect;
    if (area)
    {
        CGRect previousAreaRect = [self _rectForAreaAtIndex:area - 1];
        y = previousAreaRect.origin.y + previousAreaRect.size.height;
    }
    CGFloat width = self.bounds.size.width;
    CGFloat height = _areaHeaderHeight;
    NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:area];
    for (NSUInteger j = 0; j < numGroups; ++j)
        height += [self _heightForGroupAtIndex:j inArea:area];
    _cachedAreaRectArea = area;
    _cachedAreaRectRect = CGRectMake(x, y, width, height);
    return _cachedAreaRectRect;
}

- (CGRect)_rectForAreaAtIndexPath:(NSIndexPath *)indexPath
{
    return [self _rectForAreaAtIndex:indexPath.area];
}

- (CGRect)_rectForAreaHeaderAtIndex:(NSUInteger)area
{
    CGRect areaRect = [self _rectForAreaAtIndex:area];
    return CGRectMake(areaRect.origin.x, areaRect.origin.y, self.bounds.size.width - _areaHeaderInsets.left - _areaHeaderInsets.right, _areaHeaderHeight);
}

- (CGRect)rectForAreaHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    return [self _rectForAreaHeaderAtIndex:indexPath.area];
}

- (CGFloat)_heightForGroupAtIndex:(NSUInteger)group inArea:(NSUInteger)area
{
    CGFloat height = 0;
    height += [self _rowsInGroup:group inArea:area] * _itemHeight;
    height += _groupInsets.top + _groupInsets.bottom;
    height += _groupSeparatorHeight;
    return height;
}

- (CGRect)_rectForGroupAtIndex:(NSUInteger)group inArea:(NSUInteger)area;
{
    if (area == _cachedGroupRectArea && group == _cachedGroupRectArea)
        return _cachedGroupRectRect;
    CGRect areaRect = [self _rectForAreaAtIndex:area];
    CGFloat x = areaRect.origin.x;
    CGFloat y = areaRect.origin.y + _areaHeaderHeight;
    for (NSUInteger i = 0; i < group; ++i)
        y += [self _heightForGroupAtIndex:group inArea:area];
    CGFloat width = areaRect.size.width;
    CGFloat height = [self _heightForGroupAtIndex:group inArea:area];
    _cachedGroupRectArea = area;
    _cachedGroupRectGroup = group;
    _cachedGroupRectRect = CGRectMake(x, y, width, height);
    return _cachedGroupRectRect;
}

- (CGRect)_rectForGroupAtIndexPath:(NSIndexPath *)indexPath
{
    return [self _rectForGroupAtIndex:indexPath.group inArea:indexPath.area];
}

- (CGRect)_rectForGroupSeparatorAtIndex:(NSUInteger)group inArea:(NSUInteger)area
{
    CGRect groupRect = [self _rectForGroupAtIndex:group inArea:area];
    CGFloat x = groupRect.origin.x + _groupInsets.left;
    CGFloat y = groupRect.origin.y + groupRect.size.height - _groupInsets.bottom;
    CGFloat width = groupRect.size.width - _groupInsets.left - _groupInsets.right;
    CGFloat height;
    y -= _groupSeparatorHeight;
    height = _groupSeparatorHeight;
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    return [self _rectForGroupSeparatorAtIndex:indexPath.group inArea:indexPath.area];
}

- (CGRect)_rectForItemAtIndex:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    CGFloat x = 0;
    CGFloat y = 0;
    CGRect groupRect = [self _rectForGroupAtIndex:group inArea:area];
    x = groupRect.origin.x;
    y = groupRect.origin.y;
    NSUInteger row = item / _itemsPerRow;
    NSUInteger column = item % _itemsPerRow;
    CGFloat itemWidth = (groupRect.size.width - _groupInsets.left - _groupInsets.right) / (CGFloat)_itemsPerRow;
    x += column * itemWidth;
    y += row * _itemHeight;
    return CGRectMake(x, y, itemWidth, _itemHeight);
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self _rectForItemAtIndex:indexPath.item inGroup:indexPath.group inArea:indexPath.area];
}

#pragma mark -
#pragma mark Index paths

- (NSArray *)indexPathsForVisibleAreas
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
        if (CGRectIntersectsRect(self.bounds, [self _rectForAreaAtIndex:i]))
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForArea:i];
            [indexPaths addObject:indexPath];
        }
    return indexPaths;
}

- (NSArray *)indexPathsForVisibleAreaHeaders
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
        if (CGRectIntersectsRect(self.bounds, [self _rectForAreaHeaderAtIndex:i]))
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForArea:i];
            [indexPaths addObject:indexPath];
        }
    return indexPaths;
}

- (NSArray *)visibleAreaHeaders
{
    return [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] allValues];
}

- (ECItemViewElement *)areaHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    return [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] objectForKey:indexPath];
}

- (NSIndexPath *)indexForAreaHeaderAtPoint:(CGPoint)point
{
    for (NSIndexPath *indexPath in [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] allKeys])
        if (CGRectContainsPoint([[[_visibleElements objectForKey:kECItemViewAreaHeaderKey] objectForKey:indexPath] frame], point))
            return indexPath;
    return nil;
}

- (NSArray *)indexPathsForVisibleGroups
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSIndexPath *areaIndexPath in [self indexPathsForVisibleAreas])
    {
        NSUInteger numGroups = [self numberOfGroupsInAreaAtIndexPath:areaIndexPath];
        for (NSUInteger i = 0; i < numGroups; ++i)
            if (CGRectIntersectsRect(self.bounds, [self _rectForGroupAtIndex:i inArea:areaIndexPath.area]))
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForPosition:i inArea:areaIndexPath.area];
                [indexPaths addObject:indexPath];
            }
    }
    return indexPaths;
}

- (NSArray *)indexPathsForVisibleGroupSeparators
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSIndexPath *areaIndexPath in [self indexPathsForVisibleAreas])
    {
        NSUInteger numGroups = [self numberOfGroupsInAreaAtIndexPath:areaIndexPath];
        for (NSUInteger i = 0; i < numGroups; ++i)
            if (CGRectIntersectsRect(self.bounds, [self _rectForGroupSeparatorAtIndex:i inArea:areaIndexPath.area]))
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForPosition:i inArea:areaIndexPath.area];
                [indexPaths addObject:indexPath];
            }
    }
    return indexPaths;
}

- (NSArray *)visibleGroupSeparators
{
    return [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] allValues];
}

- (ECItemViewElement *)groupSeparatorAtIndexPath:(NSIndexPath *)indexPath
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
            CGRect itemRect = [self _rectForItemAtIndex:k inGroup:groupIndexPath.group inArea:groupIndexPath.area];
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

- (ECItemViewElement *)itemAtIndexPath:(NSIndexPath *)indexPath
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

- (NSIndexPath *)_indexPathForElementAtPoint:(CGPoint)point type:(ECItemViewElementKey *)elementType
{
    NSIndexPath *indexPath;
    indexPath = [self indexForAreaHeaderAtPoint:point];
    if (indexPath)
    {
        if (elementType)
            *elementType = kECItemViewAreaHeaderKey;
        return indexPath;
    }
    indexPath = [self indexPathForGroupSeparatorAtPoint:point];
    if (indexPath)
    {
        if (elementType)
            *elementType = kECItemViewGroupSeparatorKey;
        return indexPath;
    }
    indexPath = [self indexPathForItemAtPoint:point];
    if (indexPath)
    {
        if (elementType)
            *elementType = kECItemViewItemKey;
        return indexPath;
    }
    for (NSIndexPath *groupIndexPath in [self indexPathsForVisibleGroups])
        if (CGRectContainsPoint(UIEdgeInsetsInsetRect([self _rectForGroupAtIndexPath:groupIndexPath], _groupInsets), point))
        {
            if (elementType)
                *elementType = kECItemViewGroupKey;
            return indexPath;
        }
    if (elementType)
        *elementType = nil;
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
        if (_flags.dataSourceNumberOfGroupsInArea)
            numGroups = [_dataSource itemView:self numberOfGroupsInAreaAtIndexPath:[NSIndexPath indexPathWithIndex:i]];
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
    _cachedAreaRectArea = NSUIntegerMax;
    _cachedGroupRectArea = NSUIntegerMax;
    _cachedGroupRectGroup = NSUIntegerMax;
    if (!numAreas)
        self.contentSize = CGSizeMake(0.0, 0.0);
    CGRect lastAreaFrame = [self _rectForAreaAtIndex:numAreas - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self setNeedsLayout];
}

#pragma mark -
#pragma mark Selection

- (NSIndexPath *)indexPathForSelectedItem
{
    if (_selectedElementsType != kECItemViewItemKey)
        return nil;
    return [_selectedElements anyObject];
}

- (NSSet *)indexPathsForSelectedItems
{
    if (_selectedElementsType != kECItemViewItemKey)
        return nil;
    return [[_selectedElements copy] autorelease];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(ECItemViewScrollPosition)scrollPosition
{
    if (!indexPath || _selectedElementsType != kECItemViewItemKey)
        return;
    [_selectedElements addObject:indexPath];
    [[self itemAtIndexPath:indexPath] setSelected:YES animated:YES];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (!indexPath || _selectedElementsType != kECItemViewItemKey)
        return;
    [_selectedElements removeObject:indexPath];
    [[self itemAtIndexPath:indexPath] setSelected:NO animated:YES];
}

- (void)deselectAllItemsAnimated:(BOOL)animated
{
    if (_selectedElementsType != kECItemViewItemKey)
        return;
    [_selectedElements removeAllObjects];
    for (ECItemViewElement *item in [self visibleItems])
        [item setSelected:NO animated:YES];
}

#pragma mark -
#pragma mark Recycling

- (ECItemViewElement *)dequeueReusableAreaHeader
{
    if (![[_elementCaches objectForKey:kECItemViewAreaHeaderKey] count])
        return nil;
    return [[_elementCaches objectForKey:kECItemViewAreaHeaderKey] pop];
}

- (ECItemViewElement *)dequeueReusableGroupSeparator
{
    if (![[_elementCaches objectForKey:kECItemViewGroupSeparatorKey] count])
        return nil;
    return [[_elementCaches objectForKey:kECItemViewGroupSeparatorKey] pop];
}

- (ECItemViewElement *)dequeueReusableItem
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
    for (NSIndexPath *indexPath in [self indexPathsForVisibleAreaHeaders])
    {
        ECItemViewElement *header = [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] objectForKey:indexPath];
        if (header)
            [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] removeObjectForKey:indexPath];
        else
        {
            header = [self _loadAreaHeaderAtIndexPath:indexPath];
            if (!header)
                return;
            [self addSubview:header];
            [self sendSubviewToBack:header];
        }
        header.frame = UIEdgeInsetsInsetRect([self rectForAreaHeaderAtIndexPath:indexPath], _areaHeaderInsets);
        [newVisibleAreaHeaders setObject:header forKey:indexPath];
    }
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
        ECItemViewElement *separator = [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] objectForKey:indexPath];
        if (separator)
            [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] removeObjectForKey:indexPath];
        else
        {
            separator = [self _loadGroupSeparatorAtIndexPath:indexPath];
            if (!separator)
                continue;
            [self addSubview:separator];
            [self sendSubviewToBack:separator];
        }
        separator.frame = UIEdgeInsetsInsetRect([self rectForGroupSeparatorAtIndexPath:indexPath], _groupSeparatorInsets);
        [newVisibleGroupSeparators setObject:separator forKey:indexPath];
    }
    for (ECItemViewElement *separator in [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] allValues])
    {
        [separator removeFromSuperview];
        [[_elementCaches objectForKey:kECItemViewGroupSeparatorKey] push:separator];
    }
    [_visibleElements setObject:newVisibleGroupSeparators forKey:kECItemViewGroupSeparatorKey];
}

- (void)_layoutItems
{
    NSMutableDictionary *newVisibleItems = [NSMutableDictionary dictionary];
    for (NSIndexPath *indexPath in [self indexPathsForVisibleItems])
    {
        ECItemViewElement *item = [[_visibleElements objectForKey:kECItemViewItemKey] objectForKey:indexPath];
        if (item)
            [[_visibleElements objectForKey:kECItemViewItemKey] removeObjectForKey:indexPath];
        else
        {
            item = [self _loadItemAtIndexPath:indexPath];
            if (!item)
                continue;
            if (_selectedElementsType == kECItemViewItemKey && [_selectedElements containsObject:indexPath])
                item.selected = YES;
            [self addSubview:item];
            [self sendSubviewToBack:item];
        }
        item.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:indexPath], _itemInsets);
        [newVisibleItems setObject:item forKey:indexPath];
    }
    for (ECItemViewElement *item in [[_visibleElements objectForKey:kECItemViewItemKey] allValues])
    {
        [item removeFromSuperview];
        [[_elementCaches objectForKey:kECItemViewItemKey] push:item];
    }
    [_visibleElements setObject:newVisibleItems forKey:kECItemViewItemKey];
}

- (void)layoutSubviews
{
    [self _layoutAreaHeaders];
    [self _layoutGroupSeparators];
    [self _layoutItems];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == _tapGestureRecognizer)
        return YES;
    if (gestureRecognizer == _longPressGestureRecognizer)
        if (_isEditing)
            return YES;
        else
            return NO;
    if (_flags.superGestureRecognizerShouldReceiveTouch)
        return [super gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    NSIndexPath *indexPath;
    if (gestureRecognizer == _longPressGestureRecognizer)
        if ((_flags.dataSourceMoveItem && ( indexPath = [self indexPathForItemAtPoint:[gestureRecognizer locationInView:self]])) && ((_flags.dataSourceCanMoveItem && [_dataSource itemView:self canMoveItemAtIndexPath:indexPath]) || !_flags.dataSourceCanMoveItem))
            return YES;
        else
            return NO;
    if (_flags.superGestureRecognizerShouldBegin)
        return [super gestureRecognizerShouldBegin:gestureRecognizer];
    return YES;
}

- (void)_handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (![tapGestureRecognizer state] == UIGestureRecognizerStateEnded)
        return;
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:[tapGestureRecognizer locationInView:self]];
    [__delegate itemView:self didSelectItemAtIndexPath:indexPath];
}

- (void)_handleLongPressGesture:(UILongPressGestureRecognizer *)longPressGestureRecognizer
{
    switch ([longPressGestureRecognizer state])
    {
        case UIGestureRecognizerStateBegan:
            [self _beginDrag:longPressGestureRecognizer];
            break;
        case UIGestureRecognizerStateChanged:
            [self _continueDrag:longPressGestureRecognizer];
            break;
        case UIGestureRecognizerStateEnded:
            [self _endDrag:longPressGestureRecognizer];
        default:
            [self _cancelDrag:longPressGestureRecognizer];
    }
}

- (void)_beginDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _isDragging = YES;
}

- (void)_continueDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    CGPoint point = [dragRecognizer locationInView:self];
    if (!_scrollTimer && CGRectContainsPoint(self.bounds, point) && !CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, _scrollingHotspots), point))
    {
        _scrollTimer = [NSTimer timerWithTimeInterval:1.0/60.0 target:self selector:@selector(_handleTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_scrollTimer forMode:NSDefaultRunLoopMode];
    }
    else if (_scrollTimer && !CGRectContainsPoint(self.bounds, point) && CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, _scrollingHotspots), point))
    {
        [_scrollTimer invalidate];
        _scrollTimer = nil;
    }
    [self setNeedsLayout];
}

- (void)_endDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
//    BOOL proposedIndexPathExists;
//    NSIndexPath *proposedIndexPath = [self _proposedIndexPathForItemAtPoint:[dragRecognizer locationInView:self] exists:&proposedIndexPathExists];
//    if (!proposedIndexPath)
//        [self _cancelDrag:dragRecognizer];
//    if (!proposedIndexPathExists && !proposedIndexPath.item)
//        if (_flags.dataSourceInsertGroup)
//        {
//            [_dataSource itemView:self insertGroupAtIndexPath:[NSIndexPath indexPathForPosition:proposedIndexPath.group inArea:proposedIndexPath.area]];
//            if (_draggedItemIndexPath.area == proposedIndexPath.area && _draggedItemIndexPath.group >= proposedIndexPath.group)
//            {
//                NSIndexPath *adjustedDraggedItemIndexPath = [[NSIndexPath indexPathForItem:_draggedItemIndexPath.item inGroup:_draggedItemIndexPath.group + 1 inArea:_draggedItemIndexPath.area] retain];
//                [_draggedItemIndexPath release];
//                _draggedItemIndexPath = adjustedDraggedItemIndexPath;
//            }
//            
//        }
//        else
//            [self _cancelDrag:dragRecognizer];
//    
//    _isDragging = NO;
//    [_scrollTimer invalidate];
//    _scrollTimer = nil;
//    [_dragDestinationIndexPath release];
//    _dragDestinationIndexPath = proposedIndexPath;
//    if (_flags.dataSourceMoveItem)
//        [_dataSource itemView:self moveItemAtIndexPath:_draggedItemIndexPath toIndexPath:_dragDestinationIndexPath];
//    if (_flags.dataSourceNumberOfItemsInGroup)
//        if (![_dataSource itemView:self numberOfItemsInGroupAtIndexPath:_draggedItemIndexPath])
//            if (_flags.dataSourceDeleteGroup)
//                [_dataSource itemView:self deleteGroupAtIndexPath:[NSIndexPath indexPathForPosition:_draggedItemIndexPath.group inArea:_draggedItemIndexPath.area]];
//    [self reloadData];
//    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:kECItemViewShortAnimationDuration animations:^(void) {
//        _draggedItem.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:_dragDestinationIndexPath], _itemInsets);
//    } completion:NULL];
//    [_draggedItemIndexPath release];
//    _draggedItemIndexPath = nil;
//    _dragDestinationIndexPath = nil;
    //    _draggedItem = nil;
}

- (void)_cancelDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _isDragging = NO;
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    [self setNeedsLayout];
}

- (void)_handleTimer:(NSTimer *)timer
{
    CGPoint offset = [self contentOffset];
    CGPoint point = [_longPressGestureRecognizer locationInView:self];
    if (point.y < self.bounds.origin.y + _scrollingHotspots.top && self.bounds.origin.y > 0.0)
        offset.y -= _scrollSpeed;
    else if (point.y > self.bounds.origin.y + self.bounds.size.height - _scrollingHotspots.bottom && self.bounds.origin.y < self.contentSize.height - self.bounds.size.height)
        offset.y += _scrollSpeed;
    [self setContentOffset:offset animated:NO];
    [self setNeedsLayout];
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

+ (NSIndexPath *)indexPathForArea:(NSUInteger)area
{
    return [self indexPathWithIndex:area];
}

@end
