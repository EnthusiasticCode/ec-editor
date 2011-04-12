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

@interface ECItemView : UIView
@property (nonatomic, assign) IBOutlet id<ECItemViewDataSource> dataSource;
@property (nonatomic) UIEdgeInsets viewInsets;
@property (nonatomic) CGRect itemFrame;
@property (nonatomic) UIEdgeInsets itemInsets;
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
