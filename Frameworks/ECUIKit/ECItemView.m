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
#import <ECFoundation/ECArrayTree.h>
#import "ECItemViewElement.h"

static const CGFloat kECItemViewShortAnimationDuration = 0.15;
static const CGFloat kECItemViewLongAnimationDuration = 0.75;
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
        unsigned int dataSourceMoveGroup:1;
        unsigned int dataSourceMoveArea:1;
        unsigned int delegateDidSelectItem:1;
        unsigned int delegateDidDeselectItem:1;
    } _flags;
    NSMutableDictionary *_elementCaches;
    NSUInteger _cachedAreaRectArea;
    CGRect _cachedAreaRectRect;
    NSUInteger _cachedGroupRectArea;
    NSUInteger _cachedGroupRectGroup;
    CGRect _cachedGroupRectRect;
    CGRect _previousVisibleRect;
    ECMutableArrayTree *_elements;
    BOOL _isAnimating;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    NSMutableSet *_selectedItems;
    BOOL _isDragging;
    CGPoint _dragPoint;
    ECItemViewElementKey _draggedElementsType;
    NSMutableSet *_draggedElements;
    ECItemViewElement *_caret;
    NSIndexPath *_caretIndexPath;
    NSTimer *_scrollTimer;
    CGFloat _scrollSpeed;
    UIEdgeInsets _scrollingHotspots;
    NSUInteger _isBatchUpdating;
    NSMutableDictionary *_batchUpdatingStores;
}

- (void)_setup;

#pragma mark Data
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
- (CGRect)_rectForElement:(ECItemViewElement *)element atIndexPath:(NSIndexPath *)indexPath;

#pragma mark Index paths
- (void)_enumerateElementsInRect:(CGRect)rect contained:(BOOL)contained withBlock:(void(^)(ECItemViewElementKey type, NSUInteger area, NSUInteger group, NSUInteger item))block;
- (NSIndexPath *)_indexPathForElementAtPoint:(CGPoint)point type:(ECItemViewElementKey *)type;

#pragma mark Item insertion/deletion/reloading
- (void)_beginEndUpdatesIfNeededForBlock:(void(^)(void))block;

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
    for (ECItemViewElement *element in [_elements allObjects])
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
    _elementCaches = [[NSMutableDictionary alloc] init];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewAreaHeaderBufferSize] forKey:kECItemViewAreaHeaderKey];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewGroupSeparatorBufferSize] forKey:kECItemViewGroupSeparatorKey];
    [_elementCaches setObject:[ECStackCache cacheWithTarget:nil action:NULL size:kECItemViewItemBufferSize] forKey:kECItemViewItemKey];
    _cachedAreaRectArea = NSUIntegerMax;
    _cachedGroupRectArea = NSUIntegerMax;
    _cachedGroupRectGroup = NSUIntegerMax;
    _elements = [[ECMutableArrayTree alloc] init];
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
    [_elementCaches release];
    [_elements release];
    [_tapGestureRecognizer release];
    [_longPressGestureRecognizer release];
    [_selectedItems release];
    [_draggedElements release];
    [_caret release];
    [_caretIndexPath release];
    [_scrollTimer invalidate];
    [super dealloc];
}

#pragma mark -
#pragma mark Data

- (void)reloadData
{
    for (ECItemViewElement *element in [_elements allObjects])
        [element removeFromSuperview];
    [_elements removeAllObjects];
    NSUInteger numAreas = 1;
    if (_flags.dataSourceNumberOfAreasInItemView)
        numAreas = [_dataSource numberOfAreasInItemView:self];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        [_elements addObject:nil toIndexPath:nil];
        NSUInteger numGroups = 0;
        if (_flags.dataSourceNumberOfGroupsInArea)
            numGroups = [_dataSource itemView:self numberOfGroupsInAreaAtIndexPath:[NSIndexPath indexPathWithIndex:i]];
        for (NSUInteger j = 0; j < numGroups; ++j)
        {
            [[_elements.children objectAtIndex:i] addObject:nil toIndexPath:nil];
            NSUInteger numItems = 0;
            if (_flags.dataSourceNumberOfItemsInGroup)
                numItems = [_dataSource itemView:self numberOfItemsInGroupAtIndexPath:[NSIndexPath indexPathForGroup:j inArea:i]];
            for (NSUInteger k = [[[[[_elements.children objectAtIndex:i] children] objectAtIndex:j] children] count]; k < numItems; ++k)
                [[[[_elements.children objectAtIndex:i] children] objectAtIndex:j] addObject:nil toIndexPath:nil];
        }
    }
    if (![self numberOfAreas])
        self.contentSize = CGSizeMake(0.0, 0.0);
    CGRect lastAreaFrame = [self _rectForAreaAtIndex:[self numberOfAreas] - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self setNeedsLayout];
}

- (ECItemViewElement *)_loadAreaHeaderAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForAreaHeader)
        return nil;
    ECItemViewElement *areaHeader = [_dataSource itemView:self viewForAreaHeaderAtIndexPath:indexPath];
    areaHeader.type = kECItemViewAreaHeaderKey;
    return areaHeader;
}

- (ECItemViewElement *)_loadGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForGroupSeparator)
        return nil;
    ECItemViewElement *groupSeparator = [_dataSource itemView:self viewForGroupSeparatorAtIndexPath:indexPath];
    groupSeparator.type = kECItemViewGroupSeparatorKey;
    return groupSeparator;
}

- (ECItemViewElement *)_loadItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceViewForItem)
        return nil;
    ECItemViewElement *item = [_dataSource itemView:self viewForItemAtIndexPath:indexPath];
    item.type = kECItemViewItemKey;
    return item;
}

- (void)_syncVisibleElements
{
    CGRect currentBounds = self.bounds;
    [self _enumerateElementsInRect:currentBounds contained:NO withBlock:^(ECItemViewElementKey type, NSUInteger area, NSUInteger group, NSUInteger item) {
        if (type == kECItemViewAreaHeaderKey)
        {
            if ([[_elements.children objectAtIndex:area] object])
                return;
            NSIndexPath *newAreaIndexPath = [NSIndexPath indexPathForArea:area];
            ECItemViewElement *newArea = [self _loadAreaHeaderAtIndexPath:newAreaIndexPath];
            [_elements replaceObjectAtIndexPath:newAreaIndexPath withObject:newArea];
            [self addSubview:newArea];
            [self sendSubviewToBack:newArea];
        }
        else if (type == kECItemViewGroupSeparatorKey)
        {
            if ([[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] object])
                return;
            NSIndexPath *newGroupIndexPath = [NSIndexPath indexPathForGroup:group inArea:area];
            ECItemViewElement *newGroup = [self _loadGroupSeparatorAtIndexPath:newGroupIndexPath];
            [_elements replaceObjectAtIndexPath:newGroupIndexPath withObject:newGroup];
            [self addSubview:newGroup];
            [self sendSubviewToBack:newGroup];
        }
        else if (type == kECItemViewItemKey)
        {
            if ([[[[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] children] objectAtIndex:item] object])
                return;
            NSIndexPath *newItemIndexPath = [NSIndexPath indexPathForItem:item inGroup:group inArea:area];
            ECItemViewElement *newItem = [self _loadItemAtIndexPath:newItemIndexPath];
            [_elements replaceObjectAtIndexPath:newItemIndexPath withObject:newItem];
            [self addSubview:newItem];
            [self sendSubviewToBack:newItem];
        }
    }];
    CGFloat heightIncrease = MAX(_areaHeaderHeight, _groupSeparatorHeight);
    heightIncrease = MAX(heightIncrease, _itemHeight);
    CGRect oldRectSubRects[4] = {CGRectZero, CGRectZero, CGRectZero, CGRectZero};
    if (_previousVisibleRect.origin.y < currentBounds.origin.y)
        oldRectSubRects[0] = CGRectMake(_previousVisibleRect.origin.x, _previousVisibleRect.origin.y - heightIncrease, _previousVisibleRect.size.width, currentBounds.origin.y - _previousVisibleRect.origin.y + heightIncrease);
    if (_previousVisibleRect.origin.x < currentBounds.origin.x)
        oldRectSubRects[1] = CGRectMake(_previousVisibleRect.origin.x, currentBounds.origin.y - heightIncrease, currentBounds.origin.x - _previousVisibleRect.origin.x, currentBounds.size.height + 2 * heightIncrease);
    if (_previousVisibleRect.origin.y + _previousVisibleRect.size.height > currentBounds.origin.y + currentBounds.size.height)
        oldRectSubRects[2] = CGRectMake(_previousVisibleRect.origin.x, currentBounds.origin.y + currentBounds.size.height, _previousVisibleRect.size.width, _previousVisibleRect.origin.y + _previousVisibleRect.size.height - currentBounds.origin.y - currentBounds.size.height + heightIncrease);
    if (_previousVisibleRect.origin.x + _previousVisibleRect.size.width > currentBounds.origin.x + currentBounds.size.width)
        oldRectSubRects[3] = CGRectMake(currentBounds.origin.x + currentBounds.size.width, currentBounds.origin.y - heightIncrease, _previousVisibleRect.origin.x + _previousVisibleRect.size.width - currentBounds.origin.x - currentBounds.size.width, currentBounds.size.height + 2 * heightIncrease);
    for (NSUInteger i = 0; i < 4; ++i)
        if (!CGRectEqualToRect(oldRectSubRects[i], CGRectZero))
            [self _enumerateElementsInRect:oldRectSubRects[i] contained:YES withBlock:^(ECItemViewElementKey type, NSUInteger area, NSUInteger group, NSUInteger item) {
                if (type == kECItemViewAreaHeaderKey)
                {
                    [[[_elements.children objectAtIndex:area] object] removeFromSuperview];
                    [[_elements.children objectAtIndex:area] setObject:nil];
                }
                else if (type == kECItemViewGroupSeparatorKey)
                {
                    [[[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] object] removeFromSuperview];
                    [[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] setObject:nil];
                }
                else if (type == kECItemViewItemKey)
                {
                    [[[[[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] children] objectAtIndex:item] object] removeFromSuperview];
                    [[[[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] children] objectAtIndex:item] setObject:nil];
                }
            }];
    _previousVisibleRect = currentBounds;
}

#pragma mark -
#pragma mark Info

- (NSUInteger)numberOfAreas
{
    return [_elements.children count];
}

- (NSUInteger)_numberOfGroupsInAreaAtIndex:(NSUInteger)area
{
    return [[[_elements.children objectAtIndex:area] children] count];
}

- (NSUInteger)numberOfGroupsInAreaAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[_elements.children objectAtIndex:indexPath.area] children] count];
}

- (NSUInteger)_numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [[[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] children] count];
}

- (NSUInteger)numberOfItemsInGroupAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[[[_elements.children objectAtIndex:indexPath.area] children] objectAtIndex:indexPath.group] children] count];
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
    if (area == _cachedGroupRectArea && group == _cachedGroupRectGroup)
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

- (CGRect)_rectForElement:(ECItemViewElement *)element atIndexPath:(NSIndexPath *)indexPath
{
    if (!element.type || !indexPath)
        return CGRectZero;
    if (element.type == kECItemViewAreaHeaderKey)
        return [self rectForAreaHeaderAtIndexPath:indexPath];
    if (element.type == kECItemViewGroupSeparatorKey)
        return [self rectForGroupSeparatorAtIndexPath:indexPath];
    if (element.type == kECItemViewItemKey)
        return [self rectForItemAtIndexPath:indexPath];
    return CGRectZero;
}

#pragma mark -
#pragma mark Index paths

- (void)_enumerateElementsInRect:(CGRect)rect contained:(BOOL)contained withBlock:(void (^)(ECItemViewElementKey, NSUInteger, NSUInteger, NSUInteger))block
{
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
        if (CGRectIntersectsRect(rect, [self _rectForAreaAtIndex:i]))
        {
            CGRect areaHeaderRect = [self _rectForAreaHeaderAtIndex:i];
            if ((contained && CGRectContainsRect(rect, areaHeaderRect)) || (!contained && CGRectIntersectsRect(rect, areaHeaderRect)))
                block(kECItemViewAreaHeaderKey, i, 0, 0);
            NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:i];
            for (NSUInteger j = 0; j < numGroups; ++j)
                if (CGRectIntersectsRect(rect, [self _rectForGroupAtIndex:j inArea:i]))
                {
                    CGRect groupSeparatorRect = [self _rectForGroupSeparatorAtIndex:j inArea:i];
                    if ((contained && CGRectContainsRect(rect, groupSeparatorRect)) || (!contained && CGRectIntersectsRect(rect, groupSeparatorRect)))
                        block(kECItemViewGroupSeparatorKey, i, j, 0);
                    NSUInteger numItems = [self _numberOfItemsInGroup:j inArea:i];
                    for (NSUInteger k = 0; k < numItems;)
                    {
                        CGRect itemRect = [self _rectForItemAtIndex:k inGroup:j inArea:i];
                        if ((contained && CGRectContainsRect(rect, itemRect)) || (!contained && CGRectIntersectsRect(rect, itemRect)))
                            block(kECItemViewItemKey, i, j, k);
                        if (itemRect.origin.y + itemRect.size.height < rect.origin.y)
                            k += self.itemsPerRow;
                        else if (itemRect.origin.y > rect.origin.y + rect.size.height)
                            break;
                        else
                            ++k;
                    }
                }
        }
}

- (NSIndexPath *)_indexPathForElementAtPoint:(CGPoint)point type:(ECItemViewElementKey *)type
{
    BOOL (^typeIncludesKey)(ECItemViewElementKey) = ^(ECItemViewElementKey key)
    {
        return (BOOL)(!type || !*type || *type == key);
    };
    BOOL (^typeIncludesKeysOtherThanKey)(ECItemViewElementKey) = ^(ECItemViewElementKey key)
    {
        return (BOOL)(!type || *type != key);
    };
    NSIndexPath *(^indexPathAndType)(NSIndexPath *, ECItemViewElementKey) = ^(NSIndexPath *indexPath, ECItemViewElementKey key)
    {
        if (type)
            *type = key;
        return indexPath;
    };
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
        if (CGRectContainsPoint([self _rectForAreaAtIndex:i], point))
        {
            if (typeIncludesKeysOtherThanKey(kECItemViewAreaKey))
            {
                if (typeIncludesKey(kECItemViewAreaHeaderKey))
                    if (CGRectContainsPoint([self _rectForAreaHeaderAtIndex:i], point))
                        return indexPathAndType([NSIndexPath indexPathForArea:i], kECItemViewAreaHeaderKey);
                if (typeIncludesKeysOtherThanKey(kECItemViewAreaHeaderKey))
                {
                    NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:i];
                    for (NSUInteger j = 0; j < numGroups; ++j)
                        if (CGRectContainsPoint([self _rectForGroupAtIndex:j inArea:i], point))
                        {
                            if (typeIncludesKeysOtherThanKey(kECItemViewGroupKey))
                            {
                                if (typeIncludesKey(kECItemViewGroupSeparatorKey))
                                    if (CGRectContainsPoint([self _rectForGroupSeparatorAtIndex:j inArea:i], point))
                                        return indexPathAndType([NSIndexPath indexPathForGroup:j inArea:i], kECItemViewGroupSeparatorKey);
                                if (typeIncludesKeysOtherThanKey(kECItemViewGroupSeparatorKey))
                                {
                                    NSUInteger numItems = [self _numberOfItemsInGroup:j inArea:i];
                                    for (NSUInteger k = 0; k < numItems; ++k)
                                        if (CGRectContainsPoint([self _rectForItemAtIndex:k inGroup:j inArea:i], point))
                                            if (typeIncludesKey(kECItemViewItemKey))
                                                return indexPathAndType([NSIndexPath indexPathForItem:k inGroup:j inArea:i], kECItemViewItemKey);
                                }
                            }
                            if (typeIncludesKey(kECItemViewGroupKey))
                                return indexPathAndType([NSIndexPath indexPathForGroup:j inArea:i], kECItemViewGroupKey);
                        }
                }
            }
            if (typeIncludesKey(kECItemViewAreaKey))
                return indexPathAndType([NSIndexPath indexPathForArea:i], kECItemViewAreaKey);
        }
    return nil;
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
    
    NSMutableDictionary *areaHeadersToInsert = [NSMutableDictionary dictionary];
    NSMutableArray *areaHeadersToDelete = [NSMutableArray array];
//    NSMutableArray *areaHeadersToLoad = [NSMutableArray array];
//    NSMutableArray *areaHeadersToUnload = [NSMutableArray array];
    NSMutableDictionary *groupSeparatorsToInsert = [NSMutableDictionary dictionary];
    NSMutableArray *groupSeparatorsToDelete = [NSMutableArray array];
//    NSMutableArray *groupSeparatorsToLoad = [NSMutableArray array];
//    NSMutableArray *groupSeparatorsToUnload = [NSMutableArray array];
    NSMutableDictionary *itemsToInsert = [NSMutableDictionary dictionary];
    NSMutableArray *itemsToDelete = [NSMutableArray array];
//    NSMutableArray *itemsToLoad = [NSMutableArray array];
//    NSMutableArray *itemsToUnload = [NSMutableArray array];
    
    void (^deleteItemInGroupInArea)(NSUInteger, NSUInteger, NSUInteger) = ^(NSUInteger item, NSUInteger group, NSUInteger area)
    {
        ECItemViewElement *itemView = [[[[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] children] objectAtIndex:item] object];
        if (itemView)
            [itemsToDelete addObject:itemView];
        [[[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] children] removeObjectAtIndex:item];
    };
    
    void (^deleteGroupInArea)(NSUInteger, NSUInteger) = ^(NSUInteger group, NSUInteger area)
    {
        ECItemViewElement *groupSeparator = [[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] object];
        if (groupSeparator)
            [groupSeparatorsToDelete addObject:groupSeparator];
        NSUInteger numItems = [self _numberOfItemsInGroup:group inArea:area];
        for (NSUInteger item = 0; item < numItems; ++item)
            deleteItemInGroupInArea(item, group, area);
        [[[_elements.children objectAtIndex:area] children] removeObjectAtIndex:group];
    };
    
    void (^deleteArea)(NSUInteger) = ^(NSUInteger area)
    {
        ECItemViewElement *areaHeader = [[_elements.children objectAtIndex:area] object];
        if (areaHeader)
            [areaHeadersToDelete addObject:areaHeader];
        NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:area];
        for (NSUInteger group = 0; group < numGroups; ++group)
            deleteGroupInArea(group, area);
        [_elements.children removeObjectAtIndex:area];
    };
    
    void (^insertItemInGroupInArea)(NSUInteger, NSUInteger, NSUInteger) = ^(NSUInteger item, NSUInteger group, NSUInteger area)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inGroup:group inArea:area];
        ECItemViewElement *itemView = [self _loadItemAtIndexPath:indexPath];
        if (itemView)
            [itemsToInsert setObject:itemView forKey:indexPath];
        [[[[[_elements.children objectAtIndex:area] children] objectAtIndex:group] children] insertObject:[ECMutableArrayTree nodeWithObject:itemView] atIndex:item];
    };
    
    void (^insertGroupInArea)(NSUInteger, NSUInteger) = ^(NSUInteger group, NSUInteger area)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForGroup:group inArea:area];
        ECItemViewElement *groupSeparator = [self _loadGroupSeparatorAtIndexPath:indexPath];
        if (groupSeparator)
            [groupSeparatorsToInsert setObject:groupSeparator forKey:indexPath];
        [[[_elements.children objectAtIndex:area] children] insertObject:[ECMutableArrayTree nodeWithObject:groupSeparator] atIndex:group];
        NSUInteger numItems = 0;
        if (_dataSource && _flags.dataSourceNumberOfItemsInGroup)
            numItems = [_dataSource itemView:self numberOfItemsInGroupAtIndexPath:indexPath];
        for (NSUInteger item = 0; item < numItems; ++item)
            insertItemInGroupInArea(item, group, area);
    };
    
    void (^insertArea)(NSUInteger) = ^(NSUInteger area)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForArea:area];
        ECItemViewElement *areaHeader = [self _loadAreaHeaderAtIndexPath:indexPath];
        if (areaHeader)
            [areaHeadersToInsert setObject:areaHeader forKey:indexPath];
        [_elements.children insertObject:[ECMutableArrayTree nodeWithObject:areaHeader] atIndex:area];
        NSUInteger numGroups = 0;
        if (_dataSource && _flags.dataSourceNumberOfGroupsInArea)
            numGroups = [_dataSource itemView:self numberOfGroupsInAreaAtIndexPath:indexPath];
        for (NSUInteger group = 0; group < numGroups; ++group)
            insertGroupInArea(group, area);
    };
    
    void (^unloadItemInGroupInArea)(NSUInteger, NSUInteger, NSUInteger) = ^(NSUInteger item, NSUInteger group, NSUInteger area)
    {
        
    };
    
    void (^unloadGroupInArea)(NSUInteger, NSUInteger) = ^(NSUInteger group, NSUInteger area)
    {
        
    };
    
    void (^unloadArea)(NSUInteger) = ^(NSUInteger area)
    {
        
    };
    
    void (^loadItemInGroupInArea)(NSUInteger, NSUInteger, NSUInteger) = ^(NSUInteger item, NSUInteger group, NSUInteger area)
    {
        
    };
    
    void (^loadGroupInArea)(NSUInteger, NSUInteger) = ^(NSUInteger group, NSUInteger area)
    {
        
    };
    
    void (^loadArea)(NSUInteger) = ^(NSUInteger area)
    {
        
    };
    
    {
        NSIndexPath *indexPath;
        NSInteger areaOffset = 0;    
        NSUInteger numAreas = [self numberOfAreas];
        for (NSUInteger area = 0; area < numAreas; ++area)
        {
            BOOL didDeleteArea = NO;
            BOOL didInsertArea = NO;
            BOOL didReloadArea = NO;
            NSInteger groupOffset = 0;
            NSUInteger emptyGroups = 0;
            indexPath = [NSIndexPath indexPathForArea:area];
            if ([[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewAreaKey] containsObject:indexPath])
            {
                deleteArea(area + areaOffset);
                --areaOffset;
                didDeleteArea = YES;
            }
            if ([[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewAreaKey] containsObject:indexPath])
            {
                insertArea(area);
                ++areaOffset;
                didInsertArea = YES;
            }
            if (!didDeleteArea && [[[_batchUpdatingStores objectForKey:kECItemViewBatchReloadsKey] objectForKey:kECItemViewAreaKey] containsObject:indexPath])
            {
                unloadArea(area + areaOffset);
                loadArea(area);
                didReloadArea = YES;
            }
            if (didDeleteArea || didReloadArea)
                continue;
            NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:area + areaOffset];
            for (NSUInteger group = 0; group < numGroups; ++group)
            {
                BOOL didDeleteGroup = NO;
                BOOL didInsertGroup = NO;
                BOOL didReloadGroup = NO;
                NSInteger itemOffset = 0;
                indexPath = [NSIndexPath indexPathForGroup:group inArea:area];
                if (!didDeleteArea && [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewGroupKey] containsObject:indexPath])
                {
                    deleteGroupInArea(group + groupOffset, area + areaOffset);
                    --groupOffset;
                    didDeleteGroup = YES;
                }
                if (!didInsertArea && [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewGroupKey] containsObject:indexPath])
                {
                    insertGroupInArea(group - emptyGroups , area);
                    ++groupOffset;
                    didInsertGroup = YES;
                }
                if (!didDeleteArea && !didReloadArea && !didDeleteGroup && [[[_batchUpdatingStores objectForKey:kECItemViewBatchReloadsKey] objectForKey:kECItemViewGroupKey] containsObject:indexPath])
                {
                    unloadGroupInArea(group + groupOffset, area + areaOffset);
                    loadGroupInArea(group, area);
                    didReloadGroup = YES;
                }
                if (didDeleteGroup || didReloadGroup)
                    continue;
                NSUInteger numItems = [self _numberOfItemsInGroup:group + groupOffset inArea:area + areaOffset];
                for (NSUInteger item = 0; item < numItems; ++item)
                {
                    BOOL didDeleteItem = NO;
                    indexPath = [NSIndexPath indexPathForItem:item inGroup:group inArea:area];
                    if (!didDeleteArea && !didDeleteGroup && [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:kECItemViewItemKey] containsObject:indexPath])
                    {
                        deleteItemInGroupInArea(item + itemOffset, group + groupOffset, area + areaOffset);
                        --itemOffset;
                        didDeleteItem = YES;
                    }
                    if (!didInsertArea && !didInsertGroup && [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewItemKey] containsObject:indexPath])
                    {
                        insertItemInGroupInArea(item, group - emptyGroups, area);
                        ++itemOffset;
                    }
                    if (!didDeleteArea && !didReloadArea && !didDeleteGroup && !didReloadGroup && !didDeleteItem && [[[_batchUpdatingStores objectForKey:kECItemViewBatchReloadsKey] objectForKey:kECItemViewItemKey] containsObject:indexPath])
                    {
                        unloadItemInGroupInArea(item + itemOffset, group + groupOffset, area + areaOffset);
                        loadItemInGroupInArea(item, group, area);
                    }
                }
                NSUInteger extraInserts = 0;
                BOOL extraInsert = YES;
                while (extraInsert)
                {
                    indexPath = [NSIndexPath indexPathForItem:numItems + extraInserts inGroup:group inArea:area];
                    if (!didInsertArea && !didInsertGroup && [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewItemKey] containsObject:indexPath])
                        insertItemInGroupInArea(numItems + extraInserts, group - emptyGroups, area);
                    else
                        extraInsert = NO;
                    ++extraInserts;
                }
                if (![self _numberOfItemsInGroup:group + groupOffset inArea:area + areaOffset])
                {
                    deleteGroupInArea(group + groupOffset, area + areaOffset);
                    --groupOffset;
                    ++emptyGroups;
                }
            }
            NSUInteger extraInserts = 0;
            BOOL extraInsert = YES;
            while (extraInsert)
            {
                indexPath = [NSIndexPath indexPathForGroup:numGroups + extraInserts inArea:area];
                if (!didInsertArea && [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewGroupKey] containsObject:indexPath])
                    insertGroupInArea(numGroups + extraInserts, area);
                else
                    extraInsert = NO;
                ++extraInserts;
            }
        }
        NSUInteger extraInserts = 0;
        BOOL extraInsert = YES;
        while (extraInsert)
        {
            indexPath = [NSIndexPath indexPathForArea:numAreas + extraInserts];
            if ([[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:kECItemViewItemKey] containsObject:indexPath])
                insertArea(numAreas + extraInserts);
            else
                extraInsert = NO;
            ++extraInserts;
        }
    }
    _cachedAreaRectArea = NSUIntegerMax;
    _cachedGroupRectArea = NSUIntegerMax;
    _cachedGroupRectGroup = NSUIntegerMax;
    for (NSIndexPath *indexPath in [itemsToInsert allKeys])
    {
        ECItemViewElement *element = [itemsToInsert objectForKey:indexPath];
        element.frame = [self rectForItemAtIndexPath:indexPath];
        element.transform = CGAffineTransformMakeScale(0.1, 0.1);
        element.alpha = 0.0;
        [self addSubview:element];
        [self sendSubviewToBack:element];
    }
    for (NSIndexPath *indexPath in [groupSeparatorsToInsert allKeys])
    {
        ECItemViewElement *element = [groupSeparatorsToInsert objectForKey:indexPath];
        element.frame = [self rectForGroupSeparatorAtIndexPath:indexPath];
        element.transform = CGAffineTransformMakeScale(0.1, 0.1);
        element.alpha = 0.0;
        [self addSubview:element];
        [self sendSubviewToBack:element];
    }
    [UIView animateWithDuration:kECItemViewLongAnimationDuration animations:^(void) {
        for (NSIndexPath *indexPath in itemsToInsert)
        {
            ECItemViewElement *element = [itemsToInsert objectForKey:indexPath];
            element.transform = CGAffineTransformMakeScale(1.0, 1.0);
            element.alpha = 1.0;
        }
        for (NSIndexPath *indexPath in [groupSeparatorsToInsert allKeys])
        {
            ECItemViewElement *element = [groupSeparatorsToInsert objectForKey:indexPath];
            element.transform = CGAffineTransformMakeScale(1.0, 1.0);
            element.alpha = 1.0;
        }
        for (ECItemViewElement *element in itemsToDelete)
        {
            element.transform = CGAffineTransformMakeScale(0.1, 0.1);
            element.alpha = 0.0;
        }
        for (ECItemViewElement *element in groupSeparatorsToDelete)
        {
            element.transform = CGAffineTransformMakeScale(0.1, 0.1);
            element.alpha = 0.0;
        }
        [self _layoutElements];
    } completion:^(BOOL finished) {
        for (ECItemViewElement *element in groupSeparatorsToDelete)
            [element removeFromSuperview];
        for (ECItemViewElement *element in itemsToDelete)
            [element removeFromSuperview];
    }];
    if (!_isBatchUpdating)
        for (NSDictionary *dictionary in [_batchUpdatingStores allValues])
            for (NSMutableSet *set in [dictionary allValues])
                [set removeAllObjects];
    if (![self numberOfAreas])
        self.contentSize = CGSizeMake(0.0, 0.0);
    CGRect lastAreaFrame = [self _rectForAreaAtIndex:[self numberOfAreas] - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self setNeedsLayout];
}

- (void)_beginEndUpdatesIfNeededForBlock:(void (^)(void))block
{
    BOOL wrap = !_isBatchUpdating;
    if (wrap)
        [self beginUpdates];
    block();
    if (wrap)
        [self endUpdates];
}

- (void)insertElementsOfType:(ECItemViewElementKey)type atIndexPaths:(NSArray *)indexPaths
{
    if (![indexPaths count])
        return;
    [self _beginEndUpdatesIfNeededForBlock:^(void) {
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:type] addObjectsFromArray:indexPaths];
    }];
}

- (void)deleteElementsOfType:(ECItemViewElementKey)type atIndexPaths:(NSArray *)indexPaths
{
    if (![indexPaths count])
        return;
    [self _beginEndUpdatesIfNeededForBlock:^(void) {
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:type] addObjectsFromArray:indexPaths];
    }];
}

- (void)reloadElementsOfType:(ECItemViewElementKey)type atIndexPaths:(NSArray *)indexPaths
{
    if (![indexPaths count])
        return;
    [self _beginEndUpdatesIfNeededForBlock:^(void) {
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchReloadsKey] objectForKey:type] addObjectsFromArray:indexPaths];
    }];
}

- (void)moveElementsOfType:(ECItemViewElementKey)type atIndexPaths:(NSArray *)indexPaths toIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || ![indexPaths count])
        return;
    [self _beginEndUpdatesIfNeededForBlock:^(void) {
        [[[_batchUpdatingStores objectForKey:kECItemViewBatchDeletesKey] objectForKey:type] addObjectsFromArray:indexPaths];
        NSUInteger numIndexPaths = [indexPaths count];
        if (type == kECItemViewAreaKey)
            for (NSUInteger i = 0; i < numIndexPaths; ++i)
                [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:type] addObject:[NSIndexPath indexPathForArea:indexPath.area + i]];
        else if (type == kECItemViewGroupKey)
            for (NSUInteger i = 0; i < numIndexPaths; ++i)
                [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:type] addObject:[NSIndexPath indexPathForGroup:indexPath.group + i inArea:indexPath.area]];
        else if (type == kECItemViewItemKey)
            for (NSUInteger i = 0; i < numIndexPaths; ++i)
                [[[_batchUpdatingStores objectForKey:kECItemViewBatchInsertsKey] objectForKey:type] addObject:[NSIndexPath indexPathForItem:indexPath.item + i inGroup:indexPath.group inArea:indexPath.area]];
    }];
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
    [[_elements objectAtIndexPath:indexPath] setSelected:YES animated:YES];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    if (!indexPath)
        return;
    [_selectedItems removeObject:indexPath];
    [[_elements objectAtIndexPath:indexPath] setSelected:NO animated:YES];
}

- (void)deselectAllItemsAnimated:(BOOL)animated
{
    [_selectedItems removeAllObjects];
    for (ECItemViewElement *item in [_elements objectsAtDepth:kECItemViewItemDepth])
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
    return element;
}

#pragma mark -
#pragma mark UIView

- (void)_layoutElements
{
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        ECItemViewElement *areaHeader = [[_elements.children objectAtIndex:i] object];
        if (areaHeader)
            areaHeader.frame = [self _rectForAreaHeaderAtIndex:i];
        NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:i];
        for (NSUInteger j = 0; j < numGroups; ++j)
        {
            ECItemViewElement *groupSeparator = [[[[_elements.children objectAtIndex:i] children] objectAtIndex:j] object];
            if (groupSeparator)
                groupSeparator.frame = [self _rectForGroupSeparatorAtIndex:j inArea:i];
            NSUInteger numItems = [self _numberOfItemsInGroup:j inArea:i];
            for (NSUInteger k = 0; k < numItems; ++k)
            {
                ECItemViewElement *item = [[[[[[_elements.children objectAtIndex:i] children] objectAtIndex:j] children] objectAtIndex:k] object];
                if (item)
                    item.frame = [self _rectForItemAtIndex:k inGroup:j inArea:i];
            }
        }
    }
}

- (void)_layoutCaret
{
    if (!_isDragging)
        return;
    ECItemViewElementKey type = _caret.type;
    if (type == kECItemViewItemKey)
    {
        CGRect rect = [self rectForItemAtIndexPath:_caretIndexPath];
        rect.size. width = 10;
        rect.origin.x -= 5;
        _caret.frame = rect;
    }
    else if (type == kECItemViewAreaHeaderKey)
        _caret.frame = [self rectForAreaHeaderAtIndexPath:_caretIndexPath];
    else if (type == kECItemViewGroupSeparatorKey)
        _caret.frame = [self rectForGroupSeparatorAtIndexPath:_caretIndexPath];
    else if (type == kECItemViewAreaKey)
    {
        CGRect rect = [self _rectForAreaAtIndexPath:_caretIndexPath];
        rect.size.height = 10;
        rect.origin.y -= 5;
        _caret.frame = rect;
    }
    else if (type == kECItemViewGroupKey)
    {
        CGRect rect = [self _rectForGroupAtIndexPath:_caretIndexPath];
        rect.size.height = 10;
        rect.origin.y -= 5;
        _caret.frame = rect;
    }
    else
        _caret.frame = CGRectZero;
    [self bringSubviewToFront:_caret];
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
    {
        ECItemViewElementKey type = nil;
        [self _indexPathForElementAtPoint:[gestureRecognizer locationInView:self] type:&type];
        if (type == kECItemViewItemKey)
            return _flags.dataSourceMoveItem;
        else if (type == kECItemViewAreaHeaderKey)
            return _flags.dataSourceMoveArea;
        else if (type == kECItemViewGroupSeparatorKey)
            return _flags.dataSourceMoveGroup;
        else
            return NO;
    }
    if (_flags.superGestureRecognizerShouldBegin)
        return [super gestureRecognizerShouldBegin:gestureRecognizer];
    return YES;
}

- (void)_handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (![tapGestureRecognizer state] == UIGestureRecognizerStateEnded)
        return;
    ECItemViewElementKey type = nil;
    NSIndexPath *indexPath = [self _indexPathForElementAtPoint:[tapGestureRecognizer locationInView:self] type:&type];
    if (type != kECItemViewItemKey)
        return;
    if (![_selectedItems containsObject:indexPath])
    {
        [self selectItemAtIndexPath:indexPath animated:YES scrollPosition:ECItemViewScrollPositionNone];
        if (_flags.delegateDidSelectItem)
            [__delegate itemView:self didSelectItemAtIndexPath:indexPath];
    }
    else
    {
        [self deselectItemAtIndexPath:indexPath animated:YES];
        if (_flags.delegateDidDeselectItem)
            [__delegate itemView:self didDeselectItemAtIndexPath:indexPath];
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
    _draggedElementsType = nil;
    NSIndexPath *indexPath = [self _indexPathForElementAtPoint:_dragPoint type:&_draggedElementsType];
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
    _caret.type = _draggedElementsType;
}

- (void)_continueDrag
{
    if (_draggedElementsType == kECItemViewAreaKey)
    {
        [_caretIndexPath release];
        _caretIndexPath = [[self _indexPathForElementAtPoint:_dragPoint type:&_draggedElementsType] retain];
    }
    else if (_draggedElementsType == kECItemViewGroupKey)
    {
        ECItemViewElementKey type = nil;
        [_caretIndexPath release];
        _caretIndexPath = [[self _indexPathForElementAtPoint:_dragPoint type:&type] retain];
        if (type == kECItemViewAreaHeaderKey)
            type = kECItemViewAreaKey;
        else
            type = kECItemViewGroupKey;
        _caret.type = type;
    }
    else
    {
        ECItemViewElementKey type = nil;
        NSIndexPath *indexPath = [self _indexPathForElementAtPoint:_dragPoint type:&type];
        if (type == kECItemViewGroupKey)
        {
            type = kECItemViewItemKey;
            indexPath = [NSIndexPath indexPathForItem:[self numberOfItemsInGroupAtIndexPath:indexPath] inGroup:indexPath.group inArea:indexPath.area];
        }
        [_caretIndexPath release];
        _caretIndexPath = [indexPath retain];
        _caret.type = type;
    }
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
    NSArray *draggedElements = [_draggedElements allObjects];
    ECItemViewElementKey type = nil;
    NSIndexPath *indexPath = [self _indexPathForElementAtPoint:_dragPoint type:&type];
    NSIndexPath *previousItemIndexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inGroup:indexPath.group inArea:indexPath.area];
    while ([_draggedElements containsObject:previousItemIndexPath] && indexPath.item)
    {
        indexPath = previousItemIndexPath;
        previousItemIndexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inGroup:indexPath.group inArea:indexPath.area];
    }
    if (_draggedElementsType == kECItemViewItemKey)
    {
        NSUInteger offset = 0;
        [self beginUpdates];
        for (NSIndexPath *draggedIndexPath in draggedElements)
            if (draggedIndexPath.area == indexPath.area && draggedIndexPath.group == indexPath.group && draggedIndexPath.item < indexPath.item)
                ++offset;
        if (type == kECItemViewItemKey)
        {
            indexPath = [NSIndexPath indexPathForItem:indexPath.item - offset inGroup:indexPath.group inArea:indexPath.area];
            [_dataSource itemView:self moveItemsAtIndexPaths:draggedElements toIndexPath:indexPath];
            [self moveElementsOfType:kECItemViewItemKey atIndexPaths:draggedElements toIndexPath:indexPath];
        }
        else if (type == kECItemViewGroupKey)
        {
            indexPath = [NSIndexPath indexPathForItem:[self numberOfItemsInGroupAtIndexPath:indexPath] - offset inGroup:indexPath.group inArea:indexPath.area];
            [_dataSource itemView:self moveItemsAtIndexPaths:draggedElements toIndexPath:indexPath];
            [self moveElementsOfType:kECItemViewItemKey atIndexPaths:draggedElements toIndexPath:indexPath];
        }
        else if (type == kECItemViewAreaHeaderKey || type == kECItemViewGroupSeparatorKey)
        {
            [self deleteElementsOfType:kECItemViewItemKey atIndexPaths:draggedElements];
            if (type == kECItemViewGroupSeparatorKey)
                indexPath = [NSIndexPath indexPathForGroup:indexPath.group + 1 inArea:indexPath.area];
            else
                indexPath = [NSIndexPath indexPathForGroup:0 inArea:indexPath.area];
            [_dataSource itemView:self moveItemsAtIndexPaths:draggedElements toIndexPath:indexPath];
            [self insertElementsOfType:kECItemViewGroupKey atIndexPaths:[NSArray arrayWithObject:indexPath]];
        }
        NSUInteger numAreas = [self numberOfAreas];
        NSMutableArray *array = [NSMutableArray array];
        for (NSUInteger i = 0; i < numAreas; ++i)
        {
            NSUInteger numGroups = [self _numberOfGroupsInAreaAtIndex:i];
            for (NSUInteger j = 0; j < numGroups; --j)
                if (![self _numberOfItemsInGroup:j inArea:i])
                    [array addObject:[NSIndexPath indexPathForGroup:j inArea:i]];
        }
        [self deleteElementsOfType:kECItemViewGroupKey atIndexPaths:array];
        [self endUpdates];
    }
}

- (void)_cancelDrag
{
    _isDragging = NO;
    [_caret removeFromSuperview];
    // TODO: do not do this if cancel is called after a successful drag
    // TODO: clear selected items if they were dragged ? (the indexPaths point to the wrong items)
//    for (NSIndexPath *indexPath in _draggedElements)
//    {
//        ECItemViewElement *element = [_elements objectAtIndexPath:indexPath];
//        element.dragged = NO;
//    }
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

+ (NSIndexPath *)indexPathForItem:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [self indexPathWithIndexes:(NSUInteger[3]){area, group, item} length:3];
}

+ (NSIndexPath *)indexPathForGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [self indexPathWithIndexes:(NSUInteger[2]){area, group} length:2];
}

+ (NSIndexPath *)indexPathForArea:(NSUInteger)area
{
    return [self indexPathWithIndex:area];
}

@end
