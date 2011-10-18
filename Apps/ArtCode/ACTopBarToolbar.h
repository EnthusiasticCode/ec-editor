//
//  ACTopBarToolbar.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACTopBarToolbar : UIToolbar

@property (nonatomic, readonly, strong) UIButton *titleControl;

@property (nonatomic, strong) UIBarButtonItem *toolItem;
- (void)setToolItem:(UIBarButtonItem *)toolItem animated:(BOOL)animated;

@end
