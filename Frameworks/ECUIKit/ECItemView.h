//
//  ECItemView.h
//  edit
//
//  Created by Uri Baghin on 4/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECItemViewCell.h"
@class ECItemView;

/// Describes the interface for providing an item view with items to display.
@protocol ECItemViewDataSource
@required
/// Returns the number of items in the item view.
- (NSInteger)numberOfItemsInItemView:(ECItemView *)itemView;
/// Returns the cell for an item. This must not return the same cell for two different items.
- (ECItemViewCell *)itemView:(ECItemView *)itemView cellForItem:(NSInteger)item;
@end

/// Describes the interface for dynamically altering the behavious and appearance of an item view.
@protocol ECItemViewDelegate <NSObject>
@optional
/// Called when the user selects an item.
- (void)itemView:(ECItemView *)itemView didSelectItem:(NSInteger)item;
/// Called when the user attempts to initiate a drag operation.
/// If a superview of the item view is specified, the drag operation will be limited to that view instead of the item view.
- (BOOL)itemView:(ECItemView *)itemView shouldDragItem:(NSInteger)item inView:(UIView **)view;
/// Called when the user attempts to end a drag operation in an item view.
/// Return YES to finalize the operation, or NO to cancel it.
- (BOOL)itemView:(ECItemView *)itemView canDropItem:(NSInteger)item inTargetItemView:(ECItemView *)targetItemView;
/// Called after the drag operation completes.
/// The item is removed from the source item view, and added in the target item view, at the specified index.
- (void)itemView:(ECItemView *)itemView didDropItem:(NSInteger)item inTargetItemView:(ECItemView *)targetItemView atIndex:(NSInteger)index;
@end

@interface ECItemView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, assign) IBOutlet id<ECItemViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<ECItemViewDelegate> delegate;
@property (nonatomic) UIEdgeInsets viewInsets;
@property (nonatomic) CGRect itemFrame;
@property (nonatomic) UIEdgeInsets itemInsets;
@property (nonatomic) BOOL allowsSelection;
@property (nonatomic) BOOL allowsDragging;
@property (nonatomic, getter = isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)reloadData;
- (NSInteger)numberOfItems;
- (CGRect)rectForItem:(NSInteger)item;
- (NSInteger)itemAtPoint:(CGPoint)point;
- (void)beginUpdates;
- (void)endUpdates;
- (void)insertItems:(NSIndexSet *)items;
- (void)deleteItems:(NSIndexSet *)items;
- (void)reloadItems:(NSIndexSet *)items;
@end
