//
//  ACBrowserTableCell.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ACEditableTableCell : UITableViewCell

#pragma mark Editing controls

/// Replaces the default imageView with a button to which custom actions can be attached.
/// The button will be enable only in editing mode.
@property (nonatomic, strong) IBOutlet UIButton *iconButton;

/// Replaces the default textView with an editable text field to which custom actions can be attached.
/// The text field will be enabled only in editing mode.
@property (nonatomic, strong) IBOutlet UITextField *textField;

#pragma mark Layout

/// Insets applied to all controls inside the cell.
@property (nonatomic) UIEdgeInsets contentInsets;

/// Insets applied to all editing controls.
@property (nonatomic) UIEdgeInsets editingContentInsets;

#pragma mark Additional controls

/// Indicate if the cell should show the custom delete controls.
@property (nonatomic, getter = isCustomDelete) BOOL customDelete;

- (void)setColor:(UIColor *)color forIndentationLevel:(NSInteger)indentationLevel animated:(BOOL)animated;

@end


@interface ACEditableTableCellCustomDeleteContainerView : UIView

@end