//
//  ECGridView.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 10/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECGridView, ECGridViewCell;

@protocol ECGridViewDataSource <NSObject>
@required

- (ECGridViewCell *)gridView:(ECGridView *)gridView cellAtIndex:(NSInteger)cellIndex;
- (NSInteger)numberOfCellsForGridView:(ECGridView *)gridView;

@end


@protocol ECGridViewDelegate <UIScrollViewDelegate>
@optional

#pragma mark Managing Selections

- (void)gridView:(ECGridView *)gridView willSelectCellAtIndex:(NSInteger)cellIndex;
- (void)gridView:(ECGridView *)gridView didSelectCellAtIndex:(NSInteger)cellIndex;
- (void)gridView:(ECGridView *)gridView willDeselectCellAtIndex:(NSInteger)cellIndex;
- (void)gridView:(ECGridView *)gridView didDeselectCellAtIndex:(NSInteger)cellIndex;

@end

/// A custom view mimiking a minimum set of functionalities of the UITableView.
/// This view will layout cells in a grid instead that rows.
@interface ECGridView : UIScrollView

#pragma mark Managing the Delegate and the Data Source

@property (nonatomic, weak) id<ECGridViewDataSource> dataSource;
@property (nonatomic, weak) id<ECGridViewDelegate> delegate;

#pragma mark Configuring a Grid View

@property (nonatomic) CGFloat rowHeight;
@property (nonatomic) NSUInteger columnNumber;
@property (nonatomic, strong) UIView *backgroundView;
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier;

#pragma mark Inserting, Deleting, and Moving Cells

- (void)beginUpdate;
- (void)endUpdate;
- (void)insertCellAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated;
- (void)deleteCellAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated;

#pragma mark Reloading the Grid View

- (void)reloadData;

@end


@interface ECGridViewCell : UIView

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

#pragma mark Reusing Cells
@property (nonatomic, readonly, strong) NSString *reuseIdentifier;
- (void)prepareForReuse;

#pragma mark Accessing Views of the Cell Object

@property (nonatomic, readonly, strong) UIView *contentView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *selectedBackgroundView;

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

