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
@property (nonatomic, retain) NSIndexPath *indexPath;
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, getter = isSelected) BOOL selected;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
@end
