//
//  GridView.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GridView, GridViewCell;

@protocol GridViewDataSource <NSObject>
@required

- (GridViewCell *)gridView:(GridView *)gridView cellAtIndex:(NSInteger)cellIndex;
- (NSInteger)numberOfCellsForGridView:(GridView *)gridView;

@end


@protocol GridViewDelegate <UIScrollViewDelegate>
@optional

#pragma mark Managing Selections

- (void)gridView:(GridView *)gridView willSelectCellAtIndex:(NSInteger)cellIndex;
- (void)gridView:(GridView *)gridView didSelectCellAtIndex:(NSInteger)cellIndex;
- (void)gridView:(GridView *)gridView willDeselectCellAtIndex:(NSInteger)cellIndex;
- (void)gridView:(GridView *)gridView didDeselectCellAtIndex:(NSInteger)cellIndex;

@end

/// A custom view mimiking a minimum set of functionalities of the UITableView.
/// This view will layout cells in a grid instead that rows.
@interface GridView : UIScrollView

#pragma mark Managing the Delegate and the Data Source

@property (nonatomic, weak) id<GridViewDataSource> dataSource;
@property (nonatomic, weak) id<GridViewDelegate> delegate;

#pragma mark Configuring a Grid View

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) NSUInteger columnNumber;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic) UIEdgeInsets cellInsets;
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier;

#pragma mark Managing Selections

@property (nonatomic) BOOL allowSelection;
@property (nonatomic) BOOL allowMultipleSelection;
@property (nonatomic) BOOL allowSelectionDuringEditing;
@property (nonatomic) BOOL allowMultipleSelectionDuringEditing;
- (NSInteger)indexForSelectedCell;
- (NSIndexSet *)indexesForSelectedCells;
- (void)selectCellAtIndex:(NSInteger)cellIndex animated:(BOOL)animated;
- (void)deselectCellAtIndex:(NSInteger)cellIndex animated:(BOOL)animated;

#pragma mark Inserting, Deleting, and Moving Cells

- (void)beginUpdates;
- (void)endUpdates;
- (void)insertCellsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated;
- (void)deleteCellsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated;
- (void)reloadCellsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated;

#pragma mark Managing the Editing of Cells

@property (nonatomic, getter = isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

#pragma mark Reloading the Grid View

- (void)reloadData;

@end


@interface GridViewCell : UIView

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

+ (id)gridViewCellWithReuseIdentifier:(NSString *)reuseIdentifier;
+ (id)gridViewCellWithReuseIdentifier:(NSString *)reuseIdentifier fromNibNamed:(NSString *)nibName bundle:(NSBundle *)bundle;

#pragma mark Reusing Cells
@property (nonatomic, readonly, strong) NSString *reuseIdentifier;
- (void)prepareForReuse;

#pragma mark Accessing Views of the Cell Object

@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, strong) IBOutlet UIView *backgroundView;
@property (nonatomic, strong) IBOutlet UIView *selectedBackgroundView;

#pragma mark Managing Cell Selection and Highlighting

@property (nonatomic, getter = isSelected) BOOL selected;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
@property (nonatomic, getter = isHighlighted) BOOL highlighted;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;
@property (nonatomic, getter = isEditing) BOOL editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

#pragma mark Styling the Cell

@property (nonatomic) UIEdgeInsets contentInsets;

@end

