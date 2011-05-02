//
//  ECItemView.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECItemView;
@class ECItemViewElement;

typedef enum {
    ECItemViewScrollPositionNone,        
    ECItemViewScrollPositionTop,    
    ECItemViewScrollPositionMiddle,   
    ECItemViewScrollPositionBottom
} ECItemViewScrollPosition;

@protocol ECItemViewDataSource <NSObject>

#pragma mark Data

@optional
/// The number of areas in the item view. defaults to 1 if the data source does not implement the method.
- (NSUInteger)numberOfAreasInItemView:(ECItemView *)itemView;

@required
/// The number of groups in a given area.
- (NSUInteger)itemView:(ECItemView *)itemView numberOfGroupsInAreaAtIndexPath:(NSIndexPath *)indexPath;

/// The number of items in a given group.
- (NSUInteger)itemView:(ECItemView *)itemView numberOfItemsInGroupAtIndexPath:(NSIndexPath *)indexPath;

@optional
/// The view to be displayed as the area header for the given area.
- (ECItemViewElement *)itemView:(ECItemView *)itemView viewForAreaHeaderAtIndexPath:(NSIndexPath *)indexPath;

/// The view to be displayed as the group separator for the given index path.
- (ECItemViewElement *)itemView:(ECItemView *)itemView viewForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath;

@required
/// The view that represents the item for the given index path.
- (ECItemViewElement *)itemView:(ECItemView *)itemView viewForItemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Editing

@optional
/// Individual items can opt out of having the -editing property set for them. If not implemented, all items are assumed to be editable.
- (BOOL)itemView:(ECItemView *)itemView canEditItemAtIndexPath:(NSIndexPath *)indexPath;

/// Allows the delete accessory view to optionally be shown for a particular item. By default, the delete control will be shown only if the datasource implements -itemView:deleteItemAtIndexPath: and -itemView:deleteGroupAtIndexPath:.
- (BOOL)itemView:(ECItemView *)itemView canDeleteItemAtIndexPath:(NSIndexPath *)indexPath;

/// Delete the item at the given index path.
- (void)itemView:(ECItemView *)itemView deleteItemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Moving/Reordering

/// Allows the reorder accessory view to optionally be shown for a particular item. By default, the reorder control will be shown only if the datasource implements -itemView:moveItemAtIndexPath:toIndexPath: and -itemView:deleteGroupAtIndexPath:.
- (BOOL)itemView:(ECItemView *)itemView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

/// Move the item from the source index path to the destination index path.
- (void)itemView:(ECItemView *)itemView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

/// Insert a new group at the given index path.
- (void)itemView:(ECItemView *)itemView insertGroupAtIndexPath:(NSIndexPath *)indexPath;

/// Delete the group at the given index path.
- (void)itemView:(ECItemView *)itemView deleteGroupAtIndexPath:(NSIndexPath *)indexPath;

/// Move the group at the source index path to the destination index path.
- (void)itemView:(ECItemView *)itemView moveGroupAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

/// Move the area at the source index to the destination index.
- (void)itemView:(ECItemView *)itemView moveAreaAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex;

@end

@protocol ECItemViewDelegate <NSObject, UIScrollViewDelegate>

#pragma mark Selection

@optional
/// Called before the user selects a previously unselected item.
- (void)itemView:(ECItemView *)itemView willSelectItemAtIndexPath:(NSIndexPath *)indexPath;
/// Called before the user deselects a previously selected item.
- (void)itemView:(ECItemView *)itemView willDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
/// Called after the user selects a previously unselected item.
- (void)itemView:(ECItemView *)itemView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
/// Called after the user deselects a previously selected item.
- (void)itemView:(ECItemView *)itemView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface ECItemView : UIScrollView <UIGestureRecognizerDelegate>
@property (nonatomic, assign) IBOutlet id<ECItemViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<ECItemViewDataSource> dataSource;
@property (nonatomic) CGFloat itemHeight;
@property (nonatomic) NSUInteger itemsPerRow;
@property (nonatomic) UIEdgeInsets itemInsets;
@property (nonatomic) UIEdgeInsets groupInsets;
@property (nonatomic) CGFloat groupSeparatorHeight;
@property (nonatomic) UIEdgeInsets groupSeparatorInsets;
@property (nonatomic) CGFloat areaHeaderHeight;
@property (nonatomic) UIEdgeInsets areaHeaderInsets;
@property (nonatomic) BOOL allowsSelection;
@property (nonatomic, getter = isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

#pragma mark Data
- (void)reloadData;

#pragma mark Info
- (NSUInteger)numberOfAreas;
- (NSUInteger)numberOfGroupsInAreaAtIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)numberOfItemsInGroupAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Geometry
- (CGRect)rectForAreaHeaderAtIndexPath:(NSIndexPath *)indexPath;
- (CGRect)rectForGroupSeparatorAtIndexPath:(NSIndexPath *)indexPath;
- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Index paths
- (NSArray *)indexPathsForVisibleAreas;
- (NSArray *)indexPathsForVisibleAreaHeaders;
- (NSArray *)visibleAreaHeaders;
- (ECItemViewElement *)areaHeaderAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexForAreaHeaderAtPoint:(CGPoint)point;
- (NSArray *)indexPathsForVisibleGroups;
- (NSArray *)indexPathsForVisibleGroupSeparators;
- (NSArray *)visibleGroupSeparators;
- (ECItemViewElement *)groupSeparatorAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForGroupSeparatorAtPoint:(CGPoint)point;
- (NSArray *)indexPathsForVisibleItems;
- (NSArray *)visibleItems;
- (ECItemViewElement *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;

#pragma mark Scrolling
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(ECItemViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollToNearestSelectedItemAtScrollPosition:(ECItemViewScrollPosition)scrollPosition animated:(BOOL)animated;

#pragma mark Item insertion/deletion/reloading.
- (void)beginUpdates;
- (void)endUpdates;

- (void)insertAreasAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteAreasAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadAreasAtIndexPaths:(NSArray *)indexPaths;

- (void)insertGroupsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteGroupsAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadGroupsAtIndexPaths:(NSArray *)indexPaths;

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;

#pragma mark Selection
- (NSIndexPath *)indexPathForSelectedItem;
- (NSArray *)indexPathsForSelectedItems;

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(ECItemViewScrollPosition)scrollPosition;
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

#pragma mark Recycling
- (ECItemViewElement *)dequeueReusableItem;
- (ECItemViewElement *)dequeueReusableGroupSeparator;
- (ECItemViewElement *)dequeueReusableAreaHeader;

@end

@interface NSIndexPath (ECItemView)
+ (NSIndexPath *)indexPathForItem:(NSUInteger)item inGroup:(NSUInteger)group inArea:(NSUInteger)area;
+ (NSIndexPath *)indexPathForPosition:(NSUInteger)position inArea:(NSUInteger)area;
+ (NSIndexPath *)indexPathForArea:(NSUInteger)area;
@property (nonatomic, readonly) NSUInteger area;
@property (nonatomic, readonly) NSUInteger group;
@property (nonatomic, readonly) NSUInteger item;
@property (nonatomic, readonly) NSUInteger position;
@end
