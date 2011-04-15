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

const CGFloat ECRelationalTableViewShortAnimationDuration = 0.15;
const NSUInteger ECRelationalTableViewCellBufferSize = 10;
const NSUInteger ECRelationalTableViewHeaderBufferSize = 5;
const NSUInteger ECRelationalTableViewGroupSeparatorBufferSize = 20;
const NSUInteger ECRelationalTableViewGroupPlaceholderBufferSize = 20;

@interface ECRelationalTableView ()
{
    @private
    struct {
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
    CGFloat _headerHeight;
    CGFloat _groupSeparatorHeight;
    CGFloat _groupPlaceholderHeight;
    UIEdgeInsets _groupPlaceholderInsets;
    NSMutableArray *_areas;
    NSMutableArray *_headerTitles;
    ECStackCache *_headerCache;
    ECStackCache *_groupSeparatorCache;
    ECStackCache *_groupPlaceholderCache;
    ECStackCache *_cellCache;
    NSMutableDictionary *_visibleCells;
}
- (void)_setup;
- (UIView *)_blankHeader:(ECStackCache *)cache;
- (UIView *)_groupSeparator:(ECStackCache *)cache;
- (UIView *)_groupPlaceholder:(ECStackCache *)cache;
- (CGRect)_headerBounds;
- (CGRect)_groupSeparatorBounds;
- (CGRect)_groupPlaceholderBounds;
- (CGFloat)_heightForGroup:(NSUInteger)group inArea:(NSUInteger)area;
//- (CGRect)rectForGroupSeparatorAboveGroupRect:(CGRect)groupRect;
//- (CGRect)rectForGroupSeparatorBelowGroupRect:(CGRect)groupRect;
//- (CGRect)rectForGroupPlaceholderAboveGroupRect:(CGRect)groupRect;
//- (CGRect)rectForGroupPlaceholderBelowGroupRect:(CGRect)groupRect;
- (CGPoint)_centerForHeaderInArea:(NSUInteger)area;
- (CGPoint)_centerForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)_indexPathForItemAtPoint:(CGPoint)point includeInsets:(BOOL)includeInsets;
//- (NSIndexPath *)proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists;
- (void)_handleTapGesture:(UIGestureRecognizer *)tapGestureRecognizer;
//- (void)handleCellPanGesture:(UIGestureRecognizer *)panGestureRecognizer;
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
@synthesize groupSeparatorInsets = _groupSeparatorInsets;
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
    if (animated)
    {
        [UIView animateConcurrentlyToAnimationsWithFlag:&_isAnimating duration:ECRelationalTableViewShortAnimationDuration animations:^(void) {
            [self layoutIfNeeded];
        } completion:NULL];
    }
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
    [_visibleCells release];
    [super dealloc];
}

#pragma mark -
#pragma mark Private methods

- (void)_setup
{
    _tableInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    _cellSize = CGSizeMake(180.0, 80.0);
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
    UITapGestureRecognizer *tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleTapGesture:)] autorelease];
    [self addGestureRecognizer:tapGestureRecognizer];
    //    UIPanGestureRecognizer *cellPanGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellPanGesture:)] autorelease];
    //    [self addGestureRecognizer:cellPanGestureRecognizer];
}

- (CGRect)_headerBounds
{
    return CGRectMake(0.0, 0.0, self.bounds.size.width - _tableInsets.left - _tableInsets.right - _headerInsets.left - _headerInsets.right, _headerHeight);
}

- (UIView *)_blankHeader:(ECStackCache *)cache
{
    UILabel *header = [[[UILabel alloc] init] autorelease];
    header.backgroundColor = [UIColor blueColor];
    header.bounds = [self _headerBounds];
    return header;
}

- (CGRect)_groupSeparatorBounds
{
    return CGRectMake(0.0, 0.0, self.bounds.size.width - _tableInsets.left - _tableInsets.right - _groupSeparatorInsets.left - _groupSeparatorInsets.right, _groupSeparatorHeight);
}

- (UIView *)_groupSeparator:(ECStackCache *)cache
{
    UIView *groupSeparator = [[[UIView alloc] init] autorelease];
    groupSeparator.backgroundColor = [UIColor blackColor];
    groupSeparator.bounds = [self _groupSeparatorBounds];
    return groupSeparator;
}

- (CGRect)_groupPlaceholderBounds
{
    return CGRectMake(0.0, 0.0, self.bounds.size.width - _tableInsets.left - _tableInsets.right - _groupPlaceholderInsets.left - _groupPlaceholderInsets.right, _groupPlaceholderHeight);
}

- (UIView *)_groupPlaceholder:(ECStackCache *)cache
{
    UIView *groupPlaceholder = [[[UIView alloc] init] autorelease];
    groupPlaceholder.backgroundColor = [UIColor blackColor];
    groupPlaceholder.bounds = [self _groupPlaceholderBounds];
    return groupPlaceholder;
}

- (CGFloat)_heightForGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    CGFloat height = 0;
    height += [self rowsInGroup:group inArea:area] * _cellSize.height;
    height += _groupInsets.top + _groupInsets.bottom;
    height += _groupSeparatorHeight;
    return height;
}

- (CGPoint)_centerForHeaderInArea:(NSUInteger)area
{
    CGRect rect = [self rectForHeaderInArea:area];
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

- (CGPoint)_centerForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect rect = [self rectForItemAtIndexPath:indexPath];
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

- (void)_handleTapGesture:(UIGestureRecognizer *)tapGestureRecognizer
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
    cachedAreaRect = UIEdgeInsetsInsetRect(CGRectMake(x, y, width, height), _tableInsets);
    return cachedAreaRect;
}

- (CGRect)rectForHeaderInArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    CGRect rect = [self _headerBounds];
    rect.origin.y = areaRect.origin.y;
    return UIEdgeInsetsInsetRect(rect, _headerInsets);
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
    for (NSUInteger i = 0; i < group; ++i)
    {
        y += [self _heightForGroup:i inArea:area];
    }
    CGFloat width = areaRect.size.width;
    CGFloat height = [self _heightForGroup:group inArea:area];
    cachedArea = area;
    cachedGroup = group;
    cachedGroupRect = UIEdgeInsetsInsetRect(CGRectMake(x, y, width, height), _groupInsets);
    return cachedGroupRect;
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSUInteger cachedItem = NSUIntegerMax;
    static NSUInteger cachedGroup = NSUIntegerMax;
    static NSUInteger cachedArea = NSUIntegerMax;
    static CGRect cachedItemRect;
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
        cachedItemRect = UIEdgeInsetsInsetRect(cachedItemRect, _cellInsets);
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
    point.x += self.contentOffset.x;
    point.y += self.contentOffset.y;
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
                    return [NSIndexPath indexPathForItem:k inGroup:j inArea:i];
                if (itemRect.origin.y > point.y)
                    break;
                if (point.y > itemRect.origin.y + itemRect.size.height)
                    k += [self columns];
                else
                    ++k;
            }
        }
    }
    return nil;
}

- (ECRelationalTableViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath || !_flags.dataSourceCellForItemAtIndexPath)
        return nil;
    ECRelationalTableViewCell * cell = [_dataSource relationalTableView:self cellForItemAtIndexPath:indexPath];
    CGRect rect = CGRectMake(0.0, 0.0, _cellSize.width, _cellSize.height);
    cell.bounds = UIEdgeInsetsInsetRect(rect, _cellInsets);
    return cell;
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

- (void)layoutSubviews
{
    NSUInteger numAreas = [self numberOfAreas];
    if (!numAreas)
        return;
//    UIView *groupSeparator;
//    NSUInteger groupSeparatorIndex = 0;
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        UILabel *header = [_headerCache pop];
        if ([header superview] != self)
            [self addSubview:header];
        header.text = [_headerTitles objectAtIndex:i];
        header.center = [self _centerForHeaderInArea:i];
//        NSUInteger numGroups = [self numberOfGroupsInArea:i];
//        for (NSUInteger j = 0; j < numGroups; ++j)
//        {
//            CGRect groupRect = [self _rectForGroup:j inArea:i inAreaRect:areaRect];
//            NSUInteger numItems = [self numberOfItemsInGroup:j inArea:i];
//            if (numItems)
//            {
//                groupSeparator = [self.groupSeparators objectAtIndex:groupSeparatorIndex];
//                if (![groupSeparator superview])
//                    [self addSubview:groupSeparator];
//                groupSeparator.frame = [self rectForGroupSeparatorInGroupRect:groupRect isTopSeparator:YES];
//                if (!_isEditing)
//                    groupSeparator.alpha = 0.0;
//                else
//                    groupSeparator.alpha = 1.0;
//            }
//            ++groupSeparatorIndex;
//            if (numItems)
//            {
//                groupSeparator = [self.groupSeparators objectAtIndex:groupSeparatorIndex];
//                if (![groupSeparator superview])
//                    [self addSubview:groupSeparator];
//                groupSeparator.frame = [self rectForGroupSeparatorInGroupRect:groupRect isTopSeparator:NO];
//                if (j == numGroups - 1 && !_isEditing)
//                    groupSeparator.alpha = 0.0;
//                else if (j == numGroups - 1)
//                    groupSeparator.alpha = 1.0;
//            }
//            ++groupSeparatorIndex;
//        }
    }
    NSMutableDictionary *newVisibleItems = [[NSMutableDictionary alloc] init];
    for (NSIndexPath *indexPath in [self indexPathsForVisibleItems])
    {
        ECRelationalTableViewCell *cell = [_visibleCells objectForKey:indexPath];
        if (!cell)
            cell = [self cellForItemAtIndexPath:indexPath];
        [newVisibleItems setObject:cell forKey:indexPath];
        if ([cell superview] != self)
            [self addSubview:cell];
        cell.center = [self _centerForItemAtIndexPath:indexPath];
    }
    [_visibleCells release];
    _visibleCells = newVisibleItems;
    CGRect lastAreaFrame = [self rectForArea:numAreas - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height + _tableInsets.bottom);
}
/*
- (NSIndexPath *)proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists
{
    *exists = YES;
    return [self indexPathForItemAtPoint:point];
}
*/
/*
- (void)handleCellPanGesture:(UIGestureRecognizer *)panGestureRecognizer
{
    if (!_isEditing)
        return;
    CGPoint locationInView;
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            _flags.isDragging = YES;
            self.dragSource = [self indexPathForItemAtPoint:[panGestureRecognizer locationInView:self]];
            self.cellBeingDragged = [self cellForItemAtIndexPath:self.dragSource];
            break;
            
        case UIGestureRecognizerStateChanged:
            locationInView = [panGestureRecognizer locationInView:self];
            self.cellBeingDragged.center = locationInView;
            self.dragDestination = [self proposedIndexPathForItemAtPoint:locationInView exists:&dragDestinationExists_];
            if (self.dragDestination == self.lastDragDestination)
                break;
            self.lastDragDestination = self.dragDestination;
            [self setNeedsLayout];
            [UIView animateWithDuration:0.5 animations:^{
                [self layoutIfNeeded];
            }];
            break;
            
        case UIGestureRecognizerStateEnded:
            _flags.isDragging = NO;
            self.cellBeingDragged = nil;
            self.dragSource = nil;
            self.dragDestination = nil;
            self.lastDragDestination = nil;
            self.dragDestinationExists = NO;
            [self setNeedsLayout];
            [UIView animateWithDuration:0.5 animations:^{
                [self layoutIfNeeded];
            }];
            break;
            
        default:
            break;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = nil;
    if (_isEditing)
        indexPath = [self indexPathForItemAtPoint:point];
    NSLog(@"%@", indexPath);
    if (indexPath)
        return [self cellForItemAtIndexPath:indexPath];
    return [super hitTest:point withEvent:event];
}
*/
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

+ (NSIndexPath *)indexPathForItem:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area
{
    return [self indexPathWithIndexes:(NSUInteger[3]){area, group, item} length:3];
}

@end
