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
        unsigned int needsLayoutSubviews:1
    } flags_;
}
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIView *rootView;
- (void)recalculatePaddedCellSizeAndContentWidthInCells;
- (void)recalculatePaddedAreaHeaderSize;
@property (nonatomic, retain) NSMutableArray *areas;
@end

@implementation ECRelationalTableView

@synthesize scrollView = scrollView_;
@synthesize rootView = rootView_;
@synthesize delegate = delegate_;
@synthesize dataSource = dataSource_;
@synthesize tableInsets = tableInsets_;
@synthesize cellInsets = cellInsets_;
@synthesize levelInsets = levelInsets_;
@synthesize areaHeaderInsets = areaHeaderInsets_;
@synthesize areaFooterInsets = areaFooterInsets_;
@synthesize cellSize = cellSize_;
@synthesize paddedCellSize = paddedCellSize_;
@synthesize contentWidthInCells = contentWidthInCells_;
@synthesize areaHeaderHeight = areaHeaderHeight_;
@synthesize paddedAreaHeaderSize = paddedAreaHeaderSize_;
@synthesize areaFooterHeight = areaFooterHeight_;
@synthesize paddedAreaFooterSize = paddedAreaFooterSize_;
@synthesize backgroundView = backgroundView_;
@synthesize tableHeaderView = tableHeaderView_;
@synthesize tableFooterView = tableFooterView_;
@synthesize editing = editing_;
@synthesize allowsSelection = allowsSelection_;
@synthesize allowsSelectionDuringEditing = allowsSelectionDuringEditing_;
@synthesize itemGrowthDirection = itemGrowthDirection_;
@synthesize itemWrapDirection = itemWrapDirection_;
@synthesize levelGrowthDirection = levelGrowthDirection_;
@synthesize areas = areas_;

- (void)setDelegate:(id<ECRelationalTableViewDelegate>)delegate
{
    if (delegate == delegate_)
        return;
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
}

- (void)setDataSource:(id<ECRelationalTableViewDataSource>)dataSource
{
    if (dataSource == dataSource_)
        return;
    dataSource_ = dataSource;
    flags_.dataSourceNumberOfLevelsInArea = [dataSource respondsToSelector:@selector(relationalTableView:numberOfLevelsInArea:)];
    flags_.dataSourceNumberOfItemsAtLevelInArea = [dataSource respondsToSelector:@selector(relationalTableView:numberOfItemsAtLevel:inArea:)];
    flags_.dataSourceCellForItemAtIndexPath = [dataSource respondsToSelector:@selector(relationalTableView:cellForItemAtIndexPath:)];
    flags_.dataSourceNumberOfAreasInTableView = [dataSource respondsToSelector:@selector(numberOfAreasInTableView:)];
    flags_.dataSourceTitleForHeaderInArea = [dataSource respondsToSelector:@selector(relationalTableView:titleForHeaderInArea:)];
    flags_.dataSourceTitleForFooterInArea = [dataSource respondsToSelector:@selector(relationalTableView:titleForFooterInArea:)];
    flags_.dataSourceCanEditItem = [dataSource respondsToSelector:@selector(relationalTableView:canEditItemAtIndexPath:)];
    flags_.dataSourceCanMoveItem = [dataSource respondsToSelector:@selector(relationalTableView:canMoveItemAtIndexPath:)];
    flags_.dataSourceCommitEditingStyle = [dataSource respondsToSelector:@selector(relationalTableView:commitEditingStyle:forItemAtIndexPath:)];
    flags_.dataSourceMoveItem = [dataSource respondsToSelector:@selector(relationalTableView:moveItemAtIndexPath:toIndexPath:)];
}

- (void)setTableInsets:(UIEdgeInsets)tableInsets
{
    tableInsets_ = tableInsets;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
    [self recalculatePaddedAreaHeaderSize];
}

- (void)setCellInsets:(UIEdgeInsets)cellInsets
{
    cellInsets_ = cellInsets;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
}

- (void)setAreaHeaderInsets:(UIEdgeInsets)areaHeaderInsets
{
    areaHeaderInsets_ = areaHeaderInsets;
    [self recalculatePaddedAreaHeaderSize];
}

- (void)setLevelInsets:(UIEdgeInsets)levelInsets
{
    levelInsets_ = levelInsets;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
}

- (void)setCellSize:(CGSize)cellSize
{
    cellSize_ = cellSize;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
}

- (void)dealloc
{
    self.backgroundView = nil;
    self.tableHeaderView = nil;
    self.tableFooterView = nil;
    self.scrollView = nil;
    self.rootView = nil;
    self.areas = nil;
    [super dealloc];
}

static id init(ECRelationalTableView *self)
{
    self.scrollView = [[[UIScrollView alloc] initWithFrame:self.bounds] autorelease];
    [self addSubview:self.scrollView];
    self.rootView = [[[UIView alloc] init] autorelease];
    [self.scrollView addSubview:self.rootView];
    self->cellSize_ = CGSizeMake(120.0, 30.0);
    self->tableInsets_ = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    self->cellInsets_ = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
    self->levelInsets_ = UIEdgeInsetsMake(10.0, 0.0, 10.0, 0.0);
    self->areaHeaderHeight_ = 20.0;
    [self recalculatePaddedCellSizeAndContentWidthInCells];
    [self recalculatePaddedAreaHeaderSize];
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
    UIEdgeInsets cellInsets = self.cellInsets;
    CGSize size = self.cellSize;
    size.width += cellInsets.left + cellInsets.right;
    size.height += cellInsets.top + cellInsets.bottom;
    CGFloat netWidth = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right - self.levelInsets.left - self.levelInsets.right;
    contentWidthInCells_ = netWidth / size.width;
    size.width = netWidth / (CGFloat)contentWidthInCells_;
    paddedCellSize_ = size;
}

- (void)recalculatePaddedAreaHeaderSize
{
    CGSize size = CGSizeZero;
    size.width = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right;
    size.height = self.areaHeaderHeight + self.areaHeaderInsets.top + self.areaHeaderInsets.bottom;
    paddedAreaHeaderSize_ = size;
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
    self.areas = [NSMutableArray arrayWithCapacity:numAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        NSUInteger numLevels = 1;
        if (flags_.dataSourceNumberOfLevelsInArea)
            numLevels = [self.dataSource relationalTableView:self numberOfLevelsInArea:i];
        NSMutableArray *levels = [NSMutableArray arrayWithCapacity:numLevels];
        for (NSUInteger j = 0; j < numLevels; ++j)
        {
            NSUInteger numItems = 0;
            if (flags_.dataSourceNumberOfItemsAtLevelInArea)
                numItems = [self.dataSource relationalTableView:self numberOfItemsAtLevel:j inArea:i];
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:numItems];
            for (NSUInteger k = 0; k < numItems; ++k)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:k atLevel:j inArea:i];
                [items addObject:[self.dataSource relationalTableView:self cellForItemAtIndexPath:indexPath]];
            }
            [levels addObject:items];
        }
        [self.areas addObject:levels];
    }
    flags_.needsLayoutSubviews = YES;
}

- (NSUInteger)numberOfAreas
{
    return [self.areas count];
}

- (NSUInteger)numberOfLevelsInArea:(NSUInteger)area
{
    return [[self.areas objectAtIndex:area] count];
}

- (NSUInteger)numberOfItemsAtLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    return [[[self.areas objectAtIndex:area] objectAtIndex:level] count];
}

- (CGRect)rectForArea:(NSUInteger)area
{
    CGFloat areaHeaderHeight = self.paddedAreaHeaderSize.height;
    CGFloat cellHeight = self.paddedCellSize.height;
    UIEdgeInsets tableInsets = self.tableInsets;
    CGFloat x = tableInsets.left;
    CGFloat y = tableInsets.top;
    y +=  areaHeaderHeight * area;
    for (NSUInteger i = 0; i < area; ++i)
        for (NSUInteger j = 0; j < [self numberOfLevelsInArea:i]; ++j)
            y += [self heightInCellsForContentAtLevel:j inArea:i] * cellHeight;
    CGFloat width = self.bounds.size.width - tableInsets.left - tableInsets.right;
    CGFloat height = areaHeaderHeight;
    for (NSUInteger j = 0; j < [self numberOfLevelsInArea:area]; ++j)
        height += [self heightInCellsForContentAtLevel:j inArea:area] * cellHeight;
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForHeaderInArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    CGFloat x = areaRect.origin.x + self.areaHeaderInsets.left;
    CGFloat y = areaRect.origin.y + self.areaHeaderInsets.top;
    return (CGRect){ (CGPoint){x, y} , self.paddedAreaHeaderSize };
}

- (CGRect)rectForLevel:(NSUInteger)level inArea:(NSUInteger)area
{
    CGRect areaRect = [self rectForArea:area];
    CGFloat x = areaRect.origin.x + self.levelInsets.left;
    CGFloat y = areaRect.origin.y + self.areaHeaderInsets.top + self.paddedAreaHeaderSize.height + self.areaHeaderInsets.bottom;
    y += (self.levelInsets.top + self.levelInsets.bottom) * level;
    for (NSUInteger i = 0; i < level; ++i)
        y += [self heightInCellsForContentAtLevel:i inArea:area];
    y += self.levelInsets.top;
    CGFloat width = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right - self.levelInsets.left - self.levelInsets.right;
    CGFloat height = [self heightInCellsForContentAtLevel:level inArea:area];
    return CGRectMake(x, y, width, height);
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect levelRect = [self rectForLevel:indexPath.level inArea:indexPath.area];
    CGFloat x = levelRect.origin.x + self.cellInsets.left;
    CGFloat y = levelRect.origin.y + self.cellInsets.top;
    NSUInteger row = indexPath.item / self.contentWidthInCells;
    NSUInteger column = indexPath.item % self.contentWidthInCells;
    x += column * self.paddedCellSize.width;
    y += row * self.paddedCellSize.height;
    return (CGRect){ (CGPoint){x, y}, self.cellSize};
}

- (ECRelationalTableViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [[[self.areas objectAtIndex:indexPath.area] objectAtIndex:indexPath.level] objectAtIndex:indexPath.item];
}

- (void)layoutSubviews
{
    if (!flags_.needsLayoutSubviews)
        return;
    NSUInteger numAreas = [self numberOfAreas];
    for (NSUInteger i = 0; i < numAreas; ++i)
    {
        UIView *header = nil;
        if (flags_.delegateViewForHeaderInArea)
            header = [self.delegate relationalTableView:self viewForHeaderInArea:i];
        else if (flags_.dataSourceTitleForHeaderInArea)
        {
            header = [[[UILabel alloc] init] autorelease];
            ((UILabel *)header).text = [self.dataSource relationalTableView:self titleForHeaderInArea:i];
        }
        if (![header superview])
        {
            [self.rootView addSubview:header];
        }
        header.backgroundColor = [UIColor grayColor];
        header.frame = [self rectForHeaderInArea:i];
        for (NSUInteger j = 0; j < [self numberOfLevelsInArea:j]; ++j)
        {
            for (NSUInteger k = 0; k < [self numberOfItemsAtLevel:j inArea:i]; ++k)
            {
                NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:k atLevel:j inArea:i];
                ECRelationalTableViewCell *cell = [self cellForItemAtIndexPath:itemIndexPath];
                [self.rootView addSubview:cell];
                cell.frame = [self rectForItemAtIndexPath:itemIndexPath];
            }
        }
    }
    CGRect lastAreaFrame = [self rectForArea:numAreas - 1];
    self.scrollView.contentSize = CGSizeMake(self.bounds.size.width, lastAreaFrame.origin.y + lastAreaFrame.size.height + self.tableInsets.bottom);
    flags_.needsLayoutSubviews = NO;
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
