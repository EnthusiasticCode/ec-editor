//
//  GridView.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GridView.h"

@interface GridView (/*Private Methods*/)

- (void)_enqueueReusableCells:(NSArray *)cells;
- (void)_updateContentSize;
- (void)_positionCell:(GridViewCell *)cell forIndex:(NSInteger)cellIndex;
- (GridViewCell *)_addSubviewCellAtIndex:(NSInteger)cellIndex;
- (void)_handleSelectionRecognizer:(UITapGestureRecognizer *)recognizer;

@end

@interface GridViewCell (/*Private Methods*/)

- (void)_setSelected:(BOOL)selected animated:(BOOL)animated completionHandler:(void(^)(void))completionHandler;

@end

#pragma mark -

@implementation GridView {
  NSInteger _cellCount;
  NSMutableArray *_cells;
  NSRange _cellsLoadedRange;
  NSMutableIndexSet *_selectedCells;
  NSMutableIndexSet *_selectedEditingCells;
  
  NSMutableDictionary *_reusableCells;
  NSMutableIndexSet *_updateInsert, *_updateInsertAnimated, *_updateDelete, *_updateDeleteAnimated, *_updateReload, *_updateReloadAnimated;
  NSUInteger _updateCount;
  
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
@synthesize dataSource = _dataSource;

- (void)setDelegate:(id<GridViewDelegate>)delegate
{
  [super setDelegate:delegate];
  
  _flags.delegateHasWillSelectCellAtIndex = [delegate respondsToSelector:@selector(gridView:willSelectCellAtIndex:)];
  _flags.delegateHasDidSelectCellAtIndex = [delegate respondsToSelector:@selector(gridView:didSelectCellAtIndex:)];
  _flags.delegateHasWillDeselectCellAtIndex = [delegate respondsToSelector:@selector(gridView:willDeselectCellAtIndex:)];
  _flags.delegateHasDidDeselectCellAtIndex = [delegate respondsToSelector:@selector(gridView:didDeselectCellAtIndex:)];
}

- (void)setDataSource:(id<GridViewDataSource>)value
{
  if (value == _dataSource)
    return;
  _dataSource = value;
  [self reloadData];
}

#pragma mark Configuring a Grid View

@synthesize rowHeight, columnNumber;
@synthesize backgroundView, cellInsets;

- (void)setRowHeight:(CGFloat)value
{
  ASSERT(value > 0.0);
  
  if (value == rowHeight)
    return;
  rowHeight = value;
  [self _updateContentSize];
}

- (NSUInteger)columnNumber
{
  return MAX(1U, columnNumber);
}

- (void)setColumnNumber:(NSUInteger)value
{
  ASSERT(value > 0);
  
  if (value == columnNumber)
    return;
  columnNumber = value;
  [self setNeedsLayout];
}

- (void)setBackgroundView:(UIView *)value
{
  if (value == backgroundView)
    return;
  [backgroundView removeFromSuperview];
  backgroundView = value;
  if (backgroundView)
    [self insertSubview:backgroundView atIndex:0];
}

- (void)setCellInsets:(UIEdgeInsets)value
{
  if (UIEdgeInsetsEqualToEdgeInsets(value, cellInsets))
    return;
  cellInsets = value;
  [self setNeedsLayout];
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
    _reusableCells = [[NSMutableDictionary alloc] init];
  
  [cells enumerateObjectsUsingBlock:^(GridViewCell *cell, NSUInteger idx, BOOL *stop) {
    ASSERT(cell && cell.reuseIdentifier);
    
    [cell prepareForReuse];
    [cell removeFromSuperview];
    
    NSMutableArray *reuseArray = [_reusableCells objectForKey:cell.reuseIdentifier];
    if (!reuseArray)
    {
      reuseArray = [[NSMutableArray alloc] init];
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
  allowSelection = value;
  if (!_selectionGestureRecognizer)
  {
    _selectionGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleSelectionRecognizer:)];
    [self addGestureRecognizer:_selectionGestureRecognizer];
  }
  if (!self.isEditing)
    _selectionGestureRecognizer.enabled = value;
}

- (void)setAllowMultipleSelection:(BOOL)value
{
  if (value == allowMultipleSelection)
    return;
  allowMultipleSelection = value;
  if (allowMultipleSelection && !self.allowSelection)
    self.allowSelection = YES;
}

- (void)setAllowSelectionDuringEditing:(BOOL)value
{
  if (value == allowSelectionDuringEditing)
    return;
  allowSelectionDuringEditing = value;
  if (!_selectionGestureRecognizer)
  {
    _selectionGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleSelectionRecognizer:)];
    [self addGestureRecognizer:_selectionGestureRecognizer];
  }
  if (self.isEditing)
    _selectionGestureRecognizer.enabled = value;
}

- (void)setAllowMultipleSelectionDuringEditing:(BOOL)value
{
  if (value == allowMultipleSelectionDuringEditing)
    return;
  allowMultipleSelectionDuringEditing = value;
  if (allowMultipleSelectionDuringEditing && !self.allowSelectionDuringEditing)
    self.allowSelectionDuringEditing = YES;
}

- (NSInteger)indexForSelectedCell
{
  if ([(self.isEditing ? _selectedEditingCells : _selectedCells) count] == 0)
    return -1;
  return [(self.isEditing ? _selectedEditingCells : _selectedCells) firstIndex];
}

- (NSIndexSet *)indexesForSelectedCells
{
  return [(self.isEditing ? _selectedEditingCells : _selectedCells) copy];
}

- (void)selectCellAtIndex:(NSInteger)cellIndex animated:(BOOL)animated
{
  ASSERT(cellIndex < _cellCount);
  
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
      _selectedEditingCells = [[NSMutableIndexSet alloc] init];
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
      _selectedCells = [[NSMutableIndexSet alloc] init];
    [_selectedCells addIndex:cellIndex];
  }
  
  if (_flags.delegateHasWillSelectCellAtIndex)
    [self.delegate gridView:self willSelectCellAtIndex:cellIndex];
  
  // Select cell if visible
  if (NSLocationInRange(cellIndex, _cellsLoadedRange))
  {
    GridViewCell *cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
    [cell _setSelected:YES animated:animated completionHandler:^{
      if (_flags.delegateHasDidSelectCellAtIndex)
        [self.delegate gridView:self didSelectCellAtIndex:cellIndex];
    }];
  }
  else if (_flags.delegateHasDidSelectCellAtIndex)
  {
    [self.delegate gridView:self didSelectCellAtIndex:cellIndex];
  }
}

- (void)deselectCellAtIndex:(NSInteger)cellIndex animated:(BOOL)animated
{
  ASSERT(cellIndex < _cellCount);
  
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
    GridViewCell *cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
    [cell _setSelected:NO animated:animated completionHandler:^{
      if (_flags.delegateHasDidDeselectCellAtIndex)
        [self.delegate gridView:self didDeselectCellAtIndex:cellIndex];
    }];
  }
  else if (_flags.delegateHasDidDeselectCellAtIndex)
  {
    [self.delegate gridView:self didDeselectCellAtIndex:cellIndex];
  }
}

#pragma mark Inserting, Deleting, and Moving Cells

- (void)beginUpdates
{
  _updateCount++;
}

- (void)endUpdates
{
  ASSERT(_updateCount);
  
  _updateCount--;
  if (_updateCount > 0)
    return;
  
  [_selectedCells removeAllIndexes];
  [_selectedEditingCells removeAllIndexes];
  
  //
  CGRect bounds = UIEdgeInsetsInsetRect([self bounds], self.contentInset);
  NSMutableArray *cellsAfterUpdate = [_cells mutableCopy];
  if (!cellsAfterUpdate)
    cellsAfterUpdate = [[NSMutableArray alloc] init];
  NSInteger cellCountAfterUpdate = [self.dataSource numberOfCellsForGridView:self];
  NSRange cellsLoadedAfterUpdate = NSIntersectionRange(NSMakeRange((NSUInteger)floorf(bounds.origin.y / self.rowHeight) * self.columnNumber, (NSUInteger)(floorf(bounds.size.height / self.rowHeight) + 1) * self.columnNumber), (NSRange){ 0, cellCountAfterUpdate });
  
  //
  NSInteger offsetBeforeAnimation = 0, offsetAfterAnimation = 0;
  NSInteger count = MAX(_cellCount, cellCountAfterUpdate);
  BOOL hasAnimations = NO;
  for (NSInteger cellIndex = 0; cellIndex < count; ++cellIndex)
  {
    BOOL hasChanged = NO;
    
    // Delete
    if ([_updateDelete containsIndex:cellIndex])
    {
      if (NSLocationInRange(cellIndex, _cellsLoadedRange))
      {
        GridViewCell *cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
        [cellsAfterUpdate removeObject:cell];
        [cell removeFromSuperview];
      }
      offsetBeforeAnimation--;
      hasChanged = YES;
    }
    else if ([_updateDeleteAnimated containsIndex:cellIndex])
    {
      if (NSLocationInRange(cellIndex, _cellsLoadedRange))
      {
        GridViewCell *cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
        [cellsAfterUpdate removeObject:cell];
        [self _positionCell:cell forIndex:(cellIndex + offsetBeforeAnimation)];
        [UIView animateWithDuration:0.2 animations:^{
          cell.alpha = 0;
        } completion:^(BOOL finished) {
          [cell removeFromSuperview];
        }];
      }
      offsetAfterAnimation--;
      hasChanged = YES;
      hasAnimations = YES;
    }
    
    // Reload
    else if ([_updateReload containsIndex:cellIndex])
    {
      if (NSLocationInRange(cellIndex, _cellsLoadedRange))
      {
        GridViewCell *cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
        [cellsAfterUpdate removeObject:cell];
        [cell removeFromSuperview];
      }
      if (NSLocationInRange(cellIndex + offsetBeforeAnimation, cellsLoadedAfterUpdate))
      {
        GridViewCell *cell = [self.dataSource gridView:self cellAtIndex:(cellIndex + offsetBeforeAnimation)];
        [self _positionCell:cell forIndex:(cellIndex + offsetBeforeAnimation)];
        if (NSLocationInRange(cellIndex + offsetBeforeAnimation + offsetAfterAnimation, cellsLoadedAfterUpdate))
          [cellsAfterUpdate insertObject:cell atIndex:(cellIndex + offsetBeforeAnimation + offsetAfterAnimation - cellsLoadedAfterUpdate.location)];
      }
      hasChanged = YES;
    }
    else if ([_updateReloadAnimated containsIndex:cellIndex])
    {
      if (NSLocationInRange(cellIndex, _cellsLoadedRange))
      {
        GridViewCell *cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
        [cellsAfterUpdate removeObject:cell];
        [self _positionCell:cell forIndex:(cellIndex + offsetBeforeAnimation)];
        [UIView animateWithDuration:0.2 animations:^{
          [self _positionCell:cell forIndex:(cellIndex + offsetBeforeAnimation + offsetAfterAnimation)];
        } completion:^(BOOL finished) {
          [cell removeFromSuperview];
        }];
      }
      if (NSLocationInRange(cellIndex + offsetBeforeAnimation, cellsLoadedAfterUpdate))
      {
        GridViewCell *cell = [self.dataSource gridView:self cellAtIndex:(cellIndex + offsetBeforeAnimation)];
        [self _positionCell:cell forIndex:(cellIndex + offsetBeforeAnimation)];
        [self addSubview:cell];
        cell.alpha = 0;
        [UIView animateWithDuration:0.2 animations:^{
          cell.alpha = 1;
          [self _positionCell:cell forIndex:(cellIndex + offsetBeforeAnimation + offsetAfterAnimation)];
        } completion:nil];
        if (NSLocationInRange(cellIndex + offsetBeforeAnimation + offsetAfterAnimation, cellsLoadedAfterUpdate))
          [cellsAfterUpdate insertObject:cell atIndex:(cellIndex + offsetBeforeAnimation + offsetAfterAnimation - cellsLoadedAfterUpdate.location)];
      }
      hasChanged = YES;
      hasAnimations = YES;
    }
    
    // Insert
    if ([_updateInsert containsIndex:cellIndex])
    {
      if (NSLocationInRange(cellIndex, cellsLoadedAfterUpdate))
      {
        GridViewCell *cell = [self.dataSource gridView:self cellAtIndex:cellIndex];
        [self _positionCell:cell forIndex:cellIndex];
        if (NSLocationInRange(cellIndex, cellsLoadedAfterUpdate))
          [cellsAfterUpdate insertObject:cell atIndex:(cellIndex - cellsLoadedAfterUpdate.location)];
      }
      offsetBeforeAnimation++;
      hasChanged = YES;
    }
    else if ([_updateInsertAnimated containsIndex:cellIndex])
    {
      if (NSLocationInRange(cellIndex, cellsLoadedAfterUpdate))
      {
        GridViewCell *cell = [self.dataSource gridView:self cellAtIndex:cellIndex];
        [self _positionCell:cell forIndex:cellIndex];
        [self addSubview:cell];
        cell.alpha = 0;
        [UIView animateWithDuration:0.2 animations:^{
          cell.alpha = 1;
        }];
        if (NSLocationInRange(cellIndex, cellsLoadedAfterUpdate))
          [cellsAfterUpdate insertObject:cell atIndex:(cellIndex - cellsLoadedAfterUpdate.location)];
      }
      offsetAfterAnimation++;
      hasAnimations = YES;
    }
    
    // Reposition non-changed elements
    if (!hasChanged)
    {
      if (cellIndex < _cellCount && NSLocationInRange(cellIndex + offsetBeforeAnimation + offsetAfterAnimation, cellsLoadedAfterUpdate))
      {
        [UIView animateWithDuration:(hasAnimations ? 0.2 : 0) animations:^{
          // A way to reproduce this is to deleted several projects at the end together
          GridViewCell *cell = [_cells objectAtIndex:(cellIndex)];
          [self _positionCell:cell forIndex:(cellIndex + offsetBeforeAnimation + offsetAfterAnimation)];
        }];
      }
    }
  }
  
  ASSERT([cellsAfterUpdate count] == cellsLoadedAfterUpdate.length);
  
  _cells = cellsAfterUpdate;
  _cellsLoadedRange = cellsLoadedAfterUpdate;
  _cellCount = cellCountAfterUpdate;
  [self _updateContentSize];
  
  [_updateInsert removeAllIndexes];
  [_updateInsertAnimated removeAllIndexes];
  [_updateDelete removeAllIndexes];
  [_updateDeleteAnimated removeAllIndexes];
  [_updateReload removeAllIndexes];
  [_updateReloadAnimated removeAllIndexes];
}

- (void)insertCellsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated
{
  [self beginUpdates];
  if (animated)
  {
    if (!_updateInsertAnimated)
      _updateInsertAnimated = [[NSMutableIndexSet alloc] init];
    [_updateInsertAnimated addIndexes:indexes];
  }
  else
  {
    if (_updateInsert)
      _updateInsert = [[NSMutableIndexSet alloc] init];
    [_updateInsert addIndexes:indexes];
  }
  [self endUpdates];
}

- (void)deleteCellsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated
{
  [self beginUpdates];
  if (animated)
  {
    if (!_updateDeleteAnimated)
      _updateDeleteAnimated = [[NSMutableIndexSet alloc] init];
    [_updateDeleteAnimated addIndexes:indexes];
  }
  else
  {
    if (_updateDelete)
      _updateDelete = [[NSMutableIndexSet alloc] init];
    [_updateDelete addIndexes:indexes];
  }
  [self endUpdates];
}

- (void)reloadCellsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated
{
  [self beginUpdates];
  if (animated)
  {
    if (!_updateReloadAnimated)
      _updateReloadAnimated = [[NSMutableIndexSet alloc] init];
    [_updateReloadAnimated addIndexes:indexes];
  }
  else
  {
    if (_updateReload)
      _updateReload = [[NSMutableIndexSet alloc] init];
    [_updateReload addIndexes:indexes];
  }
  [self endUpdates];
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
  // Enable selection recognizer
  if (value)
    [_selectionGestureRecognizer setEnabled:self.allowSelectionDuringEditing];
  else
    [_selectionGestureRecognizer setEnabled:self.allowSelection];
  // Set cells editing state
  for (GridViewCell *cell in _cells)
  {
    [cell setSelected:NO animated:animated];
    [cell setEditing:value animated:animated];
  }
  // Clear selections
  [_selectedCells removeAllIndexes];
  [_selectedEditingCells removeAllIndexes];
  [self didChangeValueForKey:@"editing"];
}

+ (BOOL)automaticallyNotifiesObserversOfEditing
{
  return NO;
}

#pragma mark Reloading the Grid View

- (void)reloadData
{
  ASSERT(self.dataSource);
  
  [self _enqueueReusableCells:_cells];
  _cells = nil;
  _cellsLoadedRange = NSMakeRange(0, 0);
  
  _cellCount = [self.dataSource numberOfCellsForGridView:self];
  [self _updateContentSize];
  
  [self scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
  [self setNeedsLayout];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement {
  return NO;
}

#pragma mark View Methods

static void _init(GridView *self)
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
  ASSERT(NO && "Content size cannot be set manually");
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
  NSRange cellsRequiredRange = NSIntersectionRange(NSMakeRange((NSUInteger)floorf(bounds.origin.y / cellSize.height) * columns, (NSUInteger)(floorf(bounds.size.height / self.rowHeight) + 1) * columns), (NSRange){ 0, _cellCount });
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
    const UIEdgeInsets cinsets = self.cellInsets;
    [_cells enumerateObjectsUsingBlock:^(UIView *cell, NSUInteger cellIndex, BOOL *stop) {
      if (cellIndex == 0)
      {
        CGRect frame = UIEdgeInsetsInsetRect(cellFrame, cinsets);
        cell.bounds = (CGRect){ CGPointZero, frame.size };
        cell.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
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
      CGRect frame = UIEdgeInsetsInsetRect(cellFrame, cinsets);
      cell.bounds = (CGRect){ CGPointZero, frame.size };
      cell.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    }];
  }
}

- (void)setFrame:(CGRect)frame
{
  if (CGRectEqualToRect(frame, self.frame))
    return;
  
  _cellsLoadedRange = NSMakeRange(0, 0);
  [super setFrame:frame];
  [self _updateContentSize];
}

#pragma mark - Private Methods

- (void)_updateContentSize
{
  [super setContentSize:CGSizeMake(self.bounds.size.width, self.rowHeight * (_cellCount / self.columnNumber))];
}

- (GridViewCell *)_addSubviewCellAtIndex:(NSInteger)cellIndex
{
  GridViewCell *cell = [self.dataSource gridView:self cellAtIndex:cellIndex];
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

- (void)_positionCell:(GridViewCell *)cell forIndex:(NSInteger)cellIndex
{
  CGRect bounds = UIEdgeInsetsInsetRect([self bounds], self.contentInset);
  CGSize cellSize = CGSizeMake(bounds.size.width / (CGFloat)self.columnNumber, self.rowHeight);
  CGPoint origin = CGPointMake((cellIndex % self.columnNumber) * cellSize.width, (cellIndex / self.columnNumber) * cellSize.height);
  CGRect frame = UIEdgeInsetsInsetRect((CGRect){ origin, cellSize }, self.cellInsets);
  cell.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
  cell.bounds = (CGRect){ CGPointZero, frame.size };
}

- (void)_handleSelectionRecognizer:(UITapGestureRecognizer *)recognizer
{
  if (recognizer.state != UIGestureRecognizerStateRecognized)
    return;
  
  CGPoint tapPoint = [recognizer locationInView:self];
  NSInteger cellIndex = (NSInteger)floorf(tapPoint.y / self.rowHeight) * self.columnNumber + (NSInteger)floorf(tapPoint.x / self.bounds.size.width * self.columnNumber);
  if (cellIndex >= _cellCount)
    return;
  
  // Animate cell push
  GridViewCell *cell = nil;
  if(self.isEditing && NSLocationInRange(cellIndex, _cellsLoadedRange))
    cell = [_cells objectAtIndex:(cellIndex - _cellsLoadedRange.location)];
  
  [UIView animateWithDuration:(self.isEditing ? 0.1 : 0) animations:^{
    [cell setTransform:CGAffineTransformMakeScale(0.95, 0.95)];
  } completion:^(BOOL outerFinished) {
    [UIView animateWithDuration:(self.isEditing ? 0.1 : 0) animations:^{
      [cell setTransform:CGAffineTransformIdentity];
    } completion:^(BOOL innerFinished) {
      // Set selection
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
    }];
  }];
}

@end

#pragma mark -

@implementation GridViewCell

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

- (void)setContentView:(UIView *)value
{
  if (value == contentView)
    return;
  [contentView removeFromSuperview];
  contentView = value;
  contentView.frame = UIEdgeInsetsInsetRect([self bounds], self.contentInsets);
  [self insertSubview:contentView atIndex:100];
}

- (void)setBackgroundView:(UIView *)value
{
  if (value == backgroundView)
    return;
  [backgroundView removeFromSuperview];
  backgroundView = value;
  backgroundView.frame = [self bounds];
  backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  if (backgroundView && !self.isSelected)
    [self insertSubview:backgroundView belowSubview:self.contentView];
}

- (void)setSelectedBackgroundView:(UIView *)value
{
  if (value == selectedBackgroundView)
    return;
  [selectedBackgroundView removeFromSuperview];
  selectedBackgroundView = value;
  selectedBackgroundView.frame = [self bounds];
  selectedBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  if (selectedBackgroundView && self.isSelected)
    [self insertSubview:selectedBackgroundView belowSubview:self.contentView];
}

#pragma mark Managing Cell Selection and Highlighting

@synthesize selected, highlighted, editing;

- (void)setSelected:(BOOL)value
{
  [self setSelected:value animated:NO];
}

- (void)setSelected:(BOOL)value animated:(BOOL)animated
{
  [self _setSelected:value animated:animated completionHandler:nil];
}

- (void)_setSelected:(BOOL)value animated:(BOOL)animated completionHandler:(void (^)(void))completionHandler
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
  [UIView animateWithDuration:animated ? 0.2 : 0 animations:^{
    if (toView)
    {
      toView.alpha = 1;
      fromView.alpha = 0;
    }
  } completion:^(BOOL finished) {
    if (toView)
      [fromView removeFromSuperview];
    if (completionHandler)
      completionHandler();
  }];
  [self didChangeValueForKey:@"selected"];
}

+ (BOOL)automaticallyNotifiesObserversOfSelected
{
  return NO;
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
  for (id view in self.contentView.subviews)
  {
    if ([view respondsToSelector:@selector(setHighlighted:animated:)])
      [view setHighlighted:value animated:animated];
  }
  if ([self.backgroundView respondsToSelector:@selector(setHighlighted:animated:)])
    [(id)self.backgroundView setHighlighted:value animated:animated];
  if ([self.selectedBackgroundView respondsToSelector:@selector(setHighlighted:animated:)])
    [(id)self.selectedBackgroundView setHighlighted:value animated:animated];
  [self didChangeValueForKey:@"highlighted"];
}

+ (BOOL)automaticallyNotifiesObserversOfHighlighted
{
  return NO;
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
  // TODO: animate
  [self didChangeValueForKey:@"editing"];
}

+ (BOOL)automaticallyNotifiesObserversOfEditing
{
  return NO;
}

#pragma mark Styling the Cell

@synthesize contentInsets;

- (void)setContentInsets:(UIEdgeInsets)value
{
  if (UIEdgeInsetsEqualToEdgeInsets(value, contentInsets))
    return;
  contentInsets = value;
  self.contentView.frame = UIEdgeInsetsInsetRect([self bounds], contentInsets);
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

#pragma mark Class Methods

+ (id)gridViewCellWithReuseIdentifier:(NSString *)reuseIdentifier
{
  return [[self class] gridViewCellWithReuseIdentifier:reuseIdentifier fromNibNamed:nil bundle:nil];
}

+ (id)gridViewCellWithReuseIdentifier:(NSString *)reuseIdentifier fromNibNamed:(NSString *)nibName bundle:(NSBundle *)bundle
{
  GridViewCell *result = nil;
  if (nibName)
  {
    result = [[[self class] alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000)];
    result->reuseIdentifier = reuseIdentifier;
    [(bundle ? bundle : [NSBundle mainBundle]) loadNibNamed:nibName owner:result options:nil];
  }
  else
  {
    result = [[[self class] alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000) reuseIdentifier:reuseIdentifier];
  }
  return result;
}

@end