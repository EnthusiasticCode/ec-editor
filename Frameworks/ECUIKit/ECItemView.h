//
//  ECItemView.h
//  edit
//
//  Created by Uri Baghin on 4/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECItemView;

extern const NSUInteger ECItemViewItemNotFound;

/// Describes the interface for dynamically altering the behavious and appearance of an item view.
@protocol ECItemViewDelegate <NSObject>
@optional
/// Called when the user selects an item.
- (void)itemView:(ECItemView *)itemView didSelectItem:(NSUInteger)item;
/// Called when the user attempts to initiate a drag operation.
/// If a superview of the item view is specified, the drag operation will be limited to that view instead of the item view.
- (BOOL)itemView:(ECItemView *)itemView shouldDragItem:(NSUInteger)item inView:(UIView **)view;
/// Called when the user attempts to end a drag operation in an item view.
/// Return YES to finalize the operation, or NO to cancel it.
- (BOOL)itemView:(ECItemView *)itemView canDropItem:(NSUInteger)item inTargetItemView:(ECItemView *)targetItemView;
/// Called after the drag operation completes.
/// The item is removed from the source item view, and added in the target item view, at the specified index.
- (void)itemView:(ECItemView *)itemView didDropItem:(NSUInteger)item inTargetItemView:(ECItemView *)targetItemView atIndex:(NSUInteger)index;
@end

@interface ECItemView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, assign) IBOutlet id<ECItemViewDelegate> delegate;
@property (nonatomic, copy) NSArray *items;

@property (nonatomic) UIEdgeInsets viewInsets;
@property (nonatomic) CGRect itemBounds;
@property (nonatomic) UIEdgeInsets itemInsets;
@property (nonatomic) BOOL animatesChanges;

@property (nonatomic) BOOL allowsSelection;
@property (nonatomic) BOOL allowsDragging;
@property (nonatomic, getter = isEditing) BOOL editing;

- (CGRect)rectForItem:(NSUInteger)item;
- (NSUInteger)itemAtPoint:(CGPoint)point;
- (NSUInteger)columns;
- (NSUInteger)rows;

- (void)beginUpdates;
- (void)endUpdates;

- (void)addItem:(UIView *)item;
- (void)insertItem:(UIView *)item atIndex:(NSUInteger)index;
- (void)removeLastItem;
- (void)removeItemAtIndex:(NSUInteger)index;
- (void)replaceItemAtIndex:(NSUInteger)index withItem:(UIView *)item;

- (void)addItemsFromArray:(NSArray *)otherArray;
- (void)exchangeItemAtIndex:(NSUInteger)index1 withItemAtIndex:(NSUInteger)index2;
- (void)removeAllItems;

- (void)insertItems:(NSArray *)items atIndexes:(NSIndexSet *)indexes;
- (void)removeItemsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceItemsAtIndexes:(NSIndexSet *)indexes withItems:(NSArray *)items;

@end
