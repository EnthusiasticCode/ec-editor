//
//  ECItemView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECItemView.h"
#import "ECItemViewCell.h"
#import <ECUIKit/UIView+ConcurrentAnimation.h>
#import <ECFoundation/ECStackCache.h>
#import <ECFoundation/NSIndexPath+FixedIsEqual.h>

const CGFloat ECItemViewShortAnimationDuration = 0.15;
const NSUInteger ECItemViewCellBufferSize = 10;
const NSUInteger ECItemViewHeaderBufferSize = 5;
const NSUInteger ECItemViewGroupSeparatorBufferSize = 20;

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
        unsigned int dataSourceNumberOfItemsInGroupInArea:1;
        unsigned int dataSourceCellForItemAtIndexPath:1;
        unsigned int dataSourceNumberOfAreasInTableView:1;
        unsigned int dataSourceNumberOfGroupsInArea:1;
        unsigned int dataSourceTitleForHeaderInArea:1;
        unsigned int dataSourceCanEditItem:1;
        unsigned int dataSourceCanMoveItem:1;
        unsigned int dataSourceDeleteItem:1;
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
    BOOL _isAnimating;
    NSMutableArray *_areas;
    NSMutableArray *_headerTitles;
    ECStackCache *_headerCache;
    ECStackCache *_groupSeparatorCache;
    ECStackCache *_cellCache;
    NSMutableDictionary *_visibleCells;
    NSMutableDictionary *_visibleHeaders;
    NSMutableDictionary *_visibleSeparators;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    BOOL _isDragging;
    ECItemViewCell *_draggedItem;
    NSIndexPath *_draggedItemIndexPath;
    NSIndexPath *_dragDestinationIndexPath;
    NSTimer *_scrollTimer;
    CGFloat _scrollSpeed;
    UIEdgeInsets _scrollingHotspots;
}
- (void)_setup;

- (UIView *)_blankHeader:(ECStackCache *)cache;
- (UIView *)_groupSeparator:(ECStackCache *)cache;
- (ECItemViewCell *)_loadCellForItemAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)_heightForGroup:(NSUInteger)group inArea:(NSUInteger)area;
- (CGRect)_rectForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexSet *)_indexesForVisibleAreas;
- (NSIndexSet *)_indexesForVisibleHeaders;
- (NSArray *)_indexPathsForVisibleGroups;
- (NSArray *)_indexPathsForVisibleGroupSeparators;

- (NSIndexPath *)_proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists;

- (void)_layoutHeaders;
- (void)_layoutGroupSeparators;
- (void)_layoutCells;

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
@synthesize cellSize = _cellSize;
@synthesize cellInsets = _cellInsets;
@synthesize groupInsets = _groupInsets;
@synthesize groupSeparatorHeight = _groupSeparatorHeight;
@synthesize groupSeparatorInsets = _groupSeparatorInsets;
@synthesize groupSeparatorEditingHeight = _groupSeparatorEditingHeight;
@synthesize groupSeparatorEditingInsets = _groupSeparatorEditingInsets;
@synthesize headerHeight = _headerHeight;
@synthesize headerInsets = _headerInsets;
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
    _flags.dataSourceNumberOfGroupsInArea = [dataSource respondsToSelector:@selector(itemView:numberOfGroupsInArea:)];
    _flags.dataSourceNumberOfItemsInGroupInArea = [dataSource respondsToSelector:@selector(itemView:numberOfItemsInGroup:inArea:)];
    _flags.dataSourceCellForItemAtIndexPath = [dataSource respondsToSelector:@selector(itemView:cellForItemAtIndexPath:)];
    _flags.dataSourceNumberOfAreasInTableView = [dataSource respondsToSelector:@selector(numberOfAreasInTableView:)];
    _flags.dataSourceTitleForHeaderInArea = [dataSource respondsToSelector:@selector(itemView:titleForHeaderInArea:)];
    _flags.dataSourceCanEditItem = [dataSource respondsToSelector:@selector(itemView:canEditItemAtIndexPath:)];
    _flags.dataSourceCanMoveItem = [dataSource respondsToSelector:@selector(itemView:canMoveItemAtIndexPath:)];
    _flags.dataSourceDeleteItem = [dataSource respondsToSelector:@selector(itemView:deleteItemAtIndexPath:)];
    _flags.dataSourceMoveItem = [dataSource respondsToSelector:@selector(itemView:moveItemAtIndexPath:toIndexPath:)];
    _flags.dataSourceInsertGroup = [dataSource respondsToSelector:@selector(itemView:insertGroupAtIndexPath:)];
    _flags.dataSourceDeleteGroup = [dataSource respondsToSelector:@selector(itemView:deleteGroupAtIndexPath:)];
    _flags.dataSourceMoveGroup = [dataSource respondsToSelector:@selector(itemView:moveGroupAtIndexPath:toIndexPath:)];
    _flags.dataSourceMoveArea = [dataSource respondsToSelector:@selector(itemView:moveAreaAtIndexPath:toIndexPath:)];
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
    if (animated)
    {
        [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:^(void) {
            [self layoutIfNeeded];
        } completion:NULL];
    }
    CGRect lastAreaFrame = [self rectForArea:[self numberOfAreas] - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self didChangeValueForKey:@"editing"];   
}

- (void)_setup
{
    _cellSize = CGSizeMake(170.0, 80.0);
    _cellInsets = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
    _groupInsets = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
    _groupSeparatorHeight = 30.0;
    _groupSeparatorInsets = UIEdgeInsetsZero;
    _groupSeparatorEditingHeight = 90.0;
    _groupSeparatorEditingInsets = UIEdgeInsetsZero;
    _headerInsets = UIEdgeInsetsMake(20.0, 10.0, 20.0, 10.0);
    _headerHeight = 60.0;
    _headerCache = [[ECStackCache alloc] initWithTarget:self action:@selector(_blankHeader:) size:ECItemViewHeaderBufferSize];
    _groupSeparatorCache = [[ECStackCache alloc] initWithTarget:self action:@selector(_groupSeparator:) size:ECItemViewGroupSeparatorBufferSize];
    _cellCache = [[ECStackCache alloc] initWithTarget:nil action:NULL size:ECItemViewCellBufferSize];
    _visibleCells = [[NSMutableDictionary alloc] init];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapGesture:)];
    _tapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_tapGestureRecognizer];
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleLongPressGesture:)];
    _longPressGestureRecognizer.minimumPressDuration = 0.5;
    _longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longPressGestureRecognizer];
    UIScrollView *scrollView = [[[UIScrollView alloc] init] autorelease];
    _flags.superGestureRecognizerShouldBegin = [scrollView respondsToSelector:@selector(gestureRecognizerShouldBegin:)];
    _flags.superGestureRecognizerShouldRecognizeSimultaneously = [scrollView respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)];
    _flags.superGestureRecognizerShouldReceiveTouch = [scrollView respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)];
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
    [_headerTitles release];
    [_headerCache release];
    [_groupSeparatorCache release];
    [_cellCache release];
    [_visibleHeaders release];
    [_visibleSeparators release];
    [_visibleCells release];
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
    NSUInteger numAreas = 1;
    if (_flags.dataSourceNumberOfAreasInTableView)
        numAreas = [_dataSource numberOfAreasInTableView:self];
    [_areas release];
    _areas = [[NSMutableArray alloc] init];
    [_headerTitles release];
    _headerTitles = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        NSString *headerTitle = @"";
        if (_flags.dataSourceTitleForHeaderInArea)
            headerTitle = [_dataSource itemView:self titleForHeaderInArea:i];
        [_headerTitles addObject:headerTitle];
        NSUInteger numGroups = 1;
        if (_flags.dataSourceNumberOfGroupsInArea)
            numGroups = [_dataSource itemView:self numberOfGroupsInArea:i];
        NSMutableArray *groups = [NSMutableArray arrayWithCapacity:numGroups];
        for (NSUInteger j = 0; j < numGroups; ++j)
        {
            NSUInteger numItems = 0;
            if (_flags.dataSourceNumberOfItemsInGroupInArea)
                numItems = [_dataSource itemView:self numberOfItemsInGroup:j inArea:i];
            [groups addObject:[NSNumber numberWithUnsignedInteger:numItems]];
        }
        [_areas addObject:groups];
    }
    CGRect lastAreaFrame = [self rectForArea:[self numberOfAreas] - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self setNeedsLayout];
}

- (UIView *)_blankHeader:(ECStackCache *)cache
{
    UILabel *header = [[[UILabel alloc] init] autorelease];
    header.backgroundColor = [UIColor blueColor];
    return header;
}

- (UIView *)_groupSeparator:(ECStackCache *)cache
{
    UIView *groupSeparator = [[[UIView alloc] init] autorelease];
    groupSeparator.backgroundColor = [UIColor blackColor];
    return groupSeparator;
}

- (ECItemViewCell *)_loadCellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceCellForItemAtIndexPath)
        return nil;
    ECItemViewCell * cell = [_dataSource itemView:self cellForItemAtIndexPath:indexPath];
    return cell;
}

#pragma mark -
#pragma mark Info

- (NSUInteger)columns
{
    CGFloat netWidth = self.bounds.size.width - _groupInsets.left - _groupInsets.right;
    return netWidth / _cellSize.width;
}

- (NSUInteger)rowsInGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    NSUInteger numCells = [self numberOfItemsInGroup:group inArea:area];
    return ceil((CGFloat)numCells / (CGFloat)[self columns]);
}

- (NSUInteger)numberOfAreas
{
    return [_areas count];
}

- (NSUInteger)numberOfGroupsInArea:(NSUInteger)area
{
    return [[_areas objectAtIndex:area] count];
}

- (NSUInteger)numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [[[_areas objectAtIndex:area] objectAtIndex:group] unsignedIntegerValue];
}

#pragma mark -
#pragma mark Geometry

- (CGRect)rectForArea:(NSUInteger)area
{
    CGFloat x = 0;
    CGFloat y = 0;
    static NSUInteger cachedArea = NSUIntegerMax;
    static BOOL cachedIsEditing;
    static CGRect cachedAreaRect;
    if (area == cachedArea && _isEditing == cachedIsEditing)
        return cachedAreaRect;
    if (area)
    {
        CGRect previousAreaRect = [self rectForArea:area - 1];
        y = previousAreaRect.origin.y + previousAreaRect.size.height;
    }
    CGFloat width = self.bounds.size.width;
    CGFloat height = _headerHeight;
    NSUInteger numGroups = [self numberOfGroupsInArea:area];
    for (NSUInteger j = 0; j < numGroups; ++j)
        height += [self _heightForGroup:j inArea:area];
    cachedArea = area;
    cachedIsEditing = _isEditing;
    cachedAreaRect = CGRectMake(x, y, width, height);
    return cachedAreaRect;
}

- (CGFloat)_heightForGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    CGFloat height = 0;
    height += [self rowsInGroup:group inArea:area] * _cellSize.height;
    height += _groupInsets.top + _groupInsets.bottom;
    if (_isEditing)
        height += _groupSeparatorEditingHeight;
    else
        height += _groupSeparatorHeight;
    return height;
}

- (CGRect)_rectForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect groupRect = [self rectForGroup:indexPath.position inArea:indexPath.area];
    CGFloat x = groupRect.origin.x + _groupInsets.left;
    CGFloat y = groupRect.origin.y + groupRect.size.height - _groupInsets.bottom;
    CGFloat width = groupRect.size.width - _groupInsets.left - _groupInsets.right;
    CGFloat height;
    if (_isEditing)
    {
        y -= _groupSeparatorEditingHeight;
        height = _groupSeparatorEditingHeight;
    }
    else
    {
        y -= _groupSeparatorHeight;
        height = _groupSeparatorHeight;
    }
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForHeaderInArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    return CGRectMake(areaRect.origin.x, areaRect.origin.y, self.bounds.size.width - _headerInsets.left - _headerInsets.right, _headerHeight);
}

- (CGRect)rectForGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    static NSUInteger cachedGroup = NSUIntegerMax;
    static NSUInteger cachedArea = NSUIntegerMax;
    static BOOL cachedIsEditing;
    static CGRect cachedGroupRect;
    if (group == cachedGroup && area == cachedArea && _isEditing == cachedIsEditing)
        return cachedGroupRect;
    CGRect areaRect = [self rectForArea:area];
    CGFloat x = areaRect.origin.x;
    CGFloat y = areaRect.origin.y + _headerHeight;
    for (NSUInteger i = 0; i < group; ++i)
    {
        y += [self _heightForGroup:i inArea:area];
        if (_isEditing)
            y += _groupSeparatorEditingHeight;
        else
            y += _groupSeparatorHeight;
    }
    CGFloat width = areaRect.size.width;
    CGFloat height = [self _heightForGroup:group inArea:area];
    cachedArea = area;
    cachedGroup = group;
    cachedIsEditing = _isEditing;
    cachedGroupRect = CGRectMake(x, y, width, height);
    return cachedGroupRect;
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSUInteger cachedItem = NSUIntegerMax;
    static NSUInteger cachedGroup = NSUIntegerMax;
    static NSUInteger cachedArea = NSUIntegerMax;
    static BOOL cachedIsEditing;
    static CGRect cachedItemRect;
    if (!indexPath)
        return CGRectZero;
    if (indexPath.item == cachedItem && indexPath.group == cachedGroup && indexPath.area == cachedArea && _isEditing == cachedIsEditing)
        return cachedItemRect;
    CGFloat x = 0;
    CGFloat y = 0;
    if (indexPath.group == cachedGroup && indexPath.area == cachedArea)
    {
        NSInteger cachedItemRow = cachedItem / [self columns];
        NSInteger cachedItemColumn = cachedItem % [self columns];
        NSInteger itemRow = indexPath.item / [self columns];
        NSInteger itemColumn = indexPath.item % [self columns];
        x = cachedItemRect.origin.x + (itemColumn - cachedItemColumn) * _cellSize.width;
        y = cachedItemRect.origin.y + (itemRow - cachedItemRow) * _cellSize.height;
        cachedItemRect = CGRectMake(x, y, cachedItemRect.size.width, cachedItemRect.size.height);
    }
    else
    {
        CGRect groupRect = [self rectForGroup:indexPath.group inArea:indexPath.area];
        x = groupRect.origin.x;
        y = groupRect.origin.y;
        NSUInteger row = indexPath.item / [self columns];
        NSUInteger column = indexPath.item % [self columns];
        x += column * _cellSize.width;
        y += row * _cellSize.height;
        cachedItemRect = CGRectMake(x, y, _cellSize.width, _cellSize.height);
    }
    cachedArea = indexPath.area;
    cachedGroup = indexPath.group;
    cachedItem = indexPath.item;
    cachedIsEditing = _isEditing;
    return cachedItemRect;
}

#pragma mark -
#pragma mark Index paths

- (NSIndexSet *)_indexesForVisibleAreas
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfAreas])];
    return [indexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return CGRectIntersectsRect(self.bounds, [self rectForArea:idx]);
    }];
}

- (NSIndexSet *)_indexesForVisibleHeaders
{
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [self numberOfAreas])];
    return [indexes indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return CGRectIntersectsRect(self.bounds, [self rectForHeaderInArea:idx]);
    }];
}

- (NSArray *)_indexPathsForVisibleGroups
{
    NSIndexSet *indexes = [self _indexesForVisibleAreas];
    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSUInteger numGroups = [self numberOfGroupsInArea:idx];
        for (NSUInteger i = 0; i < numGroups; ++i)
            if (CGRectIntersectsRect(self.bounds, [self rectForGroup:i inArea:idx]))
                [indexPaths addObject:[NSIndexPath indexPathForPosition:i inArea:idx]];
    }];
    return indexPaths;
}

- (NSArray *)_indexPathsForVisibleGroupSeparators
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSIndexPath *indexPath in [self _indexPathsForVisibleGroups])
        if (CGRectIntersectsRect(self.bounds, [self _rectForGroupSeparatorAtIndexPath:indexPath]))
            [indexPaths addObject:indexPath];
    return indexPaths;
}

- (NSArray *)indexPathsForVisibleItems
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSIndexPath *groupIndexPath in [self _indexPathsForVisibleGroups])
    {
        NSUInteger numItems = [self numberOfItemsInGroup:groupIndexPath.position inArea:groupIndexPath.area];
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

- (NSArray *)visibleCells
{
    return [_visibleCells allValues];
}

- (ECItemViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath)
        return nil;
    return [_visibleCells objectForKey:indexPath];
}

- (NSIndexPath *)indexPathForCell:(ECItemViewCell *)cell
{
    if (!cell)
        return nil;
    for (NSIndexPath *indexPath in [_visibleCells allKeys])
        if ([_visibleCells objectForKey:indexPath] == cell)
            return indexPath;
    return nil;
}

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
    BOOL exists;
    NSIndexPath *indexPath = [self _proposedIndexPathForItemAtPoint:point exists:&exists];
    if (!exists)
        return nil;
    return indexPath;
}

- (NSIndexPath *)_proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists
{
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        CGRect areaRect = CGRectZero;
        areaRect = [self rectForArea:i];
        if (!CGRectContainsPoint(areaRect, point))
            continue;
        NSUInteger numGroups = [self numberOfGroupsInArea:i];
        for (NSUInteger j = 0; j < numGroups; ++j)
        {
            CGRect groupRect = CGRectZero;
            groupRect = [self rectForGroup:j inArea:i];
            if (!CGRectContainsPoint(UIEdgeInsetsInsetRect(groupRect, _groupInsets), point))
                continue;
            NSUInteger numItems = [self numberOfItemsInGroup:j inArea:i];
            for (NSUInteger k = 0; k < numItems; )
            {
                CGRect itemRect = CGRectZero;
                itemRect = [self rectForItemAtIndexPath:[NSIndexPath indexPathForItem:k inGroup:j inArea:i]];
                if (CGRectContainsPoint(itemRect, point))
                {
                    if (exists)
                        *exists = YES;
                    return [NSIndexPath indexPathForItem:k inGroup:j inArea:i];
                }
                if (itemRect.origin.y > point.y)
                    break;
                if (point.y > itemRect.origin.y + itemRect.size.height)
                    k += [self columns];
                else
                    ++k;
            }
            if (exists)
                *exists = NO;
            return [NSIndexPath indexPathForItem:numItems inGroup:j inArea:i];
        }
        for (NSUInteger j = 0; j < numGroups; ++j)
            if (CGRectContainsPoint([self _rectForGroupSeparatorAtIndexPath:[NSIndexPath indexPathForPosition:j inArea:i]], point))
            {
                if (exists)
                    *exists = NO;
                return [NSIndexPath indexPathForItem:0 inGroup:j inArea:i];
            }
    }
    if (exists)
        *exists = NO;
    return nil;
}

#pragma mark -
#pragma mark Item insertion/deletion/reloading



#pragma mark -
#pragma mark Recycling

- (ECItemViewCell *)dequeueReusableCell
{
    if (![_cellCache count])
        return nil;
    return [_cellCache pop];
}

#pragma mark -
#pragma mark UIView

- (void)_layoutHeaders
{
    NSMutableDictionary *newVisibleHeaders = [[NSMutableDictionary alloc] init];
    [[self _indexesForVisibleHeaders] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        UILabel *header = [_visibleHeaders objectForKey:[NSNumber numberWithUnsignedInteger:idx]];
        if (header)
            [_visibleHeaders removeObjectForKey:[NSNumber numberWithUnsignedInteger:idx]];
        else
        {
            header = [_headerCache pop];
            [self addSubview:header];
            [self sendSubviewToBack:header];
            header.text = [_headerTitles objectAtIndex:idx];
        }
        header.frame = UIEdgeInsetsInsetRect([self rectForHeaderInArea:idx], _headerInsets);
        [newVisibleHeaders setObject:header forKey:[NSNumber numberWithUnsignedInteger:idx]];
    }];
    for (UILabel *header in [_visibleHeaders allValues])
    {
        [header removeFromSuperview];
        [_headerCache push:header];
    }
    [_visibleHeaders release];
    _visibleHeaders = newVisibleHeaders;
}

- (void)_layoutGroupSeparators
{
    NSMutableDictionary *newVisibleGroupSeparators = [[NSMutableDictionary alloc] init];
    for (NSIndexPath *indexPath in [self _indexPathsForVisibleGroupSeparators])
    {
        UIView *separator = [_visibleSeparators objectForKey:indexPath];
        if (separator)
            [_visibleSeparators removeObjectForKey:indexPath];
        else
        {
            separator = [_groupSeparatorCache pop];
            [self addSubview:separator];
            [self sendSubviewToBack:separator];
        }
        separator.frame = UIEdgeInsetsInsetRect([self _rectForGroupSeparatorAtIndexPath:indexPath], _groupSeparatorInsets);
        [newVisibleGroupSeparators setObject:separator forKey:indexPath];
    }
    for (UIView *separator in [_visibleSeparators allValues])
    {
        [separator removeFromSuperview];
        [_groupSeparatorCache push:separator];
    }
    [_visibleSeparators release];
    _visibleSeparators = newVisibleGroupSeparators;
}

- (void)_layoutCells
{
    NSMutableDictionary *newVisibleItems = [[NSMutableDictionary alloc] init];
    for (NSIndexPath *indexPath in [self indexPathsForVisibleItems])
    {
        if (_isDragging && [indexPath isEqual:_draggedItemIndexPath])
            continue;
        ECItemViewCell *cell = [_visibleCells objectForKey:indexPath];
        if (cell)
            [_visibleCells removeObjectForKey:indexPath];
        else
        {
            cell = [self _loadCellForItemAtIndexPath:indexPath];
            [self addSubview:cell];
            [self sendSubviewToBack:cell];
        }
        [newVisibleItems setObject:cell forKey:indexPath];
        if (_isDragging && _draggedItemIndexPath && indexPath.group == _draggedItemIndexPath.group && indexPath.area == _draggedItemIndexPath.area && indexPath.item > _draggedItemIndexPath.item)
            indexPath = [NSIndexPath indexPathForItem:indexPath.item - 1 inGroup:indexPath.group inArea:indexPath.area];
        if (_isDragging && _dragDestinationIndexPath && indexPath.group == _dragDestinationIndexPath.group && indexPath.area == _dragDestinationIndexPath.area && indexPath.item >= _dragDestinationIndexPath.item)
            indexPath = [NSIndexPath indexPathForItem:indexPath.item + 1 inGroup:indexPath.group inArea:indexPath.area];
        cell.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:indexPath], _cellInsets);
    }
    for (ECItemViewCell *cell in [_visibleCells allValues])
    {
        if (_isDragging && cell == _draggedItem)
        {
            [newVisibleItems setObject:cell forKey:_draggedItemIndexPath];
            continue;
        }
        [cell removeFromSuperview];
        [_cellCache push:cell];
    }
    [_visibleCells release];
    _visibleCells = newVisibleItems;
}

- (void)layoutSubviews
{
    [self _layoutHeaders];
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
        if (_flags.dataSourceCanMoveItem && [self indexPathForItemAtPoint:[gestureRecognizer locationInView:self]] && [_dataSource itemView:self canMoveItemAtIndexPath:[self indexPathForItemAtPoint:[gestureRecognizer locationInView:self]]])
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
    else
        [self _cancelDrag:longPressGestureRecognizer];
}

- (void)_beginDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _isDragging = YES;
    _draggedItemIndexPath = [[self indexPathForItemAtPoint:[dragRecognizer locationInView:self]] retain];
    _dragDestinationIndexPath = [_draggedItemIndexPath retain];
    _draggedItem = [self cellForItemAtIndexPath:_draggedItemIndexPath];
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
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:^(void) {
        [self layoutIfNeeded];
    } completion:NULL];
}

- (void)_endDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _isDragging = NO;
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    _dragDestinationIndexPath = [self _proposedIndexPathForItemAtPoint:[dragRecognizer locationInView:self] exists:NULL];
    if (_flags.dataSourceMoveItem)
        [_dataSource itemView:self moveItemAtIndexPath:_draggedItemIndexPath toIndexPath:_dragDestinationIndexPath];
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:^(void) {
        _draggedItem.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:_dragDestinationIndexPath], _cellInsets);
    } completion:NULL];
    [_draggedItemIndexPath release];
    _draggedItemIndexPath = nil;
    [_dragDestinationIndexPath release];
    _dragDestinationIndexPath = nil;
    _draggedItem = nil;
}

- (void)_cancelDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _isDragging = NO;
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    [self setNeedsLayout];
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECItemViewShortAnimationDuration animations:^(void) {
        _draggedItem.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:_draggedItemIndexPath], _cellInsets);
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
