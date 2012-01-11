//
//  ECGridView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ECGridView.h"
#import <objc/runtime.h>

@interface ECGridView (/*Private Methods*/)

- (void)_enqueueReusableCells:(NSArray *)cells;
- (void)_updateContentSize;
- (ECGridViewCell *)_addSubviewCellAtIndex:(NSInteger)cellIndex;
- (void)_handleSelectionRecognizer:(UITapGestureRecognizer *)recognizer;

@end

#pragma mark -

@implementation ECGridView {
    NSInteger _cellCount;
    NSMutableArray *_cells;
    NSRange _cellsLoadedRange;
    NSMutableIndexSet *_selectedCells;
    NSMutableIndexSet *_selectedEditingCells;
    
    NSMutableDictionary *_reusableCells;
    NSMutableArray *_updateBatches;
    
    UITapGestureRecognizer *_selectionGestureRecognizer;
    
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
    if (![reusableArray count])
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

#pragma mark Managing Selections

@synthesize allowSelection, allowMultipleSelection, allowSelectionDuringEditing, allowMultipleSelectionDuringEditing;

- (void)setAllowSelection:(BOOL)value
{
    if (value == allowSelection)
        return;
    [self willChangeValueForKey:@"allowSelection"];
    allowSelection = value;
    if (!_selectionGestureRecognizer)
    {
        _selectionGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleSelectionRecognizer:)];
        [self addGestureRecognizer:_selectionGestureRecognizer];
    }
    if (!self.isEditing)
        _selectionGestureRecognizer.enabled = value;
    [self didChangeValueForKey:@"allowSelection"];
}

- (void)setAllowMultipleSelection:(BOOL)value
{
    if (value == allowMultipleSelection)
        return;
    [self willChangeValueForKey:@"allowMultipleSelection"];
    allowMultipleSelection = value;
    if (allowMultipleSelection && !self.allowSelection)
        self.allowSelection = YES;
    [self didChangeValueForKey:@"allowMultipleSelection"];
}

- (void)setAllowSelectionDuringEditing:(BOOL)value
{
    if (value == allowSelectionDuringEditing)
        return;
    [self willChangeValueForKey:@"allowSelectionDuringEditing"];
    allowSelectionDuringEditing = value;
    if (!_selectionGestureRecognizer)
    {
        _selectionGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleSelectionRecognizer:)];
        [self addGestureRecognizer:_selectionGestureRecognizer];
    }
    if (self.isEditing)
        _selectionGestureRecognizer.enabled = value;
    [self didChangeValueForKey:@"allowSelectionDuringEditing"];
}

- (void)setAllowMultipleSelectionDuringEditing:(BOOL)value
{
    if (value == allowMultipleSelectionDuringEditing)
        return;
    [self willChangeValueForKey:@"allowMultipleSelectionDuringEditing"];
    allowMultipleSelectionDuringEditing = value;
    if (allowMultipleSelectionDuringEditing && !self.allowSelectionDuringEditing)
        self.allowSelectionDuringEditing = YES;
    [self didChangeValueForKey:@"allowMultipleSelectionDuringEditing"];
}

- (NSInteger)indexForSelectedCell
{
    if ([_selectedCells count] != 1)
        return -1;
    return [_selectedCells firstIndex];
}

- (NSIndexSet *)indexesForSelectedCells
{
    return [_selectedCells copy];
}

- (void)selectCellAtIndex:(NSInteger)cellIndex animated:(BOOL)animated
{
    if (self.isEditing)
    {
        // Exit if already selected
        if ([_selectedEditingCells containsIndex:cellIndex])
            return;
        
        // Deselect others if multiple selection not allowed
        if (!self.allowMultipleSelectionDuringEditing)
        {
            NSIndexSet *selected = [_selectedEditingCells copy];
            [selected enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [self deselectCellAtIndex:idx animated:animated];
            }];
        }
        
        // Add selection
        if (!_selectedEditingCells)
            _selectedEditingCells = [NSMutableIndexSet new];
        [_selectedEditingCells addIndex:cellIndex];
    }
    else
    {
        // Exit if already selected
        if ([_selectedCells containsIndex:cellIndex])
            return;
        
        // Deselect others if multiple selection not allowed
        if (!self.allowMultipleSelection)
        {
            NSIndexSet *selected = [_selectedCells copy];
            [selected enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [self deselectCellAtIndex:idx animated:animated];
            }];
        }
        
        // Add selection
        if (!_selectedCells)
            _selectedCells = [NSMutableIndexSet new];
        [_selectedCells addIndex:cellIndex];
    }

    if (_flags.delegateHasWillSelectCellAtIndex)
        [self.delegate gridView:self willSelectCellAtIndex:cellIndex];

    // Select cell if visible
    if (NSLocationInRange(cellIndex, _cellsLoadedRange))
    {
        ECGridViewCell *cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
        [cell setSelected:YES animated:animated];
    }
    
    if (_flags.delegateHasDidSelectCellAtIndex)
        [self.delegate gridView:self didSelectCellAtIndex:cellIndex];
}

- (void)deselectCellAtIndex:(NSInteger)cellIndex animated:(BOOL)animated
{
    if (self.isEditing)
    {
        if (![_selectedEditingCells containsIndex:cellIndex])
            return;
        [_selectedEditingCells removeIndex:cellIndex];
    }
    else
    {
        if (![_selectedCells containsIndex:cellIndex])
            return;
        [_selectedCells removeIndex:cellIndex];
    }
    
    if (_flags.delegateHasWillDeselectCellAtIndex)
        [self.delegate gridView:self willDeselectCellAtIndex:cellIndex];
    
    // Select cell if visible
    if (NSLocationInRange(cellIndex, _cellsLoadedRange))
    {
        ECGridViewCell *cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
        [cell setSelected:NO animated:animated];
    }
    
    if (_flags.delegateHasDidDeselectCellAtIndex)
        [self.delegate gridView:self didDeselectCellAtIndex:cellIndex];
}

#pragma mark Inserting, Deleting, and Moving Cells

static const void *updateActionKey;
static const void *updateAnimatedKey;
static NSString * const updateInsertActionKey = @"insert";
static NSString * const updateDeleteActionKey = @"delete";

- (void)beginUpdate
{
    if (!_updateBatches)
        _updateBatches = [NSMutableArray new];
    
    [_updateBatches addObject:[NSMutableArray new]];
}

- (void)endUpdate
{
    ECASSERT([_updateBatches count]);
    
    [_selectedCells removeAllIndexes];
    [_selectedEditingCells removeAllIndexes];
    
    //
    NSArray *batch = [_updateBatches lastObject];
    NSString *action = nil;
    BOOL animated = NO;
    NSInteger updatedCount = _cellCount;
    NSMutableArray *updatedCells = [_cells mutableCopy];
    for (NSIndexSet *indexes in batch)
    {
        action = objc_getAssociatedObject(indexes, &updateActionKey);
        animated = [objc_getAssociatedObject(indexes, &updateAnimatedKey) boolValue];
        if (action == updateInsertActionKey)
        {
            updatedCount += [indexes count];
#warning TODO NIK implement this
            if (!animated)
            {
                [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                    if (NSLocationInRange(idx, _cellsLoadedRange))
                    {
                        [updatedCells insertObject:[self _addSubviewCellAtIndex:idx] atIndex:(idx - _cellsLoadedRange.location)];
                    }
                }];
            }
        }
        else if (action == updateDeleteActionKey)
        {
            updatedCount -= [indexes count];
            
        }
    }
    
    // Calculate visible differences
    _cellCount = [self.dataSource numberOfCellsForGridView:self];
    ECASSERT(_cellCount == updatedCount);
    
    const CGRect bounds = UIEdgeInsetsInsetRect([self bounds], self.contentInset);
    const NSUInteger columns = self.columnNumber;
    const CGSize cellSize = CGSizeMake(bounds.size.width / (CGFloat)columns, self.rowHeight);
    NSRange visibleRange = NSIntersectionRange(NSMakeRange((NSUInteger)floorf(bounds.origin.y / cellSize.height) * columns, (NSUInteger)(ceilf(bounds.size.height / self.rowHeight) + 1) * columns), (NSRange){ 0, _cellCount });
    
}

- (void)_addBatchActionWithKey:(NSString *)action withCellIndexes:(NSIndexSet *)indexes animated:(BOOL)animated
{
    BOOL isSingleInsert = NO;
    if ([_updateBatches count] == 0)
    {
        isSingleInsert = YES;
        [self beginUpdate];
    }
    
    NSMutableArray *batch = [_updateBatches lastObject];
    [batch addObject:indexes];
    objc_setAssociatedObject(indexes, &updateActionKey, action, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(indexes, &updateAnimatedKey, [NSNumber numberWithBool:animated], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (isSingleInsert)
    {
        [self endUpdate];
    }
}

- (void)insertCellAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated
{
    [self _addBatchActionWithKey:updateInsertActionKey withCellIndexes:indexes animated:animated];
}

- (void)deleteCellAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated
{
    [self _addBatchActionWithKey:updateDeleteActionKey withCellIndexes:indexes animated:animated];
}

#pragma mark Managing the Editing of Cells

@synthesize editing;

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
    if (value)
        [_selectionGestureRecognizer setEnabled:self.allowSelectionDuringEditing];
    else
        [_selectionGestureRecognizer setEnabled:self.allowSelection];
    for (ECGridViewCell *cell in _cells)
    {
        [cell setEditing:value animated:animated];
    }
    [self didChangeValueForKey:@"editing"];
}

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
    
    self.allowSelection = YES;
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
    const CGRect bounds = UIEdgeInsetsInsetRect([self bounds], self.contentInset);
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
        NSUInteger i;
        for (i = cellsRequiredRange.location; i < cellsReuseRange.location; ++i) 
        {
            [newCells addObject:[self _addSubviewCellAtIndex:i]];
        }
        if (cellsReuseRange.length)
        {
            [newCells addObjectsFromArray:[_cells subarrayWithRange:NSMakeRange(cellsReuseRange.location - _cellsLoadedRange.location, cellsReuseRange.length)]];
        }
        for (i = NSMaxRange(cellsReuseRange); i < NSMaxRange(cellsRequiredRange); ++i) {
            [newCells addObject:[self _addSubviewCellAtIndex:i]];
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
    // TODO update on bounds change
    [super setContentSize:CGSizeMake(self.bounds.size.width, self.rowHeight * (_cellCount / self.columnNumber))];
}

- (ECGridViewCell *)_addSubviewCellAtIndex:(NSInteger)cellIndex
{
    ECGridViewCell *cell = [self.dataSource gridView:self cellAtIndex:cellIndex];
    if (self.isEditing)
    {
        [cell setEditing:YES animated:NO];
        [cell setSelected:[_selectedEditingCells containsIndex:cellIndex] animated:NO];
    }
    else
    {
        [cell setEditing:NO animated:NO];
        [cell setSelected:[_selectedCells containsIndex:cellIndex] animated:NO];
    }
    [self insertSubview:cell atIndex:1];
    return cell;
}

- (void)_handleSelectionRecognizer:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateRecognized)
        return;
    
    CGPoint tapPoint = [recognizer locationInView:self];
    NSInteger cellIndex = (NSInteger)floorf(tapPoint.y / self.rowHeight) * self.columnNumber + (NSInteger)floorf(tapPoint.x / self.bounds.size.width * self.columnNumber);
    
    if (!(self.isEditing ? self.allowMultipleSelectionDuringEditing : self.allowMultipleSelection))
    {
        [self selectCellAtIndex:cellIndex animated:YES];
    }
    else
    {
        if ([(self.isEditing ? _selectedEditingCells : _selectedCells) containsIndex:cellIndex])
            [self deselectCellAtIndex:cellIndex animated:YES];
        else
            [self selectCellAtIndex:cellIndex animated:YES];
    }
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
    selectedBackgroundView.frame = [self bounds];
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
    if (toView)
    {
        toView.alpha = 0;
        toView.frame = [self bounds];
        [self insertSubview:toView atIndex:0];
    }
    [UIView animateWithDuration:animated ? 0.25 : 0 animations:^{
        if (toView)
        {
            toView.alpha = 1;
            fromView.alpha = 0;
        }
    } completion:^(BOOL finished) {
        if (toView)
            [fromView removeFromSuperview];
    }];
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

static void _initGridViewCell(ECGridViewCell *self)
{
    [self addSubview:self.contentView];
    if (self.backgroundView)
        [self addSubview:self.backgroundView];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self)
        return nil;
    _initGridViewCell(self);
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;
    _initGridViewCell(self);
    return self;
}

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)aReuseIdentifier
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;
    reuseIdentifier = aReuseIdentifier;
    _initGridViewCell(self);
    return self;
}

#pragma mark Class Methods

+ (ECGridViewCell *)gridViewCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
    return [[self class] gridViewCellWithReuseIdentifier:reuseIdentifier fromNibNamed:nil bundle:nil];
}

+ (ECGridViewCell *)gridViewCellWithReuseIdentifier:(NSString *)reuseIdentifier fromNibNamed:(NSString *)nibName bundle:(NSBundle *)bundle
{
    ECGridViewCell *result = [[[self class] alloc] initWithFrame:CGRectMake(0, 0, 20, 10) reuseIdentifier:reuseIdentifier];
    if (nibName)
    {
        [(bundle ? bundle : [NSBundle mainBundle]) loadNibNamed:nibName owner:result options:nil];
    }
    return result;
}

@end