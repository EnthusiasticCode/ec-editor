//
//  ECRelationalTableViewItem.h
//  edit-single-project-ungrouped
//
//  Created by Uri Baghin on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    ECRelationalTableViewItemSelectionStyleNone,
    ECRelationalTableViewItemSelectionStyleBlue,
    ECRelationalTableViewItemSelectionStyleGray
} ECRelationalTableViewItemSelectionStyle;

typedef enum {
    ECRelationalTableViewItemEditingStyleNone,
    ECRelationalTableViewItemEditingStyleDelete,
} ECRelationalTableViewItemEditingStyle;

typedef enum {
    ECRelationalTableViewItemAccessoryNone,                   // don't show any accessory view
    ECRelationalTableViewItemAccessoryDisclosureIndicator,    // regular chevron. doesn't track
    ECRelationalTableViewItemAccessoryDetailDisclosureButton, // blue button w/ chevron. tracks
    ECRelationalTableViewItemAccessoryCheckmark               // checkmark. doesn't track
} ECRelationalTableViewItemAccessoryType;

enum {
    ECRelationalTableViewItemStateDefaultMask                     = 0,
    ECRelationalTableViewItemStateShowingEditControlMask          = 1 << 0,
    ECRelationalTableViewItemStateShowingDeleteConfirmationMask   = 1 << 1
};
typedef NSUInteger ECRelationalTableViewItemStateMask;

@interface ECRelationalTableViewCell : UIView
/*
// Content.  These properties provide direct access to the internal label and image views used by the table view item.  These should be used instead of the content properties below.
@property(nonatomic,readonly,retain) UIImageView  *imageView;   // default is nil.  image view will be created if necessary.

@property(nonatomic,readonly,retain) UILabel      *textLabel;   // default is nil.  label will be created if necessary.

// If you want to customize items by simply adding additional views, you should add them to the content view so they will be positioned appropriately as the item transitions into and out of editing mode.
@property(nonatomic,readonly,retain) UIView       *contentView;

// Equivalent of imageView, for when the item is in a zoomed state.
@property(nonatomic,readonly,retain) UIImageView  *zoomedImageView;

// Equivalent of textLabel, for when the item is in a zoomed state.
@property(nonatomic,readonly,retain) UILabel      *zoomedTextLabel;

// Equivalent of contentView, for when the item is in a zoomed state.
@property(nonatomic,readonly,retain) UIView       *zoomedContentView;

// Default is nil for items in ECRelationalTableViewStylePlain, and non-nil for ECRelationalTableViewStyleGrouped. The 'backgroundView' will be added as a subview behind all other views.
@property(nonatomic,retain) UIView                *backgroundView;

// Default is nil for items in ECRelationalTableViewStylePlain, and non-nil for ECRelationalTableViewStyleGrouped. The 'selectedBackgroundView' will be added as a subview directly above the backgroundView if not nil, or behind all other views. It is added as a subview only when the item is selected. Calling -setSelected:animated: will cause the 'selectedBackgroundView' to animate in and out with an alpha fade.
@property(nonatomic,retain) UIView                *selectedBackgroundView;

@property(nonatomic) ECRelationalTableViewItemSelectionStyle  selectionStyle;             // default is ECRelationalTableViewItemSelectionStyleBlue.
@property(nonatomic,getter=isSelected) BOOL         selected;                   // set selected state (title, image, background). default is NO. animated is NO
@property(nonatomic,getter=isHighlighted) BOOL      highlighted;                // set highlighted state (title, image, background). default is NO. animated is NO
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;                     // animate between regular and selected state
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;               // animate between regular and highlighted state

@property(nonatomic,readonly) ECRelationalTableViewItemEditingStyle editingStyle;         // default is ECRelationalTableViewItemEditingStyleNone. This is set by ECRelationalTableView using the delegate's value for items who customize their appearance accordingly.
@property(nonatomic) BOOL                           showsReorderControl;        // default is NO

@property(nonatomic) ECRelationalTableViewItemAccessoryType   accessoryType;              // default is ECRelationalTableViewItemAccessoryNone. use to set standard type
@property(nonatomic,retain) UIView                 *accessoryView;              // if set, use custom view. ignore accessoryType. tracks if enabled can calls accessory action
@property(nonatomic) ECRelationalTableViewItemAccessoryType   editingAccessoryType;       // default is ECRelationalTableViewItemAccessoryNone. use to set standard type
@property(nonatomic,retain) UIView                 *editingAccessoryView;       // if set, use custom view. ignore editingAccessoryType. tracks if enabled can calls accessory action

@property(nonatomic,getter=isEditing) BOOL          editing;                    // show appropriate edit controls (+/- & reorder). By default -setEditing: calls setEditing:animated: with NO for animated.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

@property(nonatomic,readonly) BOOL                  showingDeleteConfirmation;  // currently showing "Delete" button
*/
@end
