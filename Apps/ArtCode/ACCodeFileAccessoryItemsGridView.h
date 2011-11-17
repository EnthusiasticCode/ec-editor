//
//  ACCodeFileAccessoryItemsGridView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCodeFileAccessoryAction;


@interface ACCodeFileAccessoryItemsGridView : UIView

/// Array of ACCodeFileAccessoryAction to be layed out as buttons in this grid view.
@property (nonatomic, copy) NSArray *accessoryActions;

/// The inset to apply to every item in the grid
@property (nonatomic) UIEdgeInsets itemInsents;

/// Size to use for a single item.
@property (nonatomic) CGSize itemSize;

/// Block to be executed when the user select an action item.
@property (nonatomic, copy) void (^didSelectActionItemBlock)(ACCodeFileAccessoryItemsGridView *sender, ACCodeFileAccessoryAction *action);

@end
