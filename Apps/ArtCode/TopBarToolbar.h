//
//  TopBarToolbar.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TopBarTitleControl;

/// The default navigation toolbar for a tab. This bar has (from left to right):
/// - Two buttons to control the tab history;
/// - A special control that works as the title;
/// - Customizable tools buttons;
/// - Customizable edit button.
@interface TopBarToolbar : UIView

#pragma mark Bar buttons

@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UIButton *forwardButton;

@property (nonatomic, strong) IBOutlet TopBarTitleControl *titleControl;

@property (nonatomic, strong) UIBarButtonItem *editItem;

@property (nonatomic, copy) NSArray *toolItems;
- (void)setToolItems:(NSArray *)toolItems animated:(BOOL)animated;

#pragma mark Layout options

/// Image used as background. This image will be streched to cover the entire view.
@property (nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

/// Insets of buttons from the view's frame. Default 7 from every side.
@property (nonatomic) UIEdgeInsets buttonsInsets UI_APPEARANCE_SELECTOR;

/// Gap between controls. Default 10.
@property (nonatomic) CGFloat controlsGap UI_APPEARANCE_SELECTOR;

@end

/// Button used for appearance styling. This button will be used for tool items.
@interface TopBarToolButton : UIButton
@end

/// Button used for appearance styling. This button will be used for the edit button.
@interface TopBarEditButton : TopBarToolButton
@end