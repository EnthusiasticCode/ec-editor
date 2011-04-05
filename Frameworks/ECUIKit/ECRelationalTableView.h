//
//  ECRelationalTableView.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECRelationalTableViewDelegate.h"
#import "ECRelationalTableViewDataSource.h"

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

typedef enum {
    ECRelationalTableViewGrowthDirectionLeftToRight,
    ECRelationalTableViewGrowthDirectionRightToLeft,
    ECRelationalTableViewGrowthDirectionTopToBottom,
    ECRelationalTableViewGrowthDirectionBottomToTop,
} ECRelationalTableViewGrowthDirection;

typedef enum {
    ECRelationalTableViewIndentDirectionHorizontal,
    ECRelationalTableViewIndentDirectionVertical,
} ECRelationalTableViewIndentDirection;

typedef enum {
    ECRelationalTableViewWrappingNone,
    ECRelationalTableViewWrappingHorizontal,
    ECRelationalTableViewWrappingVertical,
} ECRelationalTableViewWrapping;

@interface ECRelationalTableView : UIView
@property (nonatomic, assign) IBOutlet id<ECRelationalTableViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id<ECRelationalTableViewDataSource> dataSource;
@property (nonatomic) UIEdgeInsets tableInsets;
@property (nonatomic) UIEdgeInsets itemInsets;
@property (nonatomic) UIEdgeInsets indentInsets;
@property (nonatomic) UIEdgeInsets sectionHeaderInsets;
@property (nonatomic) UIEdgeInsets sectionFooterInsets;
@property (nonatomic) CGFloat sectionHeaderHeight;
@property (nonatomic) CGFloat sectionFooterHeight;
@property (nonatomic, retain) UIView *backgroundView;
@property (nonatomic, retain) UIView *tableHeaderView;
@property (nonatomic, retain) UIView *tableFooterView;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic) BOOL allowsSelection;
@property (nonatomic) BOOL allowsSelectionDuringEditing;
@property (nonatomic) ECRelationalTableViewGrowthDirection growthDirection;
@property (nonatomic) ECRelationalTableViewIndentDirection indentDirection;
@property (nonatomic) ECRelationalTableViewWrapping wrapping;

// Data

- (void)reloadData;
/*
// Info

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;

- (CGRect)rectForSection:(NSUInteger)section;                                    // includes header, footer and all items
- (CGRect)rectForHeaderInSection:(NSUInteger)section;
- (CGRect)rectForFooterInSection:(NSUInteger)section;
- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForItem:(ECRelationalTableViewItem *)item;
- (NSArray *)indexPathsForItemsInRect:(CGRect)rect;

- (ECRelationalTableViewItem *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)visibleItems;
- (NSArray *)indexPathsForVisibleItems;

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (void)scrollToNearestSelectedItemAtScrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition animated:(BOOL)animated;

// Item insertion/deletion/reloading.

- (void)beginUpdates;   // allow multiple insert/delete of items and sections to be animated simultaneously. Nestable
- (void)endUpdates;     // only call insert/delete/reload calls or change the editing state inside an update block.  otherwise things like item count, etc. may be invalid.

- (void)insertSections:(NSIndexSet *)sections withItemAnimation:(ECRelationalTableViewItemAnimation)animation;
- (void)deleteSections:(NSIndexSet *)sections withItemAnimation:(ECRelationalTableViewItemAnimation)animation;
- (void)reloadSections:(NSIndexSet *)sections withItemAnimation:(ECRelationalTableViewItemAnimation)animation;

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths withItemAnimation:(ECRelationalTableViewItemAnimation)animation;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths withItemAnimation:(ECRelationalTableViewItemAnimation)animation;
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths withItemAnimation:(ECRelationalTableViewItemAnimation)animation;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

// Selection

- (NSIndexPath *)indexPathForSelectedItem;                                       // return nil or index path representing section and item of selection.

// Selects and deselects items. These methods will not call the delegate methods (-tableView:willSelectItemAtIndexPath: or tableView:didSelectItemAtIndexPath:), nor will it send out a notification.
- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(ECRelationalTableViewScrollPosition)scrollPosition;
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
*/
@end
