//
//  ECItemViewElement.h
//  edit
//
//  Created by Uri Baghin on 5/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECItemView.h"

@interface ECItemViewElement : UIView
@property (nonatomic, assign) ECItemViewElementKey type;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, getter = isSelected) BOOL selected;
@property (nonatomic, getter = isDragged) BOOL dragged;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (void)setDragged:(BOOL)dragged animated:(BOOL)animated;
@end
