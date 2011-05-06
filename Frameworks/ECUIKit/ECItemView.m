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
#import "ECArrayTree.h"
#import "ECItemViewElement.h"

static const CGFloat kECItemViewShortAnimationDuration = 0.15;
static const NSUInteger kECItemViewAreaHeaderBufferSize = 5;
static const NSUInteger kECItemViewGroupSeparatorBufferSize = 20;
static const NSUInteger kECItemViewItemBufferSize = 10;
static const NSString *kECItemViewBatchInsertsKey = @"inserts";
static const NSString *kECItemViewBatchDeletesKey = @"deletes";
static const NSString *kECItemViewBatchReloadsKey = @"reloads";
static const NSUInteger kECItemViewAreaDepth = 1;
static const NSUInteger kECItemViewGroupDepth = 2;
static const NSUInteger kECItemViewItemDepth = 3;
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
        unsigned int dataSourceMoveItem:1;
        unsigned int dataSourceInsertGroup:1;
        unsigned int dataSourceDeleteGroup:1;
        unsigned int dataSourceMoveGroup:1;
        unsigned int dataSourceMoveArea:1;
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
    ECMutableArrayTree *_visibleElements;
    BOOL _isAnimating;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    NSMutableSet *_selectedItems;
    BOOL _isDragging;
    CGPoint _dragPoint;
    ECItemViewElementKey _draggedElementsType;
    NSMutableSet *_draggedElements;
    ECItemViewElement *_caret;
    NSTimer *_scrollTimer;
    CGFloat _scrollSpeed;
    UIEdgeInsets _scrollingHotspots;
    NSUInteger _isBatchUpdating;
    NSMutableDictionary *_batchUpdatingStores;
}

- (void)_setup;

#pragma mark Data
- (void)_reloadNumbers;
- (ECItemViewElement *)_loadAreaHeaderAtIndexPath:(NSIndexPath *)indexPath;
- (ECItemViewElement *)_loadGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath;
- (ECItemViewElement *)_loadItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)_syncVisibleElements;

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
- (CGRect)_rectForElement:(ECItemViewElement *)element;

#pragma mark Index paths
- (NSIndexPath *)_indexPathForFirstVisibleItem;
- (NSIndexPath *)_indexPathForLastVisibleItem;
- (NSIndexPath *)_indexPathForElementType:(ECItemViewElementKey)elementType atPoint:(CGPoint)point resultType:(ECItemViewElementKey *)resultType;

#pragma mark Item insertion/deletion/reloading
- (void)_wrapCallInBatchUpdatesBlockForSelector:(SEL)selector withObject:(id)object;
- (void)_wrapCallInBatchUpdatesBlockForSelector:(SEL)selector withObject:(id)object andObject:(id)anotherObject;

#pragma mark UIView
- (void)_layoutElements;
- (void)_layoutCaret;

#pragma mark UIGestureRecognizer
- (void)_handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)_handleLongPressGesture:(UILongPressGestureRecognizer *)longPressGestureRecognizer;
- (void)_beginDrag;
- (void)_continueDrag;
- (void)_endDrag;
- (void)_cancelDrag;
- (void)_handleTimer:(NSTimer *)timer;
@end

#pragma mark -

@implementation ECItemView

#pragma mark Properties and initialization

@synthesize delegate = __delegate;
@synthesize dataSource = _dataSource;
@synthesize itemHeight = _itemHeight;
@synthesize itemsPerRow = _itemsPerRow;
@synthesize groupSeparatorHeight = _groupSeparatorHeight;
@synthesize areaHeaderHeight = _areaHeaderHeight;
@synthesize allowsSelection = _allowsSelection;
@synthesize multipleSelection = _multipleSelection;
@synthesize editing = _isEditing;

- (void)setDelegate:(id<ECItemViewDelegate>)delegate
{
    if (delegate == __delegate)
        return;
    [self willChangeValueForKey:@"delegate"];
    __delegate = delegate;
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
    _flags.dataSourceMoveItem = [dataSource respondsToSelector:@selector(itemView:moveItemsAtIndexPaths:toIndexPath:)];
    _flags.dataSourceInsertGroup = [dataSource respondsToSelector:@selector(itemView:insertGroupAtIndexPath:)];
    _flags.dataSourceDeleteGroup = [dataSource respondsToSelector:@selector(itemView:deleteGroupAtIndexPath:)];
    _flags.dataSourceMoveGroup = [dataSource respondsToSelector:@selector(itemView:moveGroupsAtIndexPaths:toIndexPath:)];
    _flags.dataSourceMoveArea = [dataSource respondsToSelector:@selector(itemView:moveAreasAtIndexPaths:toIndexPath:)];
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
    for (ECItemViewElement *element in [_visibleElements allObjects])
        [element setEditing:editing animated:animated];
    [self didChangeValueForKey:@"editing"];   
}

- (void)_setup
{
    _itemHeight = 100.0;
    _itemsPerRow = 4;
    _groupSeparatorHeight = 30.0;
    _areaHeaderHeight = 60.0;
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
    _visibleElements = [[ECMutableArrayTree alloc] init];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapGesture:)];
    _tapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_tapGestureRecognizer];
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleLongPressGesture:)];
    _longPressGestureRecognizer.minimumPressDuration = 0.5;
    _longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longPressGestureRecognizer];
    _selectedItems = [[NSMutableSet alloc] init];
    _draggedElements = [[NSMutableSet alloc] init];
    _caret = [[ECItemViewElement alloc] init];
    _caret.backgroundColor = [UIColor redColor];
    _batchUpdatingStores = [[NSMutableDictionary alloc] init];
    [_batchUpdatingStores setObject:[NSMutableDictionary dictionary] forKey:kECItemViewBatchInsertsKey];
    [_batchUpdatingStores setObject:[NSMutableDictionary dictionary] forKey:kECItemViewBatchDeletesKey];
    [_batchUpdatingStores setObject:[NSMutableDictionary dictionary] forKey:kECItemViewBatchReloadsKey];
    for (NSMutableDictionary *dictionary in [_batchUpdatingStores allValues])
    {
        [dictionary setObject:[NSMutableSet set] forKey:kECItemViewAreaKey];
        [dictionary setObject:[NSMutableSet set] forKey:kECItemViewGroupKey];
        [dictionary setObject:[NSMutableSet set] forKey:kECItemViewItemKey];
    }
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
    [_selectedItems release];
    [_draggedElements release];
    [_caret release];
    [_scrollTimer invalidate];
    [super dealloc];
}

#pragma mark -
#pragma mark Data

- (void)_reloadNumbers
{
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
}

- (void)reloadData
{
    for (ECItemViewElement *element in [_visibleElements allObjects])
        [element removeFromSuperview];
    [_visibleElements removeAllObjects];
    [self beginUpdates];
    [self endUpdates];
    [self setNeedsLayout];
}

- (ECItemViewElement *)_loadAreaHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.area >= [_areas count] || !_flags.dataSourceViewForAreaHeader)
        return nil;
    ECItemViewElement *areaHeader = [_dataSource itemView:self viewForAreaHeaderAtIndexPath:indexPath];
    areaHeader.type = kECItemViewAreaHeaderKey;
    areaHeader.indexPath = indexPath;
    return areaHeader;
}

- (ECItemViewElement *)_loadGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForGroupSeparator)
        return nil;
    ECItemViewElement *groupSeparator = [_dataSource itemView:self viewForGroupSeparatorAtIndexPath:indexPath];
    groupSeparator.type = kECItemViewGroupSeparatorKey;
    groupSeparator.indexPath = indexPath;
    return groupSeparator;
}

- (ECItemViewElement *)_loadItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForItem)
        return nil;
    ECItemViewElement *item = [_dataSource itemView:self viewForItemAtIndexPath:indexPath];
    item.type = kECItemViewItemKey;
    item.indexPath = indexPath;
    return item;
}

- (void)_syncVisibleElements
{
    NSIndexPath *firstIndexPath = [self _indexPathForFirstVisibleItem];
//    NSIndexPath *lastIndexPath = [self _indexPathForLastVisibleItem];
    if (!_visibleElements.offset)
    {
        NSUInteger numAreas = [self numberOfAreas];
        for (NSUInteger i = 0; i < numAreas; ++i)
        {
            NSIndexPath *newAreaIndexPath = [NSIndexPath indexPathForArea:i];
            ECMutableArrayTree *newArea = [[[ECMutableArrayTree alloc] init] autorelease];
            newArea.object = [self _loadAreaHeaderAtIndexPath:newAreaIndexPath];
            [_visibleElements.children insertObject:newArea atIndex:0];
            [self addSubview:newArea.object];
            NSUInteger numGroups = [self numberOfGroupsInAreaAtIndexPath:newAreaIndexPath];
            for (NSUInteger j = 0; j < numGroups; ++j)
            {
                NSIndexPath *newGroupIndexPath = [NSIndexPath indexPathForPosition:j inArea:i];
                ECMutableArrayTree *newGroup = [[[ECMutableArrayTree alloc] init] autorelease];
                newGroup.object = [self _loadGroupSeparatorAtIndexPath:newGroupIndexPath];
                [newArea.children addObject:newGroup];
                [self addSubview:newGroup.object];
                NSUInteger numItems = [self numberOfItemsInGroupAtIndexPath:newGroupIndexPath];
                for (NSUInteger k = 0; k < numItems; ++k)
                {
                    NSIndexPath *newItemIndexPath = [NSIndexPath indexPathForItem:k inGroup:j inArea:i];
                    ECMutableArrayTree *newItem = [[[ECMutableArrayTree alloc] init] autorelease];
                    newItem.object = [self _loadItemAtIndexPath:newItemIndexPath];
                    [newGroup.children addObject:newItem];
                    [self addSubview:newItem.object];
                }
            }
        }
    }
    
        /*
    if (_visibleElements.offset.area < firstIndexPath.area)
        for (NSUInteger i = firstIndexPath.area - 1; i != _visibleElements.offset.area - 1; --i)
            [_visibleElements.children removeObjectAtIndex:i];
    else if (firstIndexPath.area < _visibleElements.offset.area)
        for (NSUInteger i = _visibleElements.offset.area - 1; i != firstIndexPath.area - 1; --i)
        {
            NSIndexPath *newAreaIndexPath = [NSIndexPath indexPathForArea:i];
            ECMutableArrayTree *newArea = [[[ECMutableArrayTree alloc] init] autorelease];
            newArea.object = [self _loadAreaHeaderAtIndexPath:newAreaIndexPath];
            [_visibleElements.children insertObject:newArea atIndex:0];
            NSUInteger numGroups = [self numberOfGroupsInAreaAtIndexPath:newAreaIndexPath];
            for (NSUInteger j = 0; j < numGroups; ++j)
            {
                NSIndexPath *newGroupIndexPath = [NSIndexPath indexPathForPosition:j inArea:i];
                ECMutableArrayTree *newGroup = [[[ECMutableArrayTree alloc] init] autorelease];
                newGroup.object = [self _loadGroupSeparatorAtIndexPath:newGroupIndexPath];
                [newArea.children addObject:newGroup];
                NSUInteger numItems = [self numberOfItemsInGroupAtIndexPath:newGroupIndexPath];
                for (NSUInteger k = 0; k < numItems; ++k)
                {
                    NSIndexPath *newItemIndexPath = [NSIndexPath indexPathForItem:k inGroup:j inArea:i];
                    ECMutableArrayTree *newItem = [[[ECMutableArrayTree alloc] init] autorelease];
                    newItem.object = [self _loadItemAtIndexPath:newItemIndexPath];
                    [newGroup.children addObject:newItem];
                }
            }
        }*/
    _visibleElements.offset = firstIndexPath;
    // TODO: unload items too, also consider same area offset, different group and item offsets
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
    return CGRectMake(areaRect.origin.x, areaRect.origin.y, areaRect.size.width, _areaHeaderHeight);
}

- (CGRect)rectForAreaHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    return [self _rectForAreaHeaderAtIndex:indexPath.area];
}

- (CGFloat)_heightForGroupAtIndex:(NSUInteger)group inArea:(NSUInteger)area
{
    return [self _rowsInGroup:group inArea:area] * _itemHeight + _groupSeparatorHeight;
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
    CGFloat x = groupRect.origin.x;
    CGFloat y = groupRect.origin.y + groupRect.size.height;
    CGFloat width = groupRect.size.width;
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
    CGFloat itemWidth = groupRect.size.width / (CGFloat)_itemsPerRow;
    x += column * itemWidth;
    y += row * _itemHeight;
    return CGRectMake(x, y, itemWidth, _itemHeight);
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self _rectForItemAtIndex:indexPath.item inGroup:indexPath.group inArea:indexPath.area];
}

- (CGRect)_rectForElement:(ECItemViewElement *)element
{
    if (!element.type || !element.indexPath)
        return CGRectZero;
    if (element.type == kECItemViewAreaHeaderKey)
        return [self rectForAreaHeaderAtIndexPath:element.indexPath];
    if (element.type == kECItemViewGroupSeparatorKey)
        return [self rectForGroupSeparatorAtIndexPath:element.indexPath];
    if (element.type == kECItemViewItemKey)
        return [self rectForItemAtIndexPath:element.indexPath];
    return CGRectZero;
}

#pragma mark -
#pragma mark Index paths

- (NSIndexPath *)_indexPathForFirstVisibleItem
{
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
        if (CGRectIntersectsRect(self.bounds, [self _rectForAreaAtIndex:i]))
        {
            NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:i];
            for (NSUInteger j = 0; j < numGroups; ++j)
                if (CGRectIntersectsRect(self.bounds, [self _rectForGroupAtIndex:j inArea:i]))
                {
                    NSUInteger numItems = [self _numberOfItemsInGroup:j inArea:i];
                    for (NSUInteger k = 0; k < numItems; ++k)
                    {
                        CGRect itemRect = [self _rectForItemAtIndex:k inGroup:j inArea:i];
                        if (!CGRectIntersectsRect(self.bounds, itemRect))
                            continue;
                        return [NSIndexPath indexPathForItem:k inGroup:j inArea:i];
                    }
                }
        }
    return nil;
}

- (NSIndexPath *)_indexPathForLastVisibleItem
{
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = numAreas - 1; i != NSUIntegerMax; --i)
        if (CGRectIntersectsRect(self.bounds, [self _rectForAreaAtIndex:i]))
        {
            NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:i];
            for (NSUInteger j = numGroups; j != NSUIntegerMax; --j)
                if (CGRectIntersectsRect(self.bounds, [self _rectForGroupAtIndex:j inArea:i]))
                {
                    NSUInteger numItems = [self _numberOfItemsInGroup:j inArea:i];
                    for (NSUInteger k = numItems; k != NSUIntegerMax; --k)
                    {
                        CGRect itemRect = [self _rectForItemAtIndex:k inGroup:j inArea:i];
                        if (!CGRectIntersectsRect(self.bounds, itemRect))
                            continue;
                        return [NSIndexPath indexPathForItem:k inGroup:j inArea:i];
                    }
                }
        }
    return nil;
}

- (ECItemViewElement *)elementAtIndexPath:(NSIndexPath *)indexPath
{
    return [_visibleElements objectAtIndexPath:indexPath];
}

- (ECItemViewElement *)elementAtPoint:(CGPoint)point
{
    for (ECItemViewElement *element in [_visibleElements allObjects])
        if (CGRectContainsPoint(element.frame, point))
            return element;
    return nil;
}

- (ECArrayTree *)visibleElements
{
    return [[_visibleElements copy] autorelease];
}

- (NSArray *)_indexPathsForVisibleAreas
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

- (NSArray *)_indexPathsForVisibleGroups
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSIndexPath *areaIndexPath in [self _indexPathsForVisibleAreas])
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

- (NSArray *)_indexPathsForVisibleItems
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSIndexPath *groupIndexPath in [self _indexPathsForVisibleGroups])
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

- (NSArray *)indexPathsForVisibleElements
{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[self _indexPathsForVisibleItems]];
    [array addObjectsFromArray:[self _indexPathsForVisibleGroups]];
    [array addObjectsFromArray:[self _indexPathsForVisibleAreas]];
    return array;
}

- (NSIndexPath *)_indexPathForElementType:(ECItemViewElementKey)elementType atPoint:(CGPoint)point resultType:(ECItemViewElementKey *)resultType
{
    // TODO: implement this with nested geometry hittesting instead of cycling frames, compare the two implementations with instruments
    ECItemViewElement *element = [self elementAtPoint:point];
    if (resultType)
        *resultType = element.type;
    return element.indexPath;
}

#pragma mark -
#pragma mark Item insertion/deletion/reloading

- (void)beginUpdates
{
    ++_isBatchUpdating;
}

- (void)endUpdates
{
    if (!_isBatchUpdating)
        [NSException raise:NSInternalInconsistencyException format:@"endUpdates without corresponding beginUpdates"];
    --_isBatchUpdating;
    
    /*
    NSUInteger offset;
    NSMutableArray *cellsToInsert = [NSMutableArray arrayWithCapacity:[[_visibleElements objectForKey:kECItemViewItemKey] count]];
    NSMutableArray *cellsToDelete = [NSMutableArray arrayWithCapacity:[[_visibleElements objectForKey:kECItemViewItemKey] count]];
    NSMutableArray *cellsToLoad = [NSMutableArray arrayWithCapacity:[[_visibleElements objectForKey:kECItemViewItemKey] count]];
    NSMutableArray *cellsToUnload = [NSMutableArray arrayWithCapacity:[[_visibleElements objectForKey:kECItemViewItemKey] count]];
    for (NSIndexPath *groupIndexPath in [self _indexPathsForVisibleGroups])
    {
        offset = 0;
        NSUInteger numItems = [self numberOfItemsInGroupAtIndexPath:groupIndexPath];
        for (NSUInteger index = 0; index < numItems; ++index)
        {
            ECItemViewElement *item;
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
    */
    
    [self _reloadNumbers];
    if (!_isBatchUpdating)
        for (NSDictionary *dictionary in [_batchUpdatingStores allValues])
            for (NSMutableSet *set in [dictionary allValues])
                [set removeAllObjects];
    _cachedAreaRectArea = NSUIntegerMax;
    _cachedGroupRectArea = NSUIntegerMax;
    _cachedGroupRectGroup = NSUIntegerMax;
    if (![self numberOfAreas])
        self.contentSize = CGSizeMake(0.0, 0.0);
    CGRect lastAreaFrame = [self _rectForAreaAtIndex:[self numberOfAreas] - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self setNeedsLayout];
}

- (void)_wrapCallInBatchUpdatesBlockForSelector:(SEL)selector withObject:(id)object
{
    [self beginUpdates];
    [self performSelector:selector withObject:object];
    [self endUpdates];
}

- (void)_wrapCallInBatchUpdatesBlockForSelector:(SEL)selector withObject:(id)object andObject:(id)anotherObject
{
    [self beginUpdates];
    [self performSelector:selector withObject:object withObject:anotherObject];
    [self endUpdates];
}

- (void)insertAreasAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewAreaKey] addObjectsFromArray:indexPaths];
}

- (void)deleteAreasAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewAreaKey] addObjectsFromArray:indexPaths];
}

- (void)reloadAreasAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchReloadsKey] objectForKey:kECItemViewAreaKey] addObjectsFromArray:indexPaths];
}

- (void)insertGroupsAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewGroupKey] addObjectsFromArray:indexPaths];
}

- (void)deleteGroupsAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewGroupKey] addObjectsFromArray:indexPaths];
}

- (void)reloadGroupsAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchReloadsKey] objectForKey:kECItemViewGroupKey] addObjectsFromArray:indexPaths];
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewItemKey] addObjectsFromArray:indexPaths];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewItemKey] addObjectsFromArray:indexPaths];
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths];
    else
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchReloadsKey] objectForKey:kECItemViewItemKey] addObjectsFromArray:indexPaths];
}

- (void)moveAreasAtIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths andObject:indexPath];
    else
    {
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewAreaKey] addObjectsFromArray:indexPaths];
        NSUInteger numIndexPaths = [indexPaths count];
        for (NSUInteger i = 0; i < numIndexPaths; ++i)
            [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewAreaKey] addObject:[NSIndexPath indexPathForArea:indexPath.area + i]];
    }
}

- (void)moveGroupsAtIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths andObject:indexPath];
    else
    {
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewGroupKey] addObjectsFromArray:indexPaths];
        NSUInteger numIndexPaths = [indexPaths count];
        for (NSUInteger i = 0; i < numIndexPaths; ++i)
            [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewGroupKey] addObject:[NSIndexPath indexPathForPosition:indexPath.position + i inArea:indexPath.area]];
    }
}

- (void)moveItemsAtIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath
{
    if (!_isBatchUpdating)
        [self _wrapCallInBatchUpdatesBlockForSelector:_cmd withObject:indexPaths andObject:indexPath];
    else
    {
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewItemKey] addObjectsFromArray:indexPaths];
        NSUInteger numIndexPaths = [indexPaths count];
        for (NSUInteger i = 0; i < numIndexPaths; ++i)
            [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewItemKey] addObject:[NSIndexPath indexPathForItem:indexPath.item + i inGroup:indexPath.group inArea:indexPath.area]];
    }
}

#pragma mark -
#pragma mark Selection

- (NSIndexPath *)indexPathForSelectedItem
{
    return [_selectedItems anyObject];
}

- (NSSet *)indexPathsForSelectedItems
{
    return [NSSet setWithSet:_selectedItems];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(ECItemViewScrollPosition)scrollPosition
{
    if (!indexPath)
        return;
    [_selectedItems addObject:indexPath];
    [[_visibleElements objectAtIndexPath:indexPath] setSelected:YES animated:YES];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (!indexPath)
        return;
    [_selectedItems removeObject:indexPath];
    [[_visibleElements objectAtIndexPath:indexPath] setSelected:NO animated:YES];
}

- (void)deselectAllItemsAnimated:(BOOL)animated
{
    [_selectedItems removeAllObjects];
    for (ECItemViewElement *item in [_visibleElements objectsAtDepth:kECItemViewItemDepth])
        [item setSelected:NO animated:YES];
}

#pragma mark -
#pragma mark Recycling

- (ECItemViewElement *)dequeueReusableElementForType:(ECItemViewElementKey)type
{
    if (![[_elementCaches objectForKey:type] count])
        return nil;
    ECItemViewElement *element = [[_elementCaches objectForKey:type] pop];
    element.selected = NO;
    element.dragged = NO;
    element.editing = NO;
    element.indexPath = nil;
    return element;
}

#pragma mark -
#pragma mark UIView

//- (void)_layoutAreaHeaders
//{
//    NSMutableDictionary *newVisibleAreaHeaders = [NSMutableDictionary dictionary];
//    for (NSIndexPath *indexPath in [self _indexPathsForVisibleAreas])
//    {
//        ECItemViewElement *header = [_visibleElements objectAtIndexPath:indexPath];
//        if (header)
//            [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] removeObjectForKey:indexPath];
//        else
//        {
//            header = [self _loadAreaHeaderAtIndexPath:indexPath];
//            if (!header)
//                return;
//            [self addSubview:header];
//            [self sendSubviewToBack:header];
//        }
//        header.frame = UIEdgeInsetsInsetRect([self rectForAreaHeaderAtIndexPath:indexPath], _areaHeaderInsets);
//        [newVisibleAreaHeaders setObject:header forKey:indexPath];
//    }
//    for (UILabel *header in [[_visibleElements objectForKey:kECItemViewAreaHeaderKey] allValues])
//    {
//        [header removeFromSuperview];
//        [[_elementCaches objectForKey:kECItemViewAreaHeaderKey] push:header];
//    }
//    [_visibleElements setObject:newVisibleAreaHeaders forKey:kECItemViewAreaHeaderKey];
//}
//
//- (void)_layoutGroupSeparators
//{
//    NSMutableDictionary *newVisibleGroupSeparators = [NSMutableDictionary dictionary];
//    for (NSIndexPath *indexPath in [self indexPathsForVisibleGroupSeparators])
//    {
//        ECItemViewElement *separator = [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] objectForKey:indexPath];
//        if (separator)
//            [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] removeObjectForKey:indexPath];
//        else
//        {
//            separator = [self _loadGroupSeparatorAtIndexPath:indexPath];
//            if (!separator)
//                continue;
//            [self addSubview:separator];
//            [self sendSubviewToBack:separator];
//        }
//        separator.frame = UIEdgeInsetsInsetRect([self rectForGroupSeparatorAtIndexPath:indexPath], _groupSeparatorInsets);
//        [newVisibleGroupSeparators setObject:separator forKey:indexPath];
//    }
//    for (ECItemViewElement *separator in [[_visibleElements objectForKey:kECItemViewGroupSeparatorKey] allValues])
//    {
//        [separator removeFromSuperview];
//        [[_elementCaches objectForKey:kECItemViewGroupSeparatorKey] push:separator];
//    }
//    [_visibleElements setObject:newVisibleGroupSeparators forKey:kECItemViewGroupSeparatorKey];
//}
//
//- (void)_layoutItems
//{
//    NSMutableDictionary *newVisibleItems = [NSMutableDictionary dictionary];
//    for (NSIndexPath *indexPath in [self indexPathsForVisibleItems])
//    {
//        ECItemViewElement *item = [[_visibleElements objectForKey:kECItemViewItemKey] objectForKey:indexPath];
//        if (item)
//            [[_visibleElements objectForKey:kECItemViewItemKey] removeObjectForKey:indexPath];
//        else
//        {
//            item = [self _loadItemAtIndexPath:indexPath];
//            if (!item)
//                continue;
//            if (_draggedElementsType == kECItemViewItemKey && [_draggedElements containsObject:indexPath])
//                item.selected = YES;
//            if ([_selectedItems containsObject:indexPath])
//                item.dragged = YES;
//            [self addSubview:item];
//            [self sendSubviewToBack:item];
//        }
//        item.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:indexPath], _itemInsets);
//        [newVisibleItems setObject:item forKey:indexPath];
//    }
//    for (ECItemViewElement *item in [[_visibleElements objectForKey:kECItemViewItemKey] allValues])
//    {
//        [item removeFromSuperview];
//        [[_elementCaches objectForKey:kECItemViewItemKey] push:item];
//    }
//    [_visibleElements setObject:newVisibleItems forKey:kECItemViewItemKey];
//}

- (void)_layoutElements
{
    for (ECItemViewElement *element in [_visibleElements allObjects])
        element.frame = [self _rectForElement:element];
}

- (void)_layoutCaret
{
    if (!_isDragging)
        return;
    ECItemViewElementKey type = _caret.type;
    NSIndexPath *indexPath = _caret.indexPath;
    if (type == kECItemViewItemKey)
    {
        CGRect rect = [self rectForItemAtIndexPath:indexPath];
        rect.size. width = 10;
        rect.origin.x -= 5;
        _caret.frame = rect;
    }
    else if (type == kECItemViewGroupKey)
    {
        CGRect rect = [self rectForItemAtIndexPath:[NSIndexPath indexPathForItem:[self numberOfItemsInGroupAtIndexPath:indexPath] inGroup:indexPath.group inArea:indexPath.area]];
        rect.size. width = 10;
        rect.origin.x -= 5;
        _caret.frame = rect;
    }
    else if (type == kECItemViewAreaHeaderKey)
        _caret.frame = [self rectForAreaHeaderAtIndexPath:indexPath];
    else if (type == kECItemViewGroupSeparatorKey)
        _caret.frame = [self rectForGroupSeparatorAtIndexPath:indexPath];
    else
        _caret.frame = CGRectZero;
}

- (void)layoutSubviews
{
    [self _syncVisibleElements];
    [self _layoutElements];
    [self _layoutCaret];
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
    if (gestureRecognizer == _longPressGestureRecognizer)
        if (_flags.dataSourceMoveItem)
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
    ECItemViewElement *element = [self elementAtPoint:[tapGestureRecognizer locationInView:self]];
    if (element.type != kECItemViewItemKey)
        return;
    if (![_selectedItems containsObject:element.indexPath])
    {
        [self selectItemAtIndexPath:element.indexPath animated:YES scrollPosition:ECItemViewScrollPositionNone];
        if (_flags.delegateDidSelectItem)
            [__delegate itemView:self didSelectItemAtIndexPath:element.indexPath];
    }
    else
    {
        [self deselectItemAtIndexPath:element.indexPath animated:YES];
        if (_flags.delegateDidDeselectItem)
            [__delegate itemView:self didDeselectItemAtIndexPath:element.indexPath];
    }
}

- (void)_handleLongPressGesture:(UILongPressGestureRecognizer *)longPressGestureRecognizer
{
    _dragPoint = [longPressGestureRecognizer locationInView:self];
    switch ([longPressGestureRecognizer state])
    {
        case UIGestureRecognizerStateBegan:
            [self _beginDrag];
        case UIGestureRecognizerStateChanged:
            [self _continueDrag];
            break;
        case UIGestureRecognizerStateEnded:
            [self _endDrag];
        default:
            [self _cancelDrag];
    }
}

- (void)_beginDrag
{
    NSIndexPath *indexPath = [self _indexPathForElementType:nil atPoint:_dragPoint resultType:&_draggedElementsType];
    _isDragging = YES;
    [self addSubview:_caret];
    if (_draggedElementsType == kECItemViewAreaHeaderKey)
        _draggedElementsType = kECItemViewAreaKey;
    else if (_draggedElementsType == kECItemViewGroupSeparatorKey)
        _draggedElementsType = kECItemViewGroupKey;
    if (_draggedElementsType == kECItemViewItemKey && [_selectedItems containsObject:indexPath])
    {
        [_draggedElements release];
        _draggedElements = [_selectedItems mutableCopy];
    }
    else
        [_draggedElements addObject:indexPath];
}

- (void)_continueDrag
{
    ECItemViewElementKey type;
    _caret.indexPath = [self _indexPathForElementType:_draggedElementsType atPoint:_dragPoint resultType:&type];
    _caret.type = type;
    if (!_scrollTimer && CGRectContainsPoint(self.bounds, _dragPoint) && !CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, _scrollingHotspots), _dragPoint))
    {
        _scrollTimer = [NSTimer timerWithTimeInterval:1.0/60.0 target:self selector:@selector(_handleTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_scrollTimer forMode:NSDefaultRunLoopMode];
    }
    else if (_scrollTimer && !CGRectContainsPoint(self.bounds, _dragPoint) && CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, _scrollingHotspots), _dragPoint))
    {
        [_scrollTimer invalidate];
        _scrollTimer = nil;
    }
    [self setNeedsLayout];
}

- (void)_endDrag
{
    NSIndexPath *caretIndexPath = _caret.indexPath;
    ECItemViewElementKey caretType = _caret.type;
    NSArray *draggedElements = [_draggedElements allObjects];
    if (_draggedElementsType == kECItemViewItemKey)
    {
        if (caretType == kECItemViewItemKey)
        {
            [_dataSource itemView:self moveItemsAtIndexPaths:draggedElements toIndexPath:caretIndexPath];
            [self moveItemsAtIndexPaths:draggedElements toIndexPath:caretIndexPath];
        }
        else if (caretType == kECItemViewGroupKey)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self numberOfItemsInGroupAtIndexPath:caretIndexPath] inGroup:caretIndexPath.position inArea:caretIndexPath.area];
            [_dataSource itemView:self moveItemsAtIndexPaths:draggedElements toIndexPath:indexPath];
            [self moveItemsAtIndexPaths:draggedElements toIndexPath:indexPath];
        }
        else
        {
            [self beginUpdates];
            [self deleteItemsAtIndexPaths:[_draggedElements allObjects]];
            NSIndexPath *newGroupIndexPath = nil;
            if (_caret.type == kECItemViewGroupSeparatorKey)
                newGroupIndexPath = [NSIndexPath indexPathForItem:0 inGroup:caretIndexPath.group + 1 inArea:caretIndexPath.area];
            else
                newGroupIndexPath = [NSIndexPath indexPathForItem:0 inGroup:0 inArea:caretIndexPath.area];
            [_dataSource itemView:self insertGroupAtIndexPath:newGroupIndexPath];
            [_dataSource itemView:self moveItemsAtIndexPaths:draggedElements toIndexPath:newGroupIndexPath];
            [self insertGroupsAtIndexPaths:[NSArray arrayWithObject:newGroupIndexPath]];
            [self endUpdates];
        }
    }
}

- (void)_cancelDrag
{
    _isDragging = NO;
    [_caret removeFromSuperview];
    for (NSIndexPath *indexPath in _draggedElements)
    {
        ECItemViewElement *element = [_visibleElements objectAtIndexPath:indexPath];
        element.dragged = NO;
    }
    _draggedElementsType = nil;
    [_draggedElements removeAllObjects];
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    [self setNeedsLayout];
}

- (void)_handleTimer:(NSTimer *)timer
{
    CGPoint offset = [self contentOffset];
    CGFloat scrollStep;
    CGRect bounds = self.bounds;
    if (_dragPoint.y < bounds.origin.y + _scrollingHotspots.top && bounds.origin.y > 0.0)
    {
        scrollStep = MIN(_scrollSpeed, bounds.origin.y);
        offset.y -= scrollStep;
        _dragPoint.y -= scrollStep;
    }
    else if (_dragPoint.y > bounds.origin.y + bounds.size.height - _scrollingHotspots.bottom && bounds.origin.y < (scrollStep = (self.contentSize.height - bounds.size.height)))
    {
        scrollStep = MIN(_scrollSpeed, scrollStep);
        offset.y += scrollStep;
        _dragPoint.y += scrollStep;
    }
    [self setContentOffset:offset animated:NO];
    [self _continueDrag];
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
