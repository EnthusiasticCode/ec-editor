//
//  ECItemView.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECItemViewCell.h"
@class ECItemView;

typedef enum {
    ECItemViewScrollPositionNone,        
    ECItemViewScrollPositionTop,    
    ECItemViewScrollPositionMiddle,   
    ECItemViewScrollPositionBottom
} ECItemViewScrollPosition;

@protocol ECItemViewDataSource <NSObject>
@required

// Returns the number of items at a given depth in the area
- (NSUInteger)itemView:(ECItemView *)itemView numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area;

// Item gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (ECItemViewCell *)itemView:(ECItemView *)itemView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSUInteger)numberOfAreasInTableView:(ECItemView *)itemView;              // Default is 1 if not implemented

// Returns the maximum depth of items in the area, defaults to 1
- (NSUInteger)itemView:(ECItemView *)itemView numberOfGroupsInArea:(NSUInteger)area;

- (NSString *)itemView:(ECItemView *)itemView titleForHeaderInArea:(NSUInteger)area;    // fixed font style. use custom view (UILabel) if you want something different

// Editing

// Individual items can opt out of having the -editing property set for them. If not implemented, all items are assumed to be editable.
- (BOOL)itemView:(ECItemView *)itemView canEditItemAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows the reorder accessory view to optionally be shown for a particular item. By default, the reorder control will be shown only if the datasource implements -itemView:moveItemAtIndexPath:toIndexPath:
- (BOOL)itemView:(ECItemView *)itemView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

// Data manipulation - reorder / moving support

- (void)itemView:(ECItemView *)itemView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end

@protocol ECItemViewDelegate <NSObject, UIScrollViewDelegate>
@optional

// Selection

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (NSIndexPath *)itemView:(ECItemView *)itemView willSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)itemView:(ECItemView *)itemView willDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
// Called after the user changes the selection.
- (void)itemView:(ECItemView *)itemView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)itemView:(ECItemView *)itemView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface ECItemView : UIScrollView <UIGestureRecognizerDelegate>
@property (nonatomic, assign) IBOutlet id<ECItemViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<ECItemViewDataSource> dataSource;
@property (nonatomic) UIEdgeInsets tableInsets;
@property (nonatomic) CGSize cellSize;
@property (nonatomic) UIEdgeInsets cellInsets;
@property (nonatomic) UIEdgeInsets groupInsets;
@property (nonatomic) CGFloat groupSeparatorHeight;
@property (nonatomic) UIEdgeInsets groupSeparatorInsets;
@property (nonatomic) CGFloat groupPlaceholderHeight;
@property (nonatomic) UIEdgeInsets groupPlaceholderInsets;
@property (nonatomic) CGFloat headerHeight;
@property (nonatomic) UIEdgeInsets headerInsets;
@property (nonatomic) BOOL allowsSelection;

// Editing
@property (nonatomic, getter = isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

// Data
- (void)reloadData;

// Info
- (NSUInteger)columns;
- (NSUInteger)rowsInGroup:(NSUInteger)group inArea:(NSUInteger)area;

- (NSUInteger)numberOfAreas;
- (NSUInteger)numberOfGroupsInArea:(NSUInteger)area;
- (NSUInteger)numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area;

// Geometry
- (CGRect)rectForArea:(NSUInteger)area;
- (CGRect)rectForHeaderInArea:(NSUInteger)area;
- (CGRect)rectForGroup:(NSUInteger)group inArea:(NSUInteger)area;
- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath;

// Index paths
- (NSArray *)indexPathsForVisibleItems;
- (NSArray *)visibleCells;
- (ECItemViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForCell:(ECItemViewCell *)cell;
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;
- (NSArray *)indexPathsForItemsInRect:(CGRect)rect;

// Scrolling
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(ECItemViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollToNearestSelectedItemAtScrollPosition:(ECItemViewScrollPosition)scrollPosition animated:(BOOL)animated;

// Item insertion/deletion/reloading.
- (void)beginUpdates;
- (void)endUpdates;

- (void)insertAreas:(NSIndexSet *)areas;
- (void)deleteAreas:(NSIndexSet *)areas;
- (void)reloadAreas:(NSIndexSet *)areas;

- (void)insertGroupsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteGroupsAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadGroupsAtIndexPaths:(NSArray *)indexPaths;

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;

// Selection
- (NSIndexPath *)indexPathForSelectedItem;

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(ECItemViewScrollPosition)scrollPosition;
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

// Recycling
- (ECItemViewCell *)dequeueReusableCell;

@end

@interface NSIndexPath (ECItemView)
+ (NSIndexPath *)indexPathForItem:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area;
+ (NSIndexPath *)indexPathForPosition:(NSUInteger)position inArea:(NSUInteger)area;
@property (nonatomic, readonly) NSUInteger area;
@property (nonatomic, readonly) NSUInteger group;
@property (nonatomic, readonly) NSUInteger item;
@property (nonatomic, readonly) NSUInteger position;
@end
