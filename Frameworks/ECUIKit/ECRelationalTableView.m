//
//  ECRelationalTableView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECRelationalTableView.h"
#import "ECRelationalTableViewCell.h"

@interface ECRelationalTableView ()
{
    @private
    struct {
        unsigned int dataSourceNumberOfLevelsInArea:1;
        unsigned int dataSourceNumberOfItemsAtLevelInArea:1;
        unsigned int dataSourceCellForItemAtIndexPath:1;
        unsigned int dataSourceRelatedIndexPathsForItemAtIndexPath:1;
        unsigned int dataSourceNumberOfAreasInTableView:1;
        unsigned int dataSourceTitleForHeaderInArea:1;
        unsigned int dataSourceTitleForFooterInArea:1;
        unsigned int dataSourceCommitEditingStyle:1;
        unsigned int dataSourceCanEditItem:1;
        unsigned int dataSourceCanMoveItem:1;
        unsigned int dataSourceMoveItem:1;
        unsigned int delegateWillDisplayCellForItemAtIndexPath:1;
        unsigned int delegateViewForHeaderInArea:1;
        unsigned int delegateViewForFooterInArea:1;
        unsigned int delegateAccessoryTypeForItem:1;
        unsigned int delegateAccessoryButtonTappedForItem:1;
        unsigned int delegateWillSelectItem:1;
        unsigned int delegateWillDeselectItem:1;
        unsigned int delegateDidSelectItem:1;
        unsigned int delegateDidDeselectItem:1;
        unsigned int delegateEditingStyleForItem:1;
        unsigned int delegateTitleForDeleteConfirmationButtonForItem:1;
        unsigned int delegateTargetIndexPathForMoveFromItem:1;
//        unsigned int scrollsToSelection:1;
//        unsigned int updating:1;
//        unsigned int showsSelectionImmediatelyOnTouchBegin:1;
//        unsigned int defaultShowsHorizontalScrollIndicator:1;
//        unsigned int defaultShowsVerticalScrollIndicator:1;
//        unsigned int hideScrollIndicators:1;
        unsigned int needsLayoutSubviews:1;
        unsigned int needsReloadData:1;
        unsigned int wrapsItems:1;
        unsigned int isEditing:1;
        unsigned int isAnimatingEditing:1;
        unsigned int isDragging:1;
        unsigned int allowsSelection:1;
    } flags_;
}
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *rootView;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSMutableArray *areaHeaders;
@property (nonatomic, retain) NSMutableArray *levelSeparators;
@property (nonatomic, retain) NSMutableDictionary *relatedIndexPaths;
@property (nonatomic, retain) ECRelationalTableViewCell *cellBeingDragged;
@property (nonatomic, retain) NSIndexPath *dragSource;
@property (nonatomic, retain) NSIndexPath *dragDestination;
- (void)recalculatePaddedCellSizeAndContentWidthInCells;
- (void)recalculatePaddedLevelSeparatorSize;
- (void)recalculatePaddedAreaHeaderSize;

- (CGRect)rectForHeaderInAreaRect:(CGRect)areaRect;
- (CGRect)rectForFooterInAreaRect:(CGRect)areaRect;
- (CGRect)rectForLevel:(NSUInteger)level inArea:(NSUInteger)area inAreaRect:(CGRect)areaRect;
- (CGRect)rectForLevelSeparatorInLevelRect:(CGRect)levelRect isTopSeparator:(BOOL)isTopSeparator;
- (CGRect)rectForItem:(NSUInteger)item inLevelRect:(CGRect)levelRect;
- (void)handleTapGesture:(UIGestureRecognizer *)tapGestureRecognizer;
- (void)handleCellPanGesture:(UIGestureRecognizer *)panGestureRecognizer;
@end

@implementation ECRelationalTableView

@synthesize delegate = delegate_;
@synthesize dataSource = dataSource_;
@synthesize backgroundView = backgroundView_;
@synthesize tableHeaderView = tableHeaderView_;
@synthesize tableFooterView = tableFooterView_;
@synthesize tableInsets = tableInsets_;
@synthesize cellSize = cellSize_;
@synthesize cellInsets = cellInsets_;
@synthesize paddedCellSize = paddedCellSize_;
@synthesize contentWidthInCells = contentWidthInCells_;
@synthesize levelInsets = levelInsets_;
@synthesize levelSeparatorHeight = levelSeparatorHeight_;
@synthesize levelSeparatorInsets = levelSeparatorInsets_;
@synthesize paddedLevelSeparatorSize = paddedLevelSeparatorSize_;
@synthesize areaHeaderHeight = areaHeaderHeight_;
@synthesize areaHeaderInsets = areaHeaderInsets_;
@synthesize paddedAreaHeaderSize = paddedAreaHeaderSize_;
@synthesize areaFooterHeight = areaFooterHeight_;
@synthesize areaFooterInsets = areaFooterInsets_;
@synthesize paddedAreaFooterSize = paddedAreaFooterSize_;

@synthesize scrollView = scrollView_;
@synthesize rootView = rootView_;
@synthesize items = items_;
@synthesize areaHeaders = areaHeaders_;
@synthesize levelSeparators = levelSeparators_;
@synthesize relatedIndexPaths = relatedIndexPaths_;
@synthesize cellBeingDragged = cellBeingDragged_;
@synthesize dragSource = dragSource_;
@synthesize dragDestination = dragDestination_;

- (void)setTableInsets:(UIEdgeInsets)tableInsets
{
    [self willChangeValueForKey:@"tableInsets"];
    tableInsets_ = tableInsets;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
    [self recalculatePaddedAreaHeaderSize];
    [self didChangeValueForKey:@"tableInsets"];
}

- (void)setCellSize:(CGSize)cellSize
{
    [self willChangeValueForKey:@"cellSize"];
    cellSize_ = cellSize;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
    [self didChangeValueForKey:@"cellSize"];
}

- (void)setCellInsets:(UIEdgeInsets)cellInsets
{
    [self willChangeValueForKey:@"cellInsets"];
    cellInsets_ = cellInsets;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
    [self didChangeValueForKey:@"cellInsets"];
}

- (void)setLevelInsets:(UIEdgeInsets)levelInsets
{
    [self willChangeValueForKey:@"levelInsets"];
    levelInsets_ = levelInsets;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
    [self didChangeValueForKey:@"levelInsets"];
}

- (void)setLevelSeparatorHeight:(CGFloat)levelSeparatorHeight
{
    [self willChangeValueForKey:@"levelSeparatorHeight"];
    levelSeparatorHeight_ = levelSeparatorHeight;
    [self recalculatePaddedLevelSeparatorSize];
    [self didChangeValueForKey:@"levelSeparatorHeight"];
}

- (void)setLevelSeparatorInsets:(UIEdgeInsets)levelSeparatorInsets
{
    [self willChangeValueForKey:@"levelSeparatorInsets"];
    levelSeparatorInsets_ = levelSeparatorInsets;
    [self recalculatePaddedLevelSeparatorSize];
    [self didChangeValueForKey:@"levelSeparatorInsets"];
}

- (void)setAreaHeaderHeight:(CGFloat)areaHeaderHeight
{
    [self willChangeValueForKey:@"areaHeaderHeight"];
    areaHeaderHeight_ = areaHeaderHeight;
    [self recalculatePaddedAreaHeaderSize];
    [self didChangeValueForKey:@"areaHeaderHeight"];
}

- (void)setAreaHeaderInsets:(UIEdgeInsets)areaHeaderInsets
{
    [self willChangeValueForKey:@"areaHeaderInsets"];
    areaHeaderInsets_ = areaHeaderInsets;
    [self recalculatePaddedAreaHeaderSize];
    [self didChangeValueForKey:@"areaHeaderInsets"];
}

- (void)setDelegate:(id<ECRelationalTableViewDelegate>)delegate
{
    if (delegate == delegate_)
        return;
    [self willChangeValueForKey:@"delegate"];
    delegate_ = delegate;
    flags_.delegateWillDisplayCellForItemAtIndexPath = [delegate respondsToSelector:@selector(relationalTableView:willDisplayCell:forItemAtIndexPath:)];
    flags_.delegateViewForHeaderInArea = [delegate respondsToSelector:@selector(relationalTableView:viewForHeaderInArea:)];
    flags_.delegateViewForFooterInArea = [delegate respondsToSelector:@selector(relationalTableView:viewForFooterInArea:)];
    flags_.delegateWillSelectItem = [delegate respondsToSelector:@selector(relationalTableView:willSelectItemAtIndexPath:)];
    flags_.delegateWillDeselectItem = [delegate respondsToSelector:@selector(relationalTableView:willDeselectItemAtIndexPath:)];
    flags_.delegateDidSelectItem = [delegate respondsToSelector:@selector(relationalTableView:didSelectItemAtIndexPath:)];
    flags_.delegateDidDeselectItem = [delegate respondsToSelector:@selector(relationalTableView:didDeselectItemAtIndexPath:)];
    flags_.delegateEditingStyleForItem = [delegate respondsToSelector:@selector(relationalTableView:editingStyleForItemAtIndexPath:)];
    flags_.delegateTitleForDeleteConfirmationButtonForItem = [delegate respondsToSelector:@selector(relationalTableView:titleForDeleteConfirmationButtonForItemAtIndexPath:)];
    flags_.delegateTargetIndexPathForMoveFromItem = [delegate respondsToSelector:@selector(relationalTableView:targetIndexPathForMoveFromItemAtIndexPath:toProposedIndexPath:)];
    [self didChangeValueForKey:@"delegate"];
}

- (void)setDataSource:(id<ECRelationalTableViewDataSource>)dataSource
{
    if (dataSource == dataSource_)
        return;
    [self willChangeValueForKey:@"dataSource"];
    dataSource_ = dataSource;
    flags_.dataSourceNumberOfLevelsInArea = [dataSource respondsToSelector:@selector(relationalTableView:numberOfLevelsInArea:)];
    flags_.dataSourceNumberOfItemsAtLevelInArea = [dataSource respondsToSelector:@selector(relationalTableView:numberOfItemsAtLevel:inArea:)];
    flags_.dataSourceCellForItemAtIndexPath = [dataSource respondsToSelector:@selector(relationalTableView:cellForItemAtIndexPath:)];
    flags_.dataSourceRelatedIndexPathsForItemAtIndexPath = [dataSource respondsToSelector:@selector(relationalTableView:relatedIndexPathsForItemAtIndexPath:)];
    flags_.dataSourceNumberOfAreasInTableView = [dataSource respondsToSelector:@selector(numberOfAreasInTableView:)];
    flags_.dataSourceTitleForHeaderInArea = [dataSource respondsToSelector:@selector(relationalTableView:titleForHeaderInArea:)];
    flags_.dataSourceTitleForFooterInArea = [dataSource respondsToSelector:@selector(relationalTableView:titleForFooterInArea:)];
    flags_.dataSourceCanEditItem = [dataSource respondsToSelector:@selector(relationalTableView:canEditItemAtIndexPath:)];
    flags_.dataSourceCanMoveItem = [dataSource respondsToSelector:@selector(relationalTableView:canMoveItemAtIndexPath:)];
    flags_.dataSourceCommitEditingStyle = [dataSource respondsToSelector:@selector(relationalTableView:commitEditingStyle:forItemAtIndexPath:)];
    flags_.dataSourceMoveItem = [dataSource respondsToSelector:@selector(relationalTableView:moveItemAtIndexPath:toIndexPath:)];
    [self didChangeValueForKey:@"dataSource"];
}

- (BOOL)wrapsItems
{
    return flags_.wrapsItems;
}

- (void)setWrapsItems:(BOOL)wrapsItems
{
    [self willChangeValueForKey:@"wrapsItems"];
    flags_.wrapsItems = wrapsItems;
    [self didChangeValueForKey:@"wrapsItems"];
}

- (BOOL)isEditing
{
    return flags_.isEditing;
}

- (void)setEditing:(BOOL)editing
{
    [self setEditing:editing animated:NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (editing == flags_.isEditing)
        return;
    [self willChangeValueForKey:@"editing"];
    [self setNeedsLayout];
    flags_.needsLayoutSubviews = YES;
    flags_.isEditing = editing;
    self.scrollView.canCancelContentTouches = !editing;
    if (animated)
    {
        if (!flags_.isAnimatingEditing)
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self layoutIfNeeded];
            } completion:^(BOOL finished){
                if (finished)
                    flags_.isAnimatingEditing = NO;
            }];
        else
            [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut animations:^{
                [self layoutIfNeeded];
            }completion:^(BOOL finished){
                if (finished)
                    flags_.isAnimatingEditing = NO;
            }];
        flags_.isAnimatingEditing = YES;
    }
    [self didChangeValueForKey:@"editing"];   
}

- (BOOL)allowsSelection
{
    return flags_.allowsSelection;
}

- (void)setAllowsSelection:(BOOL)allowsSelection
{
    [self willChangeValueForKey:@"allowsSelection"];
    flags_.allowsSelection = allowsSelection;
    [self didChangeValueForKey:@"allowsSelection"];
}

- (void)dealloc
{
    self.backgroundView = nil;
    self.tableHeaderView = nil;
    self.tableFooterView = nil;
    self.scrollView = nil;
    self.rootView = nil;
    self.items = nil;
    self.relatedIndexPaths = nil;
    self.cellBeingDragged = nil;
    self.dragSource = nil;
    self.dragDestination = nil;
    [super dealloc];
}

static id init(ECRelationalTableView *self)
{
    self.contentMode = UIViewContentModeRedraw;
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    [self addSubview:self.scrollView];
    self.rootView = [[[UIView alloc] init] autorelease];
    [self.scrollView addSubview:self.rootView];
    self->cellSize_ = CGSizeMake(120.0, 30.0);
    self->tableInsets_ = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    self->cellInsets_ = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
    self->levelInsets_ = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
    self->levelSeparatorHeight_ = 5.0;
    self->areaHeaderInsets_ = UIEdgeInsetsMake(5.0, 0.0, 5.0, 0.0);
    self->areaHeaderHeight_ = 20.0;
    self->flags_.needsLayoutSubviews = YES;
    self->flags_.needsReloadData = YES;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
    [self recalculatePaddedLevelSeparatorSize];
    [self recalculatePaddedAreaHeaderSize];
    UITapGestureRecognizer *tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)] autorelease];
    [self.rootView addGestureRecognizer:tapGestureRecognizer];
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

- (void)recalculatePaddedCellSizeAndContentWidthInCells
{
    [self willChangeValueForKey:@"contentWidthInCells"];
    [self willChangeValueForKey:@"paddedCellSize"];
    UIEdgeInsets cellInsets = self.cellInsets;
    paddedCellSize_ = self.cellSize;
    paddedCellSize_.width += cellInsets.left + cellInsets.right;
    paddedCellSize_.height += cellInsets.top + cellInsets.bottom;
    CGFloat netWidth = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right - self.levelInsets.left - self.levelInsets.right;
    contentWidthInCells_ = netWidth / paddedCellSize_.width;
    paddedCellSize_.width = netWidth / (CGFloat)contentWidthInCells_;
    [self didChangeValueForKey:@"contentWidthInCells"];
    [self didChangeValueForKey:@"paddedCellSize"];
}

- (void)recalculatePaddedLevelSeparatorSize
{
    [self willChangeValueForKey:@"paddedLevelSeparatorSize"];
    paddedLevelSeparatorSize_.width = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right - self.levelInsets.left - self.levelInsets.right;
    paddedLevelSeparatorSize_.height = self.levelSeparatorHeight + self.levelSeparatorInsets.top + self.levelSeparatorInsets.bottom;
    [self didChangeValueForKey:@"paddedLevelSeparatorSize"];
}

- (void)recalculatePaddedAreaHeaderSize
{
    [self willChangeValueForKey:@"paddedAreaHeaderSize"];
    paddedAreaHeaderSize_.width = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right;
    paddedAreaHeaderSize_.height = self.areaHeaderHeight + self.areaHeaderInsets.top + self.areaHeaderInsets.bottom;
    [self didChangeValueForKey:@"paddedAreaHeaderSize"];
}

- (NSUInteger)heightInCellsForContentAtLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    NSUInteger numCells = [self numberOfItemsAtLevel:level inArea:area];
    return ceil((CGFloat)numCells / (CGFloat)self.contentWidthInCells);
}

- (void)reloadData
{
    NSUInteger numAreas = 1;
    if (flags_.dataSourceNumberOfAreasInTableView)
        numAreas = [self.dataSource numberOfAreasInTableView:self];
    self.items = [NSMutableArray arrayWithCapacity:numAreas];
    self.areaHeaders = [NSMutableArray arrayWithCapacity:numAreas];
    self.levelSeparators = [NSMutableArray array];
    self.relatedIndexPaths = [NSMutableDictionary dictionary];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        UIView *header = nil;
        if (flags_.delegateViewForHeaderInArea)
            header = [self.delegate relationalTableView:self viewForHeaderInArea:i];
        else
        {
            header = [[[UILabel alloc] init] autorelease];
            header.backgroundColor = [UIColor grayColor];
            if (flags_.dataSourceTitleForHeaderInArea)
                ((UILabel *)header).text = [self.dataSource relationalTableView:self titleForHeaderInArea:i];
        }
        [self.areaHeaders addObject:header];
        NSUInteger numLevels = 1;
        if (flags_.dataSourceNumberOfLevelsInArea)
            numLevels = [self.dataSource relationalTableView:self numberOfLevelsInArea:i];
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
            if (flags_.dataSourceNumberOfItemsAtLevelInArea)
                numItems = [self.dataSource relationalTableView:self numberOfItemsAtLevel:j inArea:i];
            NSMutableArray *itemsInLevel = [NSMutableArray arrayWithCapacity:numItems];
            for (NSUInteger k = 0; k < numItems; ++k)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:k atLevel:j inArea:i];
                ECRelationalTableViewCell *cell = nil;
                if (flags_.dataSourceCellForItemAtIndexPath)
                    cell = [self.dataSource relationalTableView:self cellForItemAtIndexPath:indexPath];
                if (!cell)
                    continue;
                UIPanGestureRecognizer *cellPanGestureRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellPanGesture:)] autorelease];
                [cell addGestureRecognizer:cellPanGestureRecognizer];
                cell.exclusiveTouch = YES;
                [itemsInLevel addObject:cell];
                if (flags_.dataSourceRelatedIndexPathsForItemAtIndexPath)
                    [self.relatedIndexPaths setObject:[self.dataSource relationalTableView:self relatedIndexPathsForItemAtIndexPath:indexPath] forKey:indexPath];
            }
            [levels addObject:itemsInLevel];
        }
        [self.items addObject:levels];
    }
    if (![self.relatedIndexPaths count])
        self.relatedIndexPaths = nil;
    flags_.needsLayoutSubviews = YES;
    flags_.needsReloadData = NO;
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
    UIEdgeInsets tableInsets = self.tableInsets;
    CGFloat x = tableInsets.left;
    CGFloat y = tableInsets.top;
    y +=  areaHeaderHeight * area;
    for (NSUInteger i = 0; i < area; ++i)
        for (NSUInteger j = 0; j < [self numberOfLevelsInArea:i]; ++j)
        {
            // if the table is not editing, the is no separator after the last level
            if (j == 0 && !flags_.isEditing)
                y -= levelSeparatorHeight;
            // if the table is editing, there is a separator before each level
            if (flags_.isEditing)
                y += levelSeparatorHeight;
            y += [self heightInCellsForContentAtLevel:j inArea:i] * cellHeight;
            y += self.levelInsets.top + self.levelInsets.bottom;
            y += levelSeparatorHeight;
        }
    CGFloat width = self.bounds.size.width - tableInsets.left - tableInsets.right;
    CGFloat height = areaHeaderHeight;
    for (NSUInteger j = 0; j < [self numberOfLevelsInArea:area]; ++j)
    {
        // if the table is not editing, the is no separator after the last level
        if (j == 0 && !flags_.isEditing)
            height -= levelSeparatorHeight;
        // if the table is editing, there is a separator before each level
        if (flags_.isEditing)
            height += levelSeparatorHeight;
        height += [self heightInCellsForContentAtLevel:j inArea:area] * cellHeight;
        height += self.levelInsets.top + self.levelInsets.bottom;
        height += levelSeparatorHeight;
    }
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForHeaderInAreaRect:(CGRect)areaRect
{
    CGFloat x = areaRect.origin.x + self.areaHeaderInsets.left;
    CGFloat y = areaRect.origin.y + self.areaHeaderInsets.top;
    CGFloat width = self.paddedAreaHeaderSize.width - self.areaHeaderInsets.left - self.areaHeaderInsets.right;
    CGFloat height = self.paddedAreaHeaderSize.height - self.areaHeaderInsets.top - self.areaHeaderInsets.bottom;
    return (CGRect){ (CGPoint){x, y} , (CGSize){width, height}};
}

- (CGRect)rectForHeaderInArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    return [self rectForHeaderInAreaRect:areaRect];
}

- (CGRect)rectForLevel:(NSUInteger)level inArea:(NSUInteger)area inAreaRect:(CGRect)areaRect
{
    CGFloat x = areaRect.origin.x + self.levelInsets.left;
    CGFloat y = areaRect.origin.y + self.areaHeaderInsets.top + self.paddedAreaHeaderSize.height + self.areaHeaderInsets.bottom;
    y += (self.levelInsets.top + self.levelInsets.bottom) * level;
    for (NSUInteger i = 0; i < level; ++i)
    {
        y += [self heightInCellsForContentAtLevel:i inArea:area];
        y += paddedLevelSeparatorSize_.height;
    }
    y += self.levelInsets.top;
    CGFloat width = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right - self.levelInsets.left - self.levelInsets.right;
    CGFloat height = [self heightInCellsForContentAtLevel:level inArea:area] * self.paddedCellSize.height;
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    return [self rectForLevel:level inArea:area inAreaRect:areaRect];
}

- (CGRect)rectForLevelSeparatorInLevelRect:(CGRect)levelRect isTopSeparator:(BOOL)isTopSeparator
{
    CGFloat x = levelRect.origin.x + self.levelSeparatorInsets.left;
    CGFloat y;
    if (isTopSeparator)
        y = levelRect.origin.y + self.levelSeparatorInsets.top;
    else
        y = levelRect.origin.y + levelRect.size.height - self.levelSeparatorInsets.bottom;
    CGFloat height = self.levelSeparatorHeight;
    CGFloat width = self.paddedLevelSeparatorSize.width - self.levelSeparatorInsets.left - self.levelSeparatorInsets.right;
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForItem:(NSUInteger)item inLevelRect:(CGRect)levelRect
{
    CGFloat x = levelRect.origin.x + self.cellInsets.left;
    CGFloat y = levelRect.origin.y + self.cellInsets.top;
    NSUInteger row = item / self.contentWidthInCells;
    NSUInteger column = item % self.contentWidthInCells;
    x += column * self.paddedCellSize.width;
    y += row * self.paddedCellSize.height;
    return (CGRect){ (CGPoint){x, y}, self.cellSize};
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
    if (!flags_.needsLayoutSubviews)
        return;
    if (flags_.needsReloadData)
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
                if (!flags_.isEditing)
                    levelSeparator.alpha = 0.0;
                else
                    levelSeparator.alpha = 1.0;
            }
            ++levelSeparatorIndex;
            for (NSUInteger k = 0; k < numItems; ++k)
            {
                NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:k atLevel:j inArea:i];
                ECRelationalTableViewCell *cell = [self cellForItemAtIndexPath:itemIndexPath];
                [self.rootView addSubview:cell];
                cell.frame = [self rectForItem:k inLevelRect:levelRect];
            }
            if (numItems)
            {
                levelSeparator = [self.levelSeparators objectAtIndex:levelSeparatorIndex];
                if (![levelSeparator superview])
                    [self.rootView addSubview:levelSeparator];
                levelSeparator.frame = [self rectForLevelSeparatorInLevelRect:levelRect isTopSeparator:NO];
                if (j == numLevels - 1 && !flags_.isEditing)
                    levelSeparator.alpha = 0.0;
                else if (j == numLevels - 1)
                    levelSeparator.alpha = 1.0;
            }
            ++levelSeparatorIndex;
        }
    }
    CGRect lastAreaFrame = [self rectForArea:numAreas - 1];
    self.scrollView.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height + self.tableInsets.bottom);
    flags_.needsLayoutSubviews = NO;
}

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
    CGPoint contentOffset = [self.scrollView contentOffset];
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

- (void)handleTapGesture:(UIGestureRecognizer *)tapGestureRecognizer
{
    if (!flags_.delegateDidSelectItem)
        return;
    if (flags_.isEditing)
        return;
    if (![tapGestureRecognizer state] == UIGestureRecognizerStateEnded)
        return;
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:[tapGestureRecognizer locationInView:self]];
    [self.delegate relationalTableView:self didSelectItemAtIndexPath:indexPath];
}

- (void)handleCellPanGesture:(UIGestureRecognizer *)panGestureRecognizer
{
    if (!flags_.isEditing)
        return;
    switch ([panGestureRecognizer state]) {
        case UIGestureRecognizerStateBegan:
            flags_.isDragging = YES;
            self.dragSource = [self indexPathForItemAtPoint:[panGestureRecognizer locationInView:self]];
            self.cellBeingDragged = [self cellForItemAtIndexPath:self.dragSource];
            break;
            
        case UIGestureRecognizerStateChanged:
            self.cellBeingDragged.center = [panGestureRecognizer locationInView:self];
            break;
            
        case UIGestureRecognizerStateEnded:
            flags_.isDragging = NO;
            self.cellBeingDragged = nil;
            break;
            
        default:
            break;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = nil;
    if (flags_.isEditing)
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
