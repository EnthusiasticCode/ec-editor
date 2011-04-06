//
//  ECRelationalTableView.m
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECRelationalTableView.h"
#import "ECRelationalTableViewItem.h"

@interface ECRelationalTableView ()
@property (nonatomic, retain) NSMutableDictionary *cellCache;
- (void)recalculatePaddedCellSizeAndWidthInCells;
- (void)recalculatePaddedSectionHeaderSize;
@end

@implementation ECRelationalTableView

@synthesize tableInsets = tableInsets_;
@synthesize cellInsets = cellInsets_;
@synthesize indentInsets = indentInsets_;
@synthesize sectionHeaderInsets = sectionHeaderInsets_;
@synthesize sectionFooterInsets = sectionFooterInsets_;
@synthesize cellSize = cellSize_;
@synthesize paddedCellSize = paddedCellSize_;
@synthesize paddedSectionHeaderSize = paddedSectionHeaderSize_;
@synthesize widthInCells = widthInCells_;
@synthesize cellCache = cellCache_;

- (void)setTableInsets:(UIEdgeInsets)tableInsets
{
    tableInsets_ = tableInsets;
    [self recalculatePaddedCellSizeAndWidthInCells];
    [self recalculatePaddedSectionHeaderSize];
}

- (void)setCellInsets:(UIEdgeInsets)cellInsets
{
    cellInsets_ = cellInsets;
    [self recalculatePaddedCellSizeAndWidthInCells];
}

- (void)setSectionHeaderInsets:(UIEdgeInsets)sectionHeaderInsets
{
    sectionHeaderInsets_ = sectionHeaderInsets;
    [self recalculatePaddedSectionHeaderSize];
}

- (void)setCellSize:(CGSize)cellSize
{
    cellSize_ = cellSize;
    [self recalculatePaddedCellSizeAndWidthInCells];
}

- (void)dealloc
{
    self.cellCache = nil;
    [super dealloc];
}

static ECRelationalTableView *init(ECRelationalTableView *self)
{
    self.rowHeight = 30.0;
    self.backgroundColor = [UIColor blackColor];
    self->cellSize_ = CGSizeMake(100.0, 100.0);
    self->tableInsets_ = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    self->cellInsets_ = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
    self.cellCache = [NSMutableDictionary dictionary];
    [self recalculatePaddedCellSizeAndWidthInCells];
    [self recalculatePaddedSectionHeaderSize];
    return self;
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (!self)
        return nil;
    return init(self);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self)
        return nil;
    return init(self);
}


- (void)recalculatePaddedCellSizeAndWidthInCells
{
    UIEdgeInsets cellInsets = self.cellInsets;
    CGSize size = self.cellSize;
    size.width += cellInsets.left + cellInsets.right;
    size.height += cellInsets.top + cellInsets.bottom;
    CGFloat netWidth = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right;
    widthInCells_ = netWidth / size.width;
    size.width = netWidth / (CGFloat)widthInCells_;
    paddedCellSize_ = CGSizeMake(size.width, size.width);
}

- (void)recalculatePaddedSectionHeaderSize
{
    CGSize size = CGSizeZero;
    size.width = self.bounds.size.width - self.tableInsets.left - self.tableInsets.right - self.sectionHeaderInsets.left - self.sectionHeaderInsets.right;
    size.height = self.sectionHeaderHeight + self.sectionHeaderInsets.top + self.sectionHeaderInsets.bottom;
    paddedSectionHeaderSize_ = size;
}

- (NSInteger)heightInCellsForContentInSection:(NSInteger)section
{
    NSInteger numCells = [self numberOfRowsInSection:section];
    return ceil((CGFloat)numCells / (CGFloat)[self widthInCells]);
}

- (CGRect)rectForHeaderInSection:(NSInteger)section
{
    CGRect sectionRect = [self rectForSection:section];
    CGFloat x = sectionRect.origin.x + self.sectionHeaderInsets.left;
    CGFloat y = sectionRect.origin.y + self.sectionHeaderInsets.top;
    return (CGRect){ (CGPoint){x, y} , (CGSize){[self paddedSectionHeaderSize].width, self.sectionHeaderHeight} };
}

- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGRect sectionHeaderRect = [self rectForHeaderInSection:indexPath.section];
    CGFloat x = self.tableInsets.left + self.cellInsets.left;
    CGFloat y = sectionHeaderRect.origin.y + sectionHeaderRect.size.height + self.sectionHeaderInsets.bottom + self.cellInsets.top;
    NSInteger row = indexPath.row / self.widthInCells;
    NSInteger column = indexPath.row % self.widthInCells;
    x += row * self.paddedCellSize.width;
    y += column * self.paddedCellSize.height;
    return (CGRect){ (CGPoint){x, y}, self.cellSize};
}

- (CGRect)rectForSection:(NSInteger)section
{
    CGFloat sectionHeaderHeight = self.paddedSectionHeaderSize.height;
    CGFloat cellHeight = self.paddedCellSize.height;
    UIEdgeInsets tableInsets = self.tableInsets;
    CGFloat x = tableInsets.left;
    CGFloat y = tableInsets.top;
    y +=  sectionHeaderHeight * section;
    for (NSInteger i = 0; i < section; ++i)
        y += [self heightInCellsForContentInSection:i] * cellHeight;
    CGFloat width = self.bounds.size.width - tableInsets.left - tableInsets.right;
    CGFloat height = sectionHeaderHeight;
    height += [self heightInCellsForContentInSection:section] * cellHeight;
    return CGRectMake(x, y, width, height);
}

- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // sometimes gets called with nil index path
    if (!indexPath)
        return nil;
    NSRange indexPathRange = NSMakeRange(indexPath.section, indexPath.row);
    UITableViewCell *cell = nil;
    cell = [self.cellCache objectForKey:[NSValue valueWithRange:indexPathRange]];
    if (!cell)
    {
        if ([self.dataSource respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)])
            cell = [self.dataSource tableView:self cellForRowAtIndexPath:indexPath];
        if (cell)
            [self.cellCache setObject:cell forKey:[NSValue valueWithRange:indexPathRange]];
    }
    return cell;
}

- (void)layoutSubviews
{
//    [super layoutSubviews];
    NSInteger numSections = [self numberOfSections];
    for (NSInteger i = 0; i < numSections; ++i)
    {
        UIView *header = nil;
        if ([self.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)])
            header = [self.delegate tableView:self viewForHeaderInSection:i];
        else if ([self.dataSource respondsToSelector:@selector(tableView:titleForHeaderInSection:)])
        {
            header = [[[UILabel alloc] init] autorelease];
            ((UILabel *)header).text = [self.dataSource tableView:self titleForHeaderInSection:i];
        }
        if (![header superview])
        {
            [self addSubview:header];
        }
        header.backgroundColor = [UIColor grayColor];
        header.frame = [self rectForHeaderInSection:i];
        for (NSInteger j = 0; j < [self numberOfRowsInSection:i]; ++j)
        {
            NSIndexPath *rowIndexPath = [NSIndexPath indexPathForRow:j inSection:i];
//            NSInteger itemDepth = 0;
//            if ([self.delegate respondsToSelector:@selector(tableView:indentationLevelForRowAtIndexPath:)])
//                itemDepth = [self.delegate tableView:self indentationLevelForRowAtIndexPath:rowIndexPath];
            UITableViewCell *cell = [self cellForRowAtIndexPath:rowIndexPath];
            [self addSubview:cell];
            cell.frame = [self rectForRowAtIndexPath:rowIndexPath];
        }
    }
    CGRect lastSectionFrame = [self rectForSection:numSections - 1];
    self.contentSize = CGSizeMake(self.bounds.size.width, lastSectionFrame.origin.y + lastSectionFrame.size.height + self.tableInsets.bottom);
}

@end
