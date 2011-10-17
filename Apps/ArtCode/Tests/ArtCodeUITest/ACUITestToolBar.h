//
//  ACUITestToolBar.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//



@interface ACUITestToolbar : UIToolbar

@property (nonatomic, readonly, strong) UIButton *titleItem;

@property (nonatomic, strong) UIBarButtonItem *toolItem;
- (void)setToolItem:(UIBarButtonItem *)toolItem animated:(BOOL)animated;

@end
