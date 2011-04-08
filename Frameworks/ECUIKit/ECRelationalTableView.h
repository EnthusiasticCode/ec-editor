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
} ECRelationalTableViewScrollPosition;            // scroll so item of interest is completely visible at top/center/bottom of view

typedef enum {
    ECRelationalTableViewItemAnimationFade,
    ECRelationalTableViewItemAnimationRight,       // slide in from right (or out to right)
    ECRelationalTableViewItemAnimationLeft,
    ECRelationalTableViewItemAnimationTop,
    ECRelationalTableViewItemAnimationBottom,
    ECRelationalTableViewItemAnimationNone,        // available in iPhone 3.0
    ECRelationalTableViewItemAnimationMiddle,      // available in iPhone 3.2.  attempts to keep item centered in the space it will/did occupy
} ECRelationalTableViewItemAnimation;

@protocol ECRelationalTableViewDataSource <NSObject>
@required

// Returns the number of items at a given depth in the area
- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfItemsAtLevel:(NSUInteger)level inArea:(NSUInteger)area;

// Item gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (ECRelationalTableViewCell *)relationalTableView:(ECRelationalTableView *)relationalTableView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSArray *)relationalTableView:(ECRelationalTableView *)relationalTableView relatedIndexPathsForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSUInteger)numberOfAreasInTableView:(ECRelationalTableView *)relationalTableView;              // Default is 1 if not implemented

// Returns the maximum depth of items in the area, defaults to 1
- (NSUInteger)relationalTableView:(ECRelationalTableView *)relationalTableView numberOfLevelsInArea:(NSUInteger)area;

- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForHeaderInArea:(NSUInteger)area;    // fixed font style. use custom view (UILabel) if you want something different
- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForFooterInArea:(NSUInteger)area;

// Editing

// Individual items can opt out of having the -editing property set for them. If not implemented, all items are assumed to be editable.
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView canEditItemAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows the reorder accessory view to optionally be shown for a particular item. By default, the reorder control will be shown only if the datasource implements -relationalTableView:moveItemAtIndexPath:toIndexPath:
- (BOOL)relationalTableView:(ECRelationalTableView *)relationalTableView canMoveItemAtIndexPath:(NSIndexPath *)indexPath;

// Data manipulation - insert and delete support

// After a item has the minus or plus button invoked (based on the ECRelationalTableViewItemEditingStyle for the item), the dataSource must commit the change
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView commitEditingStyle:(ECRelationalTableViewItemEditingStyle)editingStyle forItemAtIndexPath:(NSIndexPath *)indexPath;

// Data manipulation - reorder / moving support

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath;

@end

@protocol ECRelationalTableViewDelegate <NSObject, UIScrollViewDelegate>

@optional

// Display customization

- (void)relationalTableView:(ECRelationalTableView *)relationalTableView willDisplayCell:(ECRelationalTableViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;

// Area header & footer information. Views are preferred over title should you decide to provide both

- (UIView *)relationalTableView:(ECRelationalTableView *)relationalTableView viewForHeaderInArea:(NSUInteger)area;   // custom view for header. will be adjusted to default or specified header height
- (UIView *)relationalTableView:(ECRelationalTableView *)relationalTableView viewForFooterInArea:(NSUInteger)area;   // custom view for footer. will be adjusted to default or specified footer height

// Accessories (disclosures). 

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForItemWithIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForItemWithIndexPath:(NSIndexPath *)indexPath;

// Selection

// Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView willSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView willDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
// Called after the user changes the selection.
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)relationalTableView:(ECRelationalTableView *)relationalTableView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

// Editing

// Allows customization of the editingStyle for a particular item located at 'indexPath'. If not implemented, all editable items will have ECRelationalTableViewItemEditingStyleDelete set for them when the table has editing property set to YES.
- (ECRelationalTableViewItemEditingStyle)relationalTableView:(ECRelationalTableView *)relationalTableView editingStyleForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)relationalTableView:(ECRelationalTableView *)relationalTableView titleForDeleteConfirmationButtonForItemAtIndexPath:(NSIndexPath *)indexPath;

// Moving/reordering

// Allows customization of the target item for a particular item as it is being moved/reordered
- (NSIndexPath *)relationalTableView:(ECRelationalTableView *)relationalTableView targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

@end

@interface ECRelationalTableView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, assign) IBOutlet id<ECRelationalTableViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<ECRelationalTableViewDataSource> dataSource;
@property (nonatomic) UIEdgeInsets tableInsets;
@property (nonatomic) UIEdgeInsets cellInsets;
@property (nonatomic) UIEdgeInsets levelInsets;
@property (nonatomic) UIEdgeInsets areaHeaderInsets;
@property (nonatomic) UIEdgeInsets areaFooterInsets;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, readonly) CGSize paddedCellSize;
@property (nonatomic, readonly) NSUInteger contentWidthInCells;
@property (nonatomic) CGFloat areaHeaderHeight;
@property (nonatomic, readonly) CGSize paddedAreaHeaderSize;
@property (nonatomic) CGFloat areaFooterHeight;
@property (nonatomic, readonly) CGSize paddedAreaFooterSize;
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) UIView *tableHeaderView;
@property (nonatomic, retain) UIView *tableFooterView;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic) BOOL allowsSelection;
@property (nonatomic) BOOL allowsSelectionDuringEditing;
@property (nonatomic) NSLocaleLanguageDirection itemGrowthDirection;
@property (nonatomic) NSLocaleLanguageDirection itemWrapDirection;
@property (nonatomic) NSLocaleLanguageDirection levelGrowthDirection;

// Data

- (void)reloadData;

// Info

- (NSUInteger)heightInCellsForContentAtLevel:(NSUInteger)level inArea:(NSUInteger)area;

- (NSUInteger)numberOfAreas;
- (NSUInteger)numberOfLevelsInArea:(NSUInteger)area;
- (NSUInteger)numberOfItemsAtLevel:(NSUInteger)level inArea:(NSUInteger)area;

- (CGRect)rectForArea:(NSUInteger)area;                                    // includes header, footer and all items
- (CGRect)rectForHeaderInArea:(NSUInteger)area;
- (CGRect)rectForFooterInArea:(NSUInteger)area;
- (CGRect)rectForLevel:(NSUInteger)level inArea:(NSUInteger)area;
- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForCell:(ECRelationalTableViewCell *)cell;
- (NSArray *)indexPathsForItemsInRect:(CGRect)rect;

- (ECRelationalTableViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)relatedIndexPathsForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)visibleCells;
- (NSArray *)indexPathsForVisibleItems;

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollToNearestSelectedItemAtScrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition animated:(BOOL)animated;

// Item insertion/deletion/reloading.

- (void)beginUpdates;   // allow multiple insert/delete of items and areas to be animated simultaneously. Nestable
- (void)endUpdates;     // only call insert/delete/reload calls or change the editing state inside an update block.  otherwise things like item count, etc. may be invalid.

- (void)insertAreas:(NSIndexSet *)areas withItemAnimation:(ECRelationalTableViewItemAnimation)animation;
- (void)deleteAreas:(NSIndexSet *)areas withItemAnimation:(ECRelationalTableViewItemAnimation)animation;
- (void)reloadAreas:(NSIndexSet *)areas withItemAnimation:(ECRelationalTableViewItemAnimation)animation;

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withItemAnimation:(ECRelationalTableViewItemAnimation)animation;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths withItemAnimation:(ECRelationalTableViewItemAnimation)animation;
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths withItemAnimation:(ECRelationalTableViewItemAnimation)animation;

// Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

// Selection

- (NSIndexPath *)indexPathForSelectedItem;                                       // return nil or index path representing area and item of selection.

// Selects and deselects items. These methods will not call the delegate methods (-tableView:willSelectItemAtIndexPath: or tableView:didSelectItemAtIndexPath:), nor will it send out a notification.
- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition;
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (ECRelationalTableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;  // Used by the delegate to acquire an already allocated cell, in lieu of allocating a new one.

@end

@interface NSIndexPath (ECRelationalTableView)
+ (NSIndexPath *)indexPathForItem:(NSUInteger)item atLevel:(NSUInteger)level inArea:(NSUInteger)area;
@property (nonatomic, readonly) NSUInteger area;
@property (nonatomic, readonly) NSUInteger level;
@property (nonatomic, readonly) NSUInteger item;
@end
