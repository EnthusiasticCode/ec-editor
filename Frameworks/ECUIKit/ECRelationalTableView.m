//
//  ECRelationalTableView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECRelationalTableView.h"
#import "ECRelationalTableViewCell.h"
#import <ECUIKit/UIView+ConcurrentAnimation.h>
#import <ECFoundation/ECStackCache.h>
#import <ECFoundation/NSIndexPath+FixedIsEqual.h>

const CGFloat ECRelationalTableViewShortAnimationDuration = 0.15;
const NSUInteger ECRelationalTableViewCellBufferSize = 10;
const NSUInteger ECRelationalTableViewHeaderBufferSize = 5;
const NSUInteger ECRelationalTableViewGroupSeparatorBufferSize = 20;
const NSUInteger ECRelationalTableViewGroupPlaceholderBufferSize = 20;

@interface UIScrollView (MethodsInUIGestureRecognizerDelegateProtocolAppleCouldntBotherDeclaring)
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;
@end

@interface ECRelationalTableView ()
{
    @private
    struct {
        unsigned int superGestureRecognizerShouldBegin:1;
        unsigned int superGestureRecognizerShouldRecognizeSimultaneously:1;
        unsigned int superGestureRecognizerShouldReceiveTouch:1;
        unsigned int dataSourceNumberOfItemsInGroupInArea:1;
        unsigned int dataSourceCellForItemAtIndexPath:1;
        unsigned int dataSourceRelatedIndexPathsForItemAtIndexPath:1;
        unsigned int dataSourceNumberOfAreasInTableView:1;
        unsigned int dataSourceNumberOfGroupsInArea:1;
        unsigned int dataSourceTitleForHeaderInArea:1;
        unsigned int dataSourceCanEditItem:1;
        unsigned int dataSourceCanMoveItem:1;
        unsigned int dataSourceMoveItem:1;
        unsigned int delegateWillSelectItem:1;
        unsigned int delegateWillDeselectItem:1;
        unsigned int delegateDidSelectItem:1;
        unsigned int delegateDidDeselectItem:1;
        unsigned int delegateTargetIndexPathForMoveFromItem:1;
    } _flags;
    BOOL _isAnimating;
    NSMutableArray *_areas;
    NSMutableArray *_headerTitles;
    ECStackCache *_headerCache;
    ECStackCache *_groupSeparatorCache;
    ECStackCache *_groupPlaceholderCache;
    ECStackCache *_cellCache;
    NSMutableDictionary *_visibleCells;
    NSMutableDictionary *_visibleHeaders;
    NSMutableDictionary *_visibleSeparators;
    NSMutableDictionary *_visiblePlaceholders;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
    BOOL _isDragging;
    ECRelationalTableViewCell *_draggedItem;
    NSIndexPath *_draggedItemIndexPath;
    NSIndexPath *_dragDestinationIndexPath;
}
- (void)_setup;
- (UIView *)_blankHeader:(ECStackCache *)cache;
- (UIView *)_groupSeparator:(ECStackCache *)cache;
- (UIView *)_groupPlaceholder:(ECStackCache *)cache;
- (CGFloat)_heightForGroup:(NSUInteger)group inArea:(NSUInteger)area;
- (CGRect)_rectForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath;
- (CGRect)_rectForGroupPlaceholderAtIndexPath:(NSIndexPath *)indexPath;
- (CGPoint)_centerForHeaderInArea:(NSUInteger)area;
- (CGPoint)_centerForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath;
- (CGPoint)_centerForGroupPlaceholderAtIndexPath:(NSIndexPath *)indexPath;
- (CGPoint)_centerForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexSet *)_indexesForVisibleAreas;
- (NSIndexSet *)_indexesForVisibleHeaders;
- (NSArray *)_indexPathsForVisibleGroups;
- (NSArray *)_indexPathsForVisibleGroupSeparators;
- (NSArray *)_indexPathsForVisibleGroupPlaceholders;
- (ECRelationalTableViewCell *)loadCellForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)_proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists;
- (void)_layoutHeaders;
- (void)_layoutGroupSeparators;
- (void)_layoutGroupPlaceholders;
- (void)_layoutCells;
- (void)_handleTapGesture:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)_handlePanGesture:(UILongPressGestureRecognizer *)longPressGestureRecognizer;
- (void)_beginDrag:(UILongPressGestureRecognizer *)dragRecognizer;
- (void)_continueDrag:(UILongPressGestureRecognizer *)dragRecognizer;
- (void)_endDrag:(UILongPressGestureRecognizer *)dragRecognizer;
- (void)_cancelDrag:(UILongPressGestureRecognizer *)dragRecognizer;
@end

#pragma mark -

@implementation ECRelationalTableView

#pragma mark Properties and initialization

@synthesize delegate = __delegate;
@synthesize dataSource = _dataSource;
@synthesize tableInsets = _tableInsets;
@synthesize cellSize = _cellSize;
@synthesize cellInsets = _cellInsets;
@synthesize groupInsets = _groupInsets;
@synthesize groupSeparatorHeight = _groupSeparatorHeight;
@synthesize groupSeparatorInsets = _groupSeparatorInsets;
@synthesize groupPlaceholderHeight = _groupPlaceholderHeight;
@synthesize groupPlaceholderInsets = _groupPlaceholderInsets;
@synthesize headerHeight = _headerHeight;
@synthesize headerInsets = _headerInsets;
@synthesize allowsSelection = _allowsSelection;
@synthesize editing = _isEditing;

- (void)setDelegate:(id<ECRelationalTableViewDelegate>)delegate
{
    if (delegate == __delegate)
        return;
    [self willChangeValueForKey:@"delegate"];
    __delegate = delegate;
    _flags.delegateWillSelectItem = [delegate respondsToSelector:@selector(relationalTableView:willSelectItemAtIndexPath:)];
    _flags.delegateWillDeselectItem = [delegate respondsToSelector:@selector(relationalTableView:willDeselectItemAtIndexPath:)];
    _flags.delegateDidSelectItem = [delegate respondsToSelector:@selector(relationalTableView:didSelectItemAtIndexPath:)];
    _flags.delegateDidDeselectItem = [delegate respondsToSelector:@selector(relationalTableView:didDeselectItemAtIndexPath:)];
    _flags.delegateTargetIndexPathForMoveFromItem = [delegate respondsToSelector:@selector(relationalTableView:targetIndexPathForMoveFromItemAtIndexPath:toProposedIndexPath:)];
    [self didChangeValueForKey:@"delegate"];
}

- (void)setDataSource:(id<ECRelationalTableViewDataSource>)dataSource
{
    if (dataSource == _dataSource)
        return;
    [self willChangeValueForKey:@"dataSource"];
    _dataSource = dataSource;
    _flags.dataSourceNumberOfGroupsInArea = [dataSource respondsToSelector:@selector(relationalTableView:numberOfGroupsInArea:)];
    _flags.dataSourceNumberOfItemsInGroupInArea = [dataSource respondsToSelector:@selector(relationalTableView:numberOfItemsInGroup:inArea:)];
    _flags.dataSourceCellForItemAtIndexPath = [dataSource respondsToSelector:@selector(relationalTableView:cellForItemAtIndexPath:)];
    _flags.dataSourceRelatedIndexPathsForItemAtIndexPath = [dataSource respondsToSelector:@selector(relationalTableView:relatedIndexPathsForItemAtIndexPath:)];
    _flags.dataSourceNumberOfAreasInTableView = [dataSource respondsToSelector:@selector(numberOfAreasInTableView:)];
    _flags.dataSourceTitleForHeaderInArea = [dataSource respondsToSelector:@selector(relationalTableView:titleForHeaderInArea:)];
    _flags.dataSourceCanEditItem = [dataSource respondsToSelector:@selector(relationalTableView:canEditItemAtIndexPath:)];
    _flags.dataSourceCanMoveItem = [dataSource respondsToSelector:@selector(relationalTableView:canMoveItemAtIndexPath:)];
    _flags.dataSourceMoveItem = [dataSource respondsToSelector:@selector(relationalTableView:moveItemAtIndexPath:toIndexPath:)];
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
    if (editing)
    {
        for (UIView *separator in [_visibleSeparators allValues])
            [separator removeFromSuperview];
        [_visibleSeparators removeAllObjects];
    }
    else
    {
        for (UIView *placeholder in [_visiblePlaceholders allValues])
            [placeholder removeFromSuperview];
        [_visiblePlaceholders removeAllObjects];
    }
    if (animated)
    {
        [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECRelationalTableViewShortAnimationDuration animations:^(void) {
            [self layoutIfNeeded];
        } completion:NULL];
    }
    CGRect lastAreaFrame = [self rectForArea:[self numberOfAreas] - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self didChangeValueForKey:@"editing"];   
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
    [_groupPlaceholderCache release];
    [_cellCache release];
    [_visibleHeaders release];
    [_visibleSeparators release];
    [_visiblePlaceholders release];
    [_visibleCells release];
    [_tapGestureRecognizer release];
    [_longPressGestureRecognizer release];
    [_draggedItem release];
    [_draggedItemIndexPath release];
    [_dragDestinationIndexPath release];
    [super dealloc];
}

#pragma mark -
#pragma mark Private methods

- (void)_setup
{
    _tableInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    _cellSize = CGSizeMake(170.0, 80.0);
    _cellInsets = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
    _groupInsets = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
    _groupSeparatorInsets = UIEdgeInsetsZero;
    _headerInsets = UIEdgeInsetsMake(20.0, 10.0, 20.0, 10.0);
    _headerHeight = 60.0;
    _groupSeparatorHeight = 30.0;
    _groupPlaceholderHeight = 80.0;
    _groupPlaceholderInsets = UIEdgeInsetsZero;
    _headerCache = [[ECStackCache alloc] initWithTarget:self action:@selector(_blankHeader:) size:ECRelationalTableViewHeaderBufferSize];
    _groupSeparatorCache = [[ECStackCache alloc] initWithTarget:self action:@selector(_groupSeparator:) size:ECRelationalTableViewGroupSeparatorBufferSize];
    _groupPlaceholderCache =[[ECStackCache alloc] initWithTarget:self action:@selector(_groupPlaceholder:) size:ECRelationalTableViewGroupPlaceholderBufferSize];
    _cellCache = [[ECStackCache alloc] initWithTarget:nil action:NULL size:ECRelationalTableViewCellBufferSize];
    _visibleCells = [[NSMutableDictionary alloc] init];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapGesture:)];
    _tapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_tapGestureRecognizer];
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handlePanGesture:)];
    _longPressGestureRecognizer.minimumPressDuration = 0.5;
    _longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longPressGestureRecognizer];
    UIScrollView *scrollView = [[[UIScrollView alloc] init] autorelease];
    _flags.superGestureRecognizerShouldBegin = [scrollView respondsToSelector:@selector(gestureRecognizerShouldBegin:)];
    _flags.superGestureRecognizerShouldRecognizeSimultaneously = [scrollView respondsToSelector:@selector(gestureRecognizer:shouldRecognizeSimultaneouslyWithGestureRecognizer:)];
    _flags.superGestureRecognizerShouldReceiveTouch = [scrollView respondsToSelector:@selector(gestureRecognizer:shouldReceiveTouch:)];
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

- (UIView *)_groupPlaceholder:(ECStackCache *)cache
{
    UIView *groupPlaceholder = [[[UIView alloc] init] autorelease];
    groupPlaceholder.backgroundColor = [UIColor blackColor];
    return groupPlaceholder;
}

- (CGFloat)_heightForGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    CGFloat height = 0;
    height += [self rowsInGroup:group inArea:area] * _cellSize.height;
    height += _groupInsets.top + _groupInsets.bottom;
    return height;
}

- (CGRect)_rectForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    static NSUInteger cachedArea = NSUIntegerMax;
    static NSUInteger cachedPosition = NSUIntegerMax;
    static CGRect cachedSeparatorRect;
    if (cachedArea == indexPath.area && cachedPosition == indexPath.position)
        return cachedSeparatorRect;
    CGFloat y = 0;
    if (cachedArea == indexPath.area)
    {
        y = cachedSeparatorRect.origin.y;
        NSRange separatorRange;
        if (cachedPosition < indexPath.position)
            separatorRange = NSMakeRange( cachedPosition, indexPath.position - cachedPosition);
        else
            separatorRange = NSMakeRange(indexPath.position, cachedPosition - indexPath.position);
        NSRange groupsBetweenSeparatorsRange = NSMakeRange(separatorRange.location + 1, separatorRange.length - 1);
        for (NSUInteger i = groupsBetweenSeparatorsRange.location; i < groupsBetweenSeparatorsRange.location + groupsBetweenSeparatorsRange.length; ++i)
            y += [self _heightForGroup:i inArea:indexPath.area];
        y += (separatorRange.length - 1) * _groupSeparatorHeight;
    }
    else
    {
        y = [self rectForArea:indexPath.area].origin.y;
        for (NSUInteger i = 0; i < indexPath.position; ++i)
            y += [self _heightForGroup:i inArea:indexPath.area];
        if (indexPath.position > 1)
            y += (indexPath.position - 1) * _groupSeparatorHeight;
    }
    cachedArea = indexPath.area;
    cachedPosition = indexPath.position;
    cachedSeparatorRect = CGRectMake(_tableInsets.left, y, self.bounds.size.width - _tableInsets.left - _tableInsets.right - _groupSeparatorInsets.left - _groupSeparatorInsets.right, _groupSeparatorHeight);
    return cachedSeparatorRect;
}

- (CGRect)_rectForGroupPlaceholderAtIndexPath:(NSIndexPath *)indexPath
{
    static NSUInteger cachedArea = NSUIntegerMax;
    static NSUInteger cachedPosition = NSUIntegerMax;
    static CGRect cachedPlaceholderRect;
    if (cachedArea == indexPath.area && cachedPosition == indexPath.position)
        return cachedPlaceholderRect;
    CGFloat y = 0;
    if (cachedArea == indexPath.area)
    {
        y = cachedPlaceholderRect.origin.y;
        NSRange placeholderRange;
        if (cachedPosition < indexPath.position)
            placeholderRange = NSMakeRange( cachedPosition, indexPath.position - cachedPosition);
        else
            placeholderRange = NSMakeRange(indexPath.position, cachedPosition - indexPath.position);
        for (NSUInteger i = placeholderRange.location; i < placeholderRange.location + placeholderRange.length; ++i)
            y += [self _heightForGroup:i inArea:indexPath.area];
        y += (placeholderRange.length) * _groupPlaceholderHeight;
    }
    else
    {
        y = [self rectForArea:indexPath.area].origin.y + _headerHeight;
        for (NSUInteger i = 0; i < indexPath.position; ++i)
        {
            y += [self _heightForGroup:i inArea:indexPath.area];
        }
        if (indexPath.position > 0)
            y += (indexPath.position) * _groupPlaceholderHeight;
    }
    cachedArea = indexPath.area;
    cachedPosition = indexPath.position;
    cachedPlaceholderRect = CGRectMake(_tableInsets.left, y, self.bounds.size.width - _tableInsets.left - _tableInsets.right - _groupPlaceholderInsets.left - _groupPlaceholderInsets.right, _groupPlaceholderHeight);
    return cachedPlaceholderRect;
}

- (CGPoint)_centerForHeaderInArea:(NSUInteger)area
{
    CGRect rect = [self rectForHeaderInArea:area];
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

- (CGPoint)_centerForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect rect = [self _rectForGroupSeparatorAtIndexPath:indexPath];
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));    
}

- (CGPoint)_centerForGroupPlaceholderAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect rect = [self _rectForGroupPlaceholderAtIndexPath:indexPath];
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

- (CGPoint)_centerForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect rect = [self rectForItemAtIndexPath:indexPath];
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

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
    NSIndexSet *indexes = [self _indexesForVisibleAreas];
    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSUInteger numGroups = [self numberOfGroupsInArea:idx];
        for (NSUInteger i = 0; i < numGroups - 1; ++i)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForPosition:i inArea:idx];
            if (CGRectIntersectsRect(self.bounds, [self _rectForGroupSeparatorAtIndexPath:indexPath]))
                [indexPaths addObject:indexPath];
        }
    }];
    return indexPaths;
}

- (NSArray *)_indexPathsForVisibleGroupPlaceholders
{
    NSIndexSet *indexes = [self _indexesForVisibleAreas];
    NSMutableArray *indexPaths = [NSMutableArray array];
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSUInteger numGroups = [self numberOfGroupsInArea:idx];
        for (NSUInteger i = 0; i < numGroups + 1; ++i)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForPosition:i inArea:idx];
            if (CGRectIntersectsRect(self.bounds, [self _rectForGroupSeparatorAtIndexPath:indexPath]))
                [indexPaths addObject:indexPath];
        }
    }];
    return indexPaths;
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
            headerTitle = [_dataSource relationalTableView:self titleForHeaderInArea:i];
        [_headerTitles addObject:headerTitle];
        NSUInteger numGroups = 1;
        if (_flags.dataSourceNumberOfGroupsInArea)
            numGroups = [_dataSource relationalTableView:self numberOfGroupsInArea:i];
        NSMutableArray *groups = [NSMutableArray arrayWithCapacity:numGroups];
        for (NSUInteger j = 0; j < numGroups; ++j)
        {
            NSUInteger numItems = 0;
            if (_flags.dataSourceNumberOfItemsInGroupInArea)
                numItems = [_dataSource relationalTableView:self numberOfItemsInGroup:j inArea:i];
            [groups addObject:[NSNumber numberWithUnsignedInteger:numItems]];
        }
        [_areas addObject:groups];
    }
    CGRect lastAreaFrame = [self rectForArea:[self numberOfAreas] - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height);
    [self setNeedsLayout];
}

#pragma mark -
#pragma mark Info

- (NSUInteger)columns
{
    CGFloat netWidth = self.bounds.size.width - _tableInsets.left - _tableInsets.right - _groupInsets.left - _groupInsets.right;
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
    static CGRect cachedAreaRect;
    if (area == cachedArea)
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
    {
        if (_isEditing && j == 0)
            height += _groupPlaceholderHeight;
        height += [self _heightForGroup:j inArea:area];
        if (_isEditing)
            height += _groupPlaceholderHeight;
        else if (j != numGroups - 1)
            height += _groupSeparatorHeight;
    }
    cachedArea = area;
    cachedAreaRect = CGRectMake(x, y, width, height);
    return cachedAreaRect;
}

- (CGRect)rectForHeaderInArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    return CGRectMake(areaRect.origin.x, areaRect.origin.y, self.bounds.size.width - _tableInsets.left - _tableInsets.right - _headerInsets.left - _headerInsets.right, _headerHeight);
}

- (CGRect)rectForGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    static NSUInteger cachedGroup = NSUIntegerMax;
    static NSUInteger cachedArea = NSUIntegerMax;
    static CGRect cachedGroupRect;
    if (group == cachedGroup && area == cachedArea)
        return cachedGroupRect;
    CGRect areaRect = [self rectForArea:area];
    CGFloat x = areaRect.origin.x;
    CGFloat y = areaRect.origin.y + _headerHeight;
    if (_isEditing)
        y += _groupPlaceholderHeight;
    for (NSUInteger i = 0; i < group; ++i)
    {
        y += [self _heightForGroup:i inArea:area];
        if (_isEditing)
            y += _groupPlaceholderHeight;
        else
            y += _groupSeparatorHeight;
    }
    CGFloat width = areaRect.size.width;
    CGFloat height = [self _heightForGroup:group inArea:area];
    cachedArea = area;
    cachedGroup = group;
    cachedGroupRect = CGRectMake(x, y, width, height);
    return cachedGroupRect;
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSUInteger cachedItem = NSUIntegerMax;
    static NSUInteger cachedGroup = NSUIntegerMax;
    static NSUInteger cachedArea = NSUIntegerMax;
    static CGRect cachedItemRect;
    if (!indexPath)
        return CGRectZero;
    if (indexPath.item == cachedItem && indexPath.group == cachedGroup && indexPath.area == cachedArea)
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
    return cachedItemRect;
}

#pragma mark -
#pragma mark Index paths

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
    static CGPoint cachedPoint = (CGPoint){CGFLOAT_MAX, CGFLOAT_MAX};
    static NSUInteger cachedArea;
    static NSUInteger cachedGroup;
    static NSUInteger cachedItem;
    if (CGPointEqualToPoint(point, cachedPoint))
        if (cachedArea == NSUIntegerMax)
            return nil;
        else
            return [NSIndexPath indexPathForItem:cachedItem inGroup:cachedGroup inArea:cachedArea];
    for (NSUInteger i = 0; i < [self numberOfAreas]; ++i)
    {
        CGRect areaRect = CGRectZero;
        areaRect = [self rectForArea:i];
        if (!CGRectContainsPoint(areaRect, point))
            continue;
        for (NSUInteger j = 0; j < [self numberOfGroupsInArea:i]; ++j)
        {
            CGRect groupRect = CGRectZero;
            groupRect = [self rectForGroup:j inArea:i];
            if (!CGRectContainsPoint(groupRect, point))
                continue;
            for (NSUInteger k = 0; k < [self numberOfItemsInGroup:j inArea:i]; )
            {
                CGRect itemRect = CGRectZero;
                itemRect = [self rectForItemAtIndexPath:[NSIndexPath indexPathForItem:k inGroup:j inArea:i]];
                if (CGRectContainsPoint(itemRect, point))
                {
                    cachedPoint = point;
                    cachedArea = i;
                    cachedGroup = j;
                    cachedItem = k;
                    return [NSIndexPath indexPathForItem:k inGroup:j inArea:i];
                }
                if (itemRect.origin.y > point.y)
                    break;
                if (point.y > itemRect.origin.y + itemRect.size.height)
                    k += [self columns];
                else
                    ++k;
            }
        }
    }
    cachedPoint = point;
    cachedArea = NSUIntegerMax;
    return nil;
}

- (ECRelationalTableViewCell *)loadCellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceCellForItemAtIndexPath)
        return nil;
    ECRelationalTableViewCell * cell = [_dataSource relationalTableView:self cellForItemAtIndexPath:indexPath];
    return cell;
}

- (ECRelationalTableViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath)
        return nil;
    return [_visibleCells objectForKey:indexPath];
}

- (NSArray *)visibleCells
{
    return [_visibleCells allValues];
}

- (NSArray *)indexPathsForVisibleItems
{
    CGRect bounds = self.bounds;
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        CGRect areaRect = [self rectForArea:i];
        if (!CGRectIntersectsRect(bounds, areaRect))
            continue;
        NSUInteger numGroups = [self numberOfGroupsInArea:i];
        for (NSUInteger j = 0; j < numGroups; ++j)
        {
            CGRect groupRect = [self rectForGroup:j inArea:i];
            if (!CGRectIntersectsRect(bounds, groupRect))
                continue;
            NSUInteger numItems = [self numberOfItemsInGroup:j inArea:i];
            for (NSUInteger k = 0; k < numItems; ++k)
            {
                CGRect itemRect = [self rectForItemAtIndexPath:[NSIndexPath indexPathForItem:k inGroup:j inArea:i]];
                if (!CGRectIntersectsRect(bounds, itemRect))
                    continue;
                [indexPaths addObject:[NSIndexPath indexPathForItem:k inGroup:j inArea:i]];
            }
        }
    }
    return indexPaths;
}

#pragma mark -
#pragma mark Recycling

- (ECRelationalTableViewCell *)dequeueReusableCell
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
        {
            [_visibleHeaders removeObjectForKey:[NSNumber numberWithUnsignedInteger:idx]];
            header.center = [self _centerForHeaderInArea:idx];
        }
        else
        {
            header = [_headerCache pop];
            [self addSubview:header];
            header.text = [_headerTitles objectAtIndex:idx];
            header.frame = UIEdgeInsetsInsetRect([self rectForHeaderInArea:idx], _headerInsets);
        }
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
        {
            [_visibleSeparators removeObjectForKey:indexPath];
            separator.center = [self _centerForGroupSeparatorAtIndexPath:indexPath];
        }
        else
        {
            separator = [_groupSeparatorCache pop];
            [self addSubview:separator];
            separator.frame = UIEdgeInsetsInsetRect([self _rectForGroupSeparatorAtIndexPath:indexPath], _groupSeparatorInsets);
        }
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

- (void)_layoutGroupPlaceholders
{
    NSMutableDictionary *newVisibleGroupPlaceholders = [[NSMutableDictionary alloc] init];
    for (NSIndexPath *indexPath in [self _indexPathsForVisibleGroupPlaceholders])
    {
        UIView *placeholder = [_visiblePlaceholders objectForKey:indexPath];
        if (placeholder)
        {
            [_visiblePlaceholders removeObjectForKey:indexPath];
            placeholder.center = [self _centerForGroupPlaceholderAtIndexPath:indexPath];
        }
        else
        {
            placeholder = [_groupPlaceholderCache pop];
            [self addSubview:placeholder];
            placeholder.frame = UIEdgeInsetsInsetRect([self _rectForGroupPlaceholderAtIndexPath:indexPath], _groupPlaceholderInsets);
        }
        [newVisibleGroupPlaceholders setObject:placeholder forKey:indexPath];
    }
    for (UIView *placeholder in [_visiblePlaceholders allValues])
    {
        [placeholder removeFromSuperview];
        [_groupPlaceholderCache push:placeholder];
    }
    [_visiblePlaceholders release];
    _visiblePlaceholders = newVisibleGroupPlaceholders;
}

- (void)_layoutCells
{
    NSMutableDictionary *newVisibleItems = [[NSMutableDictionary alloc] init];
    for (NSIndexPath *indexPath in [self indexPathsForVisibleItems])
    {
        ECRelationalTableViewCell *cell = [_visibleCells objectForKey:indexPath];
        if (cell)
        {
            [_visibleCells removeObjectForKey:indexPath];
            cell.center = [self _centerForItemAtIndexPath:indexPath];
        }
        else
        {
            cell = [self loadCellForItemAtIndexPath:indexPath];
            cell.frame = UIEdgeInsetsInsetRect([self rectForItemAtIndexPath:indexPath], _cellInsets);
            [self addSubview:cell];
        }
        [newVisibleItems setObject:cell forKey:indexPath];
    }
    for (ECRelationalTableViewCell *cell in [_visibleCells allValues])
    {
        [cell removeFromSuperview];
        [_cellCache push:cell];
    }
    [_visibleCells release];
    _visibleCells = newVisibleItems;
}

- (void)layoutSubviews
{
    [self _layoutHeaders];
    if (!_isEditing)
        [self _layoutGroupSeparators];
    else
        [self _layoutGroupPlaceholders];
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
        if (_flags.dataSourceCanMoveItem && [self indexPathForItemAtPoint:[gestureRecognizer locationInView:self]] && [_dataSource relationalTableView:self canMoveItemAtIndexPath:[self indexPathForItemAtPoint:[gestureRecognizer locationInView:self]]])
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
    [__delegate relationalTableView:self didSelectItemAtIndexPath:indexPath];
}

- (void)_handlePanGesture:(UILongPressGestureRecognizer *)longPressGestureRecognizer
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
    _draggedItem = [[self cellForItemAtIndexPath:_draggedItemIndexPath] retain];
    _draggedItem.center = [dragRecognizer locationInView:self];
}

- (void)_continueDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _draggedItem.center = [dragRecognizer locationInView:self];
    _dragDestinationIndexPath = [self indexPathForItemAtPoint:[dragRecognizer locationInView:self]];
    [self setNeedsLayout];
    [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECRelationalTableViewShortAnimationDuration animations:^(void) {
        [self layoutIfNeeded];
    } completion:NULL];
}

- (void)_endDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    [self _cancelDrag:dragRecognizer];
}

- (void)_cancelDrag:(UILongPressGestureRecognizer *)dragRecognizer
{
    _isDragging = NO;
    _draggedItem.center = [self _centerForItemAtIndexPath:_draggedItemIndexPath];
    [_draggedItemIndexPath release];
    _draggedItemIndexPath = nil;
    [_draggedItem release];
    _draggedItem = nil;
}

@end

#pragma mark -

@implementation NSIndexPath (ECRelationalTableView)

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
