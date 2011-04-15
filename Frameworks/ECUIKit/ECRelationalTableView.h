//
//  ECRelationalTableView.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECRelationalTableViewCell.h"
@class ECRelationalTableView;

typedef enum {
    ECRelationalTableViewScrollPositionNone,        
    ECRelationalTableViewScrollPositionTop,    
    ECRelationalTableViewScrollPositionMiddle,   
    ECRelationalTableViewScrollPositionBottom
} ECRelationalTableViewScrollPosition;

@protocol ECRelationalTableViewDataSource <NSObject>
@required

// Returns the number of items at a given depth in the area
- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfItemsInGroup:(NSUInteger)group inArea:(NSUInteger)area;

// Item gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (ECRelationalTableViewCell *)relationalTableView:(ECRelationalTableView *)relationalTableView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSArray *)relationalTableView:(ECRelationalTableView *)relationalTableView relatedIndexPathsForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)numberOfAreasInTableView:(ECRelationalTableView *)relationalTableView;              // Default is 1 if not implemented

// Returns the maximum depth of items in the area, defaults to 1
- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfGroupsInArea:(NSUInteger)area;

- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForHeaderInArea:(NSUInteger)area;    // fixed font style. use custom view (UILabel) if you want something different

// Editing

// Individual items can opt out of having the -editing property set for them. If not implemented, all items are assumed to be editable.
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView canEditItemAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows the reorder accessory view to optionally be shown for a particular item. By default, the reorder control will be shown only if the datasource implements -relationalTableView:moveItemAtIndexPath:toIndexPath:
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

// Data manipulation - reorder / moving support

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end

@protocol ECRelationalTableViewDelegate <NSObject, UIScrollViewDelegate>
@optional

// Selection

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView willSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView willDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
// Called after the user changes the selection.
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows customization of the target item for a particular item as it is being moved/reordered
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

@end

@interface ECRelationalTableView : UIScrollView <UIGestureRecognizerDelegate>
@property (nonatomic, assign) IBOutlet id<ECRelationalTableViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<ECRelationalTableViewDataSource> dataSource;
@property (nonatomic) UIEdgeInsets tableInsets;
@property (nonatomic) CGSize cellSize;
@property (nonatomic) UIEdgeInsets cellInsets;
@property (nonatomic) UIEdgeInsets groupInsets;
@property (nonatomic) UIEdgeInsets groupSeparatorInsets;
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
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForCell:(ECRelationalTableViewCell *)cell;
- (NSArray *)indexPathsForItemsInRect:(CGRect)rect;
- (ECRelationalTableViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)relatedIndexPathsForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)visibleCells;
- (NSArray *)indexPathsForVisibleItems;

// Scrolling
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollToNearestSelectedItemAtScrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition animated:(BOOL)animated;

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

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition;
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

// Recycling
- (ECRelationalTableViewCell *)dequeueReusableCell;

@end

@interface NSIndexPath (ECRelationalTableView)
+ (NSIndexPath *)indexPathForItem:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area;
@property (nonatomic, readonly) NSUInteger area;
@property (nonatomic, readonly) NSUInteger group;
@property (nonatomic, readonly) NSUInteger item;
@end
