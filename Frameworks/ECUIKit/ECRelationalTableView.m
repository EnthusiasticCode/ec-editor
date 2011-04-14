//
//  ECRelationalTableView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECRelationalTableView.h"
#import "ECRelationalTableViewCell.h"
//#import "UIView+ConcurrentAnimations.h"

@interface ECRelationalTableView ()
{
    @private
    struct {
        unsigned int dataSourceNumberOfItemsAtLevelInArea:1;
        unsigned int dataSourceCellForItemAtIndexPath:1;
        unsigned int dataSourceRelatedIndexPathsForItemAtIndexPath:1;
        unsigned int dataSourceNumberOfAreasInTableView:1;
        unsigned int dataSourceNumberOfLevelsInArea:1;
        unsigned int dataSourceTitleForHeaderInArea:1;
        unsigned int dataSourceTitleForFooterInArea:1;
        unsigned int dataSourceCanEditItem:1;
        unsigned int dataSourceCanMoveItem:1;
        unsigned int dataSourceMoveItem:1;
        unsigned int delegateWillSelectItem:1;
        unsigned int delegateWillDeselectItem:1;
        unsigned int delegateDidSelectItem:1;
        unsigned int delegateDidDeselectItem:1;
        unsigned int delegateTargetIndexPathForMoveFromItem:1;
    } _flags;
    BOOL _needsReloadData;
    BOOL _isAnimating;
}
- (CGRect)rectForHeaderInAreaRect:(CGRect)areaRect;
- (CGRect)rectForFooterInAreaRect:(CGRect)areaRect;
- (CGRect)rectForLevel:(NSUInteger)level inArea:(NSUInteger)area inAreaRect:(CGRect)areaRect;
- (CGRect)rectForTopLevelSeparatorInAreaRect:(CGRect)areaRect;
- (CGRect)rectForBottomLevelSeparatorInAreaRect:(CGRect)areaRect;
- (CGRect)rectForLevelSeparatorBelowLevelRect:(CGRect)levelRect;
- (CGRect)rectForItem:(NSUInteger)item inLevelRect:(CGRect)levelRect;
- (NSIndexPath *)proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists;
- (void)handleTapGesture:(UIGestureRecognizer *)tapGestureRecognizer;
- (void)handleCellPanGesture:(UIGestureRecognizer *)panGestureRecognizer;
@end

@implementation ECRelationalTableView

@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize tableInsets = _tableInsets;
@synthesize cellSize = _cellSize;
@synthesize cellInsets = _cellInsets;
@synthesize levelInsets = _levelInsets;
@synthesize levelSeparatorInsets = _levelSeparatorInsets;
@synthesize areaHeaderInsets = _areaHeaderInsets;
@synthesize allowsSelection = _allowsSelection;
@synthesize editing = _isEditing;

- (void)setDelegate:(id<ECRelationalTableViewDelegate>)delegate
{
    if (delegate == _delegate)
        return;
    [self willChangeValueForKey:@"delegate"];
    _delegate = delegate;
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
    _flags.dataSourceNumberOfLevelsInArea = [dataSource respondsToSelector:@selector(relationalTableView:numberOfLevelsInArea:)];
    _flags.dataSourceNumberOfItemsAtLevelInArea = [dataSource respondsToSelector:@selector(relationalTableView:numberOfItemsAtLevel:inArea:)];
    _flags.dataSourceCellForItemAtIndexPath = [dataSource respondsToSelector:@selector(relationalTableView:cellForItemAtIndexPath:)];
    _flags.dataSourceRelatedIndexPathsForItemAtIndexPath = [dataSource respondsToSelector:@selector(relationalTableView:relatedIndexPathsForItemAtIndexPath:)];
    _flags.dataSourceNumberOfAreasInTableView = [dataSource respondsToSelector:@selector(numberOfAreasInTableView:)];
    _flags.dataSourceTitleForHeaderInArea = [dataSource respondsToSelector:@selector(relationalTableView:titleForHeaderInArea:)];
    _flags.dataSourceTitleForFooterInArea = [dataSource respondsToSelector:@selector(relationalTableView:titleForFooterInArea:)];
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
    self.canCancelContentTouches = !editing;
    if (animated)
    { // do concurrently
//        [UIView animateWithDuration:0.0 animations:^(void) {
//            [self layoutIfNeeded];
//        }];
    }
    [self didChangeValueForKey:@"editing"];   
}
- (void)dealloc
{
    [super dealloc];
}

static id init(ECRelationalTableView *self)
{
    self->_cellSize = CGSizeMake(120.0, 30.0);
    self->_tableInsets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    self->_cellInsets = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
    self->_levelInsets = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
    self->_areaHeaderInsets = UIEdgeInsetsMake(5.0, 0.0, 5.0, 0.0);
    UITapGestureRecognizer *tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [self addGestureRecognizer:tapGestureRecognizer];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    self.userInteractionEnabled = YES;
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    return init(self);
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    if (!self)
        return nil;
    return init(self);
}

- (NSUInteger)columns
{
    return self.contentWidthInCells;
}

- (NSUInteger)rowsAtLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    NSUInteger numCells = [self numberOfItemsAtLevel:level inArea:area];
    return ceil((CGFloat)numCells / (CGFloat)self.contentWidthInCells);
}

- (void)reloadData
{
    NSUInteger numAreas = 1;
    if (_flags.dataSourceNumberOfAreasInTableView)
        numAreas = [_dataSource numberOfAreasInTableView:self];
    self.items = [NSMutableArray arrayWithCapacity:numAreas];
    self.areaHeaders = [NSMutableArray arrayWithCapacity:numAreas];
    self.levelSeparators = [NSMutableArray array];
    self.relatedIndexPaths = [NSMutableDictionary dictionary];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        UIView *header = nil;
        if (_flags.delegateViewForHeaderInArea)
            header = [_delegate relationalTableView:self viewForHeaderInArea:i];
        else
        {
            header = [[[UILabel alloc] init] autorelease];
            header.backgroundColor = [UIColor grayColor];
            if (_flags.dataSourceTitleForHeaderInArea)
                ((UILabel *)header).text = [_dataSource relationalTableView:self titleForHeaderInArea:i];
        }
        [self.areaHeaders addObject:header];
        NSUInteger numLevels = 1;
        if (_flags.dataSourceNumberOfLevelsInArea)
            numLevels = [_dataSource relationalTableView:self numberOfLevelsInArea:i];
        NSMutableArray *levels = [NSMutableArray arrayWithCapacity:numLevels];
        for (NSUInteger j = 0; j < numLevels; ++j)
        {
            // 2 separators per level: top and bottom
            for (NSUInteger separator = 0; separator < 2; ++separator)
            {
                UIView *levelSeparator = [[[UIView alloc] init] autorelease];
                levelSeparator.backgroundColor = [UIColor blackColor];
                [self.levelSeparators addObject:levelSeparator];
            }
            NSUInteger numItems = 0;
            if (_flags.dataSourceNumberOfItemsAtLevelInArea)
                numItems = [_dataSource relationalTableView:self numberOfItemsAtLevel:j inArea:i];
            NSMutableArray *itemsInLevel = [NSMutableArray arrayWithCapacity:numItems];
            for (NSUInteger k = 0; k < numItems; ++k)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:k atLevel:j inArea:i];
                ECRelationalTableViewCell *cell = nil;
                if (_flags.dataSourceCellForItemAtIndexPath)
                    cell = [_dataSource relationalTableView:self cellForItemAtIndexPath:indexPath];
                if (!cell)
                    continue;
                UIPanGestureRecognizer *cellPanGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellPanGesture:)] autorelease];
                [cell addGestureRecognizer:cellPanGestureRecognizer];
                cell.exclusiveTouch = YES;
                [itemsInLevel addObject:cell];
                if (_flags.dataSourceRelatedIndexPathsForItemAtIndexPath)
                    [self.relatedIndexPaths setObject:[_dataSource relationalTableView:self relatedIndexPathsForItemAtIndexPath:indexPath] forKey:indexPath];
            }
            [levels addObject:itemsInLevel];
        }
        [self.items addObject:levels];
    }
    if (![self.relatedIndexPaths count])
        self.relatedIndexPaths = nil;
    _flags.needsReloadData = NO;
}

- (NSUInteger)numberOfAreas
{
    return [self.items count];
}

- (NSUInteger)numberOfLevelsInArea:(NSUInteger)area
{
    return [[self.items objectAtIndex:area] count];
}

- (NSUInteger)numberOfItemsAtLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    return [[[self.items objectAtIndex:area] objectAtIndex:level] count];
}

- (CGRect)rectForArea:(NSUInteger)area
{
    CGFloat areaHeaderHeight = self.paddedAreaHeaderSize.height;
    CGFloat cellHeight = self.paddedCellSize.height;
    CGFloat levelSeparatorHeight = self.paddedLevelSeparatorSize.height;
    UIEdgeInsets tableInsets = _tableInsets;
    CGFloat x = tableInsets.left;
    CGFloat y = tableInsets.top;
    y +=  areaHeaderHeight * area;
    for (NSUInteger i = 0; i < area; ++i)
        for (NSUInteger j = 0; j < [self numberOfLevelsInArea:i]; ++j)
        {
            // if the table is not editing, the is no separator after the last level
            if (j == 0 && !_isEditing)
                y -= levelSeparatorHeight;
            // if the table is editing, there is a separator before each level
            if (_isEditing)
                y += levelSeparatorHeight;
            y += [self rowsAtLevel:j inArea:i] * cellHeight;
            y += _levelInsets.top + _levelInsets.bottom;
            y += levelSeparatorHeight;
        }
    CGFloat width = self.bounds.size.width - tableInsets.left - tableInsets.right;
    CGFloat height = areaHeaderHeight;
    for (NSUInteger j = 0; j < [self numberOfLevelsInArea:area]; ++j)
    {
        // if the table is not editing, the is no separator after the last level
        if (j == 0 && !_isEditing)
            height -= levelSeparatorHeight;
        // if the table is editing, there is a separator before each level
        if (_isEditing)
            height += levelSeparatorHeight;
        height += [self rowsAtLevel:j inArea:area] * cellHeight;
        height += _levelInsets.top + _levelInsets.bottom;
        height += levelSeparatorHeight;
    }
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForHeaderInAreaRect:(CGRect)areaRect
{
    CGFloat x = areaRect.origin.x + _areaHeaderInsets.left;
    CGFloat y = areaRect.origin.y + _areaHeaderInsets.top;
    CGFloat width = self.paddedAreaHeaderSize.width - _areaHeaderInsets.left - _areaHeaderInsets.right;
    CGFloat height = self.paddedAreaHeaderSize.height - _areaHeaderInsets.top - _areaHeaderInsets.bottom;
    return (CGRect){ (CGPoint){x, y} , (CGSize){width, height}};
}

- (CGRect)rectForHeaderInArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    return [self rectForHeaderInAreaRect:areaRect];
}

- (CGRect)rectForLevel:(NSUInteger)level inArea:(NSUInteger)area inAreaRect:(CGRect)areaRect
{
    CGFloat x = areaRect.origin.x + _levelInsets.left;
    CGFloat y = areaRect.origin.y + _areaHeaderInsets.top + self.paddedAreaHeaderSize.height + _areaHeaderInsets.bottom;
    y += (_levelInsets.top + _levelInsets.bottom) * level;
    for (NSUInteger i = 0; i < level; ++i)
    {
        y += [self rowsAtLevel:i inArea:area];
        y += paddedLevelSeparatorSize_.height;
    }
    y += _levelInsets.top;
    CGFloat width = self.bounds.size.width - _tableInsets.left - _tableInsets.right - _levelInsets.left - _levelInsets.right;
    CGFloat height = [self rowsAtLevel:level inArea:area] * self.paddedCellSize.height;
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    return [self rectForLevel:level inArea:area inAreaRect:areaRect];
}

- (CGRect)rectForLevelSeparatorInLevelRect:(CGRect)levelRect isTopSeparator:(BOOL)isTopSeparator
{
    CGFloat x = levelRect.origin.x + _levelSeparatorInsets.left;
    CGFloat y;
    if (isTopSeparator)
        y = levelRect.origin.y + _levelSeparatorInsets.top;
    else
        y = levelRect.origin.y + levelRect.size.height - _levelSeparatorInsets.bottom;
    CGFloat height = self.levelSeparatorHeight;
    CGFloat width = self.paddedLevelSeparatorSize.width - _levelSeparatorInsets.left - _levelSeparatorInsets.right;
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForItem:(NSUInteger)item inLevelRect:(CGRect)levelRect
{
    CGFloat x = levelRect.origin.x + _cellInsets.left;
    CGFloat y = levelRect.origin.y + _cellInsets.top;
    NSUInteger row = item / self.contentWidthInCells;
    NSUInteger column = item % self.contentWidthInCells;
    x += column * self.paddedCellSize.width;
    y += row * self.paddedCellSize.height;
    return (CGRect){ (CGPoint){x, y}, _cellSize};
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect levelRect = [self rectForLevel:indexPath.level inArea:indexPath.area];
    return [self rectForItem:indexPath.item inLevelRect:levelRect];
}

- (ECRelationalTableViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath)
        return nil;
    return [[[self.items objectAtIndex:indexPath.area] objectAtIndex:indexPath.level] objectAtIndex:indexPath.item];
}

- (NSArray *)relatedIndexPathsForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.relatedIndexPaths objectForKey:indexPath];
}

- (void)layoutSubviews
{
    if (_flags.needsReloadData)
        [self reloadData];
    NSUInteger numAreas = [self numberOfAreas];
    UIView *header;
    UIView *levelSeparator;
    NSUInteger levelSeparatorIndex = 0;
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        CGRect areaRect = [self rectForArea:i];
        header = [self.areaHeaders objectAtIndex:i];
        if (![header superview])
            [self.rootView addSubview:header];
        header.frame = [self rectForHeaderInAreaRect:areaRect];
        NSUInteger numLevels = [self numberOfLevelsInArea:i];
        for (NSUInteger j = 0; j < numLevels; ++j)
        {
            CGRect levelRect = [self rectForLevel:j inArea:i inAreaRect:areaRect];
            NSUInteger numItems = [self numberOfItemsAtLevel:j inArea:i];
            if (numItems)
            {
                levelSeparator = [self.levelSeparators objectAtIndex:levelSeparatorIndex];
                if (![levelSeparator superview])
                    [self.rootView addSubview:levelSeparator];
                levelSeparator.frame = [self rectForLevelSeparatorInLevelRect:levelRect isTopSeparator:YES];
                if (!_isEditing)
                    levelSeparator.alpha = 0.0;
                else
                    levelSeparator.alpha = 1.0;
            }
            ++levelSeparatorIndex;
            for (NSUInteger k = 0; k < numItems; ++k)
            {
                NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:k atLevel:j inArea:i];
                ECRelationalTableViewCell *cell;
                if (_isEditing && [self.dragDestination isEqual:itemIndexPath])
                    cell = self.cellBeingDragged;
                else
                    cell= [self cellForItemAtIndexPath:itemIndexPath];
                [self.rootView addSubview:cell];
                if (_isEditing && self.dragSource.area == i && self.dragSource.level == j && self.dragSource.item <= k)
                    cell.frame = [self rectForItem:k - 1 inLevelRect:levelRect];
                else
                    cell.frame = [self rectForItem:k inLevelRect:levelRect];
            }
            if (numItems)
            {
                levelSeparator = [self.levelSeparators objectAtIndex:levelSeparatorIndex];
                if (![levelSeparator superview])
                    [self.rootView addSubview:levelSeparator];
                levelSeparator.frame = [self rectForLevelSeparatorInLevelRect:levelRect isTopSeparator:NO];
                if (j == numLevels - 1 && !_isEditing)
                    levelSeparator.alpha = 0.0;
                else if (j == numLevels - 1)
                    levelSeparator.alpha = 1.0;
            }
            ++levelSeparatorIndex;
        }
    }
    CGRect lastAreaFrame = [self rectForArea:numAreas - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height + _tableInsets.bottom);
}

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
    CGPoint contentOffset = [self contentOffset];
    point.x += contentOffset.x;
    point.y += contentOffset.y;
    for (NSUInteger i = 0; i < [self numberOfAreas]; ++i)
    {
        CGRect areaRect = CGRectZero;
        areaRect = [self rectForArea:i];
        if (!CGRectContainsPoint(areaRect, point))
            continue;
        for (NSUInteger j = 0; j < [self numberOfLevelsInArea:i]; ++j)
        {
            CGRect levelRect = CGRectZero;
            levelRect = [self rectForLevel:j inArea:i inAreaRect:areaRect];
            if (!CGRectContainsPoint(levelRect, point))
                continue;
            for (NSUInteger k = 0; k < [self numberOfItemsAtLevel:j inArea:i]; )
            {
                CGRect itemRect = CGRectZero;
                itemRect = [self rectForItem:k inLevelRect:levelRect];
                if (CGRectContainsPoint(itemRect, point))
                    return [NSIndexPath indexPathForItem:k atLevel:j inArea:i];
                if (itemRect.origin.y > point.y)
                    break;
                if (point.y > itemRect.origin.y + itemRect.size.height)
                    k += [self contentWidthInCells];
                else
                    ++k;
            }
        }
    }
    return nil;
}

- (NSIndexPath *)proposedIndexPathForItemAtPoint:(CGPoint)point exists:(BOOL *)exists
{
    *exists = YES;
    return [self indexPathForItemAtPoint:point];
}

- (void)handleTapGesture:(UIGestureRecognizer *)tapGestureRecognizer
{
    if (!_flags.delegateDidSelectItem)
        return;
    if (_isEditing)
        return;
    if (![tapGestureRecognizer state] == UIGestureRecognizerStateEnded)
        return;
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:[tapGestureRecognizer locationInView:self]];
    [_delegate relationalTableView:self didSelectItemAtIndexPath:indexPath];
}

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

@end

@implementation NSIndexPath (ECRelationalTableView)

- (NSUInteger)area
{
    return [self indexAtPosition:0];
}

- (NSUInteger)level
{
    return [self indexAtPosition:1];
}

- (NSUInteger)item
{
    return [self indexAtPosition:2];
}

+ (NSIndexPath *)indexPathForItem:(NSUInteger)item atLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    return [self indexPathWithIndexes:(NSUInteger[3]){area, level, item} length:3];
}

@end
