//
//  ECGridView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ECGridView.h"

@interface ECGridView (/*Private Methods*/)

- (void)_enqueueReusableCells:(NSArray *)cells;
- (void)_updateContentSize;

@end

#pragma mark -

@implementation ECGridView {
    NSInteger _cellCount;
    NSMutableArray *_cells;
    NSRange _cellsLoadedRange;
    
    NSMutableDictionary *_reusableCells;
    
    struct {
        unsigned delegateHasWillSelectCellAtIndex : 1;
        unsigned delegateHasDidSelectCellAtIndex : 1;
        unsigned delegateHasWillDeselectCellAtIndex : 1;
        unsigned delegateHasDidDeselectCellAtIndex : 1;
    } _flags;
}

#pragma mark Managing the Delegate and the Data Source

@dynamic delegate;
@synthesize dataSource;

- (void)setDelegate:(id<ECGridViewDelegate>)delegate
{
    if (delegate != self.delegate)
    {
        [super setDelegate:delegate];
        
        _flags.delegateHasWillSelectCellAtIndex = [delegate respondsToSelector:@selector(gridView:willSelectCellAtIndex:)];
        _flags.delegateHasDidSelectCellAtIndex = [delegate respondsToSelector:@selector(gridView:didSelectCellAtIndex:)];
        _flags.delegateHasWillDeselectCellAtIndex = [delegate respondsToSelector:@selector(gridView:willDeselectCellAtIndex:)];
        _flags.delegateHasDidDeselectCellAtIndex = [delegate respondsToSelector:@selector(gridView:didDeselectCellAtIndex:)];
    }
}

- (void)setDataSource:(id<ECGridViewDataSource>)value
{
    if (value == dataSource)
        return;
    [self willChangeValueForKey:@"dataSource"];
    dataSource = value;
    [self reloadData];
    [self didChangeValueForKey:@"dataSource"];
}

#pragma mark Configuring a Grid View

@synthesize rowHeight, columnNumber;
@synthesize backgroundView;

- (void)setRowHeight:(CGFloat)value
{
    ECASSERT(value > 0.0);
    
    if (value == rowHeight)
        return;
    [self willChangeValueForKey:@"rowHeight"];
    rowHeight = value;
    [self _updateContentSize];
    [self didChangeValueForKey:@"rowHeight"];
}

- (void)setColumnNumber:(NSUInteger)value
{
    ECASSERT(value > 0);
    
    if (value == columnNumber)
        return;
    [self willChangeValueForKey:@"columnNumber"];
    columnNumber = value;
    [self setNeedsLayout];
    [self didChangeValueForKey:@"columnNumber"];
}

- (void)setBackgroundView:(UIView *)value
{
    if (value == backgroundView)
        return;
    [self willChangeValueForKey:@"backgroundView"];
    [backgroundView removeFromSuperview];
    backgroundView = value;
    if (backgroundView)
        [self insertSubview:backgroundView atIndex:0];
    [self didChangeValueForKey:@"backgroundView"];
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    if (!_reusableCells)
        return nil;
    
    NSMutableArray *reusableArray = [_reusableCells objectForKey:identifier];
    if (!reusableArray)
        return nil;
    
    id result = [reusableArray objectAtIndex:0];
    [reusableArray removeObjectAtIndex:0];
    return result;
}

- (void)_enqueueReusableCells:(NSArray *)cells
{
    if (!_reusableCells)
        _reusableCells = [NSMutableDictionary new];
    
    [cells enumerateObjectsUsingBlock:^(ECGridViewCell *cell, NSUInteger idx, BOOL *stop) {
        ECASSERT(cell && cell.reuseIdentifier);
        
        [cell prepareForReuse];
        [cell removeFromSuperview];
        
        NSMutableArray *reuseArray = [_reusableCells objectForKey:cell.reuseIdentifier];
        if (!reuseArray)
        {
            reuseArray = [NSMutableArray new];
            [_reusableCells setObject:reuseArray forKey:cell.reuseIdentifier];
        }
        
        [reuseArray addObject:cell];
    }];
}

#pragma mark Inserting, Deleting, and Moving Cells


#pragma mark Reloading the Grid View

- (void)reloadData
{
    ECASSERT(self.dataSource);
    
    _cells = nil;
    _cellsLoadedRange = NSMakeRange(0, 0);
    
    _cellCount = [self.dataSource numberOfCellsForGridView:self];
    [self _updateContentSize];
    
    [self scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    [self setNeedsLayout];
}

#pragma mark View Methods

static void _init(ECGridView *self)
{
    self->rowHeight = 200;
    self->columnNumber = 2;
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    _init(self);
    return self;
}

- (void)setContentSize:(CGSize)contentSize
{
    ECASSERT(NO && "Content size cannot be set manually");
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    const CGRect bounds = [self bounds];
    const NSUInteger columns = self.columnNumber;
    const CGSize cellSize = CGSizeMake(bounds.size.width / (CGFloat)columns, self.rowHeight);
    
    // Position background
    if (self.backgroundView)
    {
        self.backgroundView.frame = bounds;
    }
    
    // Load required cells
    if (bounds.origin.y < 0)
        return;
    NSRange cellsRequiredRange = NSIntersectionRange(NSMakeRange((NSUInteger)floorf(bounds.origin.y / cellSize.height) * columns, (NSUInteger)(ceilf(bounds.size.height / self.rowHeight) + 1) * columns), (NSRange){ 0, _cellCount });
    if (cellsRequiredRange.length && !NSEqualRanges(cellsRequiredRange, _cellsLoadedRange))
    {
        NSRange cellsReuseRange = NSIntersectionRange(cellsRequiredRange, _cellsLoadedRange);
        // Remove non visible cells
        NSRange reuseRange = NSMakeRange(0, cellsReuseRange.location - _cellsLoadedRange.location);
        if (reuseRange.length)
        {
            NSArray *cellsReuse = [_cells subarrayWithRange:reuseRange];
            reuseRange = NSMakeRange(cellsReuseRange.length + [cellsReuse count], [_cells count] - [cellsReuse count] - cellsReuseRange.length);
            [self _enqueueReusableCells:cellsReuse];
        }
        else
        {
            reuseRange = NSMakeRange(cellsReuseRange.length, [_cells count] - cellsReuseRange.length);
        }
        if (reuseRange.length)
        {
            [self _enqueueReusableCells:[_cells subarrayWithRange:reuseRange]];
        }
        // Create new cells array
        NSMutableArray *newCells = [NSMutableArray arrayWithCapacity:cellsRequiredRange.length];
        UIView *cell = nil;
        NSUInteger i;
        for (i = cellsRequiredRange.location; i < cellsReuseRange.location; ++i) 
        {
            cell = [self.dataSource gridView:self cellAtIndex:i];
            [newCells addObject:cell];
            [self insertSubview:cell atIndex:1];
        }
        if (cellsReuseRange.length)
        {
            [newCells addObjectsFromArray:[_cells subarrayWithRange:NSMakeRange(cellsReuseRange.location - _cellsLoadedRange.location, cellsReuseRange.length)]];
        }
        for (i = NSMaxRange(cellsReuseRange); i < NSMaxRange(cellsRequiredRange); ++i) {
            cell = [self.dataSource gridView:self cellAtIndex:i];
            [newCells addObject:cell];
            [self insertSubview:cell atIndex:1];
        }
        _cells = newCells;
        _cellsLoadedRange = cellsRequiredRange;
        
        // Layout cells
        __block CGRect cellFrame = (CGRect){ CGPointMake(bounds.origin.x, (CGFloat)(cellsRequiredRange.location / columns) * cellSize.height), cellSize };
        [_cells enumerateObjectsUsingBlock:^(UIView *cell, NSUInteger cellIndex, BOOL *stop) {
            if (cellIndex == 0)
            {
                cell.frame = cellFrame;
                return;
            }
            if (cellIndex % columns == 0)
            {
                cellFrame.origin.x = bounds.origin.x;
                cellFrame.origin.y += cellSize.height;
            }
            else
            {
                cellFrame.origin.x += cellSize.width;
            }
            cell.frame = cellFrame;
        }];
    }
}

#pragma mark - Private Methods

- (void)_updateContentSize
{
    [super setContentSize:CGSizeMake([self bounds].size.width, self.rowHeight * (_cellCount / self.columnNumber))];
}

@end

#pragma mark -

@implementation ECGridViewCell

#pragma mark Reusing Cells

@synthesize reuseIdentifier;
- (void)prepareForReuse {}

#pragma mark Accessing Views of the Cell Object

@synthesize contentView, backgroundView, selectedBackgroundView;

- (UIView *)contentView
{
    if (!contentView)
    {
        contentView = [[UIView alloc] initWithFrame:UIEdgeInsetsInsetRect([self bounds], self.contentInsets)];
        contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return contentView;
}

- (void)setBackgroundView:(UIView *)value
{
    if (value == backgroundView)
        return;
    [self willChangeValueForKey:@"backgroundView"];
    [backgroundView removeFromSuperview];
    backgroundView = value;
    backgroundView.frame = [self bounds];
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (backgroundView && !self.isSelected)
        [self insertSubview:backgroundView belowSubview:self.contentView];
    [self didChangeValueForKey:@"backgroundView"];
}

- (void)setSelectedBackgroundView:(UIView *)value
{
    if (value == selectedBackgroundView)
        return;
    [self willChangeValueForKey:@"selectedBackgroundView"];
    [selectedBackgroundView removeFromSuperview];
    selectedBackgroundView = value;
    selectedBackgroundView.frame = self.bounds;
    selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (selectedBackgroundView && self.isSelected)
        [self insertSubview:selectedBackgroundView belowSubview:self.contentView];
    [self didChangeValueForKey:@"selectedBackgroundView"];
}

#pragma mark Managing Cell Selection and Highlighting

@synthesize selected, highlighted, editing;

- (void)setSelected:(BOOL)value
{
    [self setSelected:value animated:NO];
}

- (void)setSelected:(BOOL)value animated:(BOOL)animated
{
    if (value == selected)
        return;
    [self willChangeValueForKey:@"selected"];
    UIView *fromView = (selected ? selectedBackgroundView : backgroundView);
    UIView *toView = (!selected ? selectedBackgroundView : backgroundView);
    selected = value;
    // TODO animate
    if (toView)
    {
        [fromView removeFromSuperview];
        [self addSubview:toView];
    }
    [self didChangeValueForKey:@"selected"];
}

- (void)setHighlighted:(BOOL)value
{
    [self setHighlighted:value animated:NO];
}

- (void)setHighlighted:(BOOL)value animated:(BOOL)animated
{
    if (value == highlighted)
        return;
    [self willChangeValueForKey:@"highlighted"];
    highlighted = value;
    // TODO animate
    [self didChangeValueForKey:@"highlighted"];
}

- (void)setEditing:(BOOL)value
{
    [self setEditing:value animated:NO];
}

- (void)setEditing:(BOOL)value animated:(BOOL)animated
{
    if (value == editing)
        return;
    [self willChangeValueForKey:@"editing"];
    editing = value;
    // TODO animate
    [self didChangeValueForKey:@"editing"];
}

#pragma mark Styling the Cell

@synthesize contentInsets;

- (void)setContentInsets:(UIEdgeInsets)value
{
    if (UIEdgeInsetsEqualToEdgeInsets(value, contentInsets))
        return;
    [self willChangeValueForKey:@"contentInsets"];
    contentInsets = value;
    self.contentView.frame = UIEdgeInsetsInsetRect([self bounds], contentInsets);
    [self didChangeValueForKey:@"contentInsets"];
}

#pragma mark View Methods

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)aReuseIdentifier
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    reuseIdentifier = aReuseIdentifier;
    [self addSubview:self.contentView];
    if (self.backgroundView)
        [self addSubview:self.backgroundView];
    return self;
}

@end