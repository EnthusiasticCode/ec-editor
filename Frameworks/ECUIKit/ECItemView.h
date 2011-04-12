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

@protocol ECItemViewDataSource
@required
- (NSInteger)numberOfItemsInItemView:(ECItemView *)itemView;
- (ECItemViewCell *)itemView:(ECItemView *)itemView cellForItem:(NSInteger)item;
@end

@protocol ECItemViewDelegate <NSObject>
@optional
- (void)itemView:(ECItemView *)itemView didSelectItem:(NSInteger)item;
@end

@interface ECItemView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, assign) IBOutlet id<ECItemViewDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<ECItemViewDelegate> delegate;
@property (nonatomic) UIEdgeInsets viewInsets;
@property (nonatomic) CGRect itemFrame;
@property (nonatomic) UIEdgeInsets itemInsets;
@property (nonatomic) BOOL allowsSelection;
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
