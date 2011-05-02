//
//  ECItemViewElement.h
//  edit
//
//  Created by Uri Baghin on 5/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECItemViewElement : UIView
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, getter = isSelected) BOOL selected;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
@end
