//
//  ACTopBarToolbar.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTopBarTitleControl;

@interface ACTopBarToolbar : UIToolbar

@property (nonatomic, readonly, strong) ACTopBarTitleControl *titleControl;

@property (nonatomic, strong) UIBarButtonItem *editItem;

@property (nonatomic, copy) NSArray *toolItems;
- (void)setToolItems:(NSArray *)toolItems animated:(BOOL)animated;

@end
