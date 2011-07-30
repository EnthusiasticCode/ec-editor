//
//  ACBrowserTableCell.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACEditableTableCell.h"
#import "AppStyle.h"

static Class UITableViewCellReorderControlClass = nil;
static Class UITableViewCellEditControlClass = nil;

@implementation ACEditableTableCell {
    UIImageView *checkMarkImageView;
}

@synthesize iconButton, textField;
@synthesize contentInsets;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (!UITableViewCellReorderControlClass)
        UITableViewCellReorderControlClass = NSClassFromString(@"UITableViewCellReorderControl");
    if (!UITableViewCellEditControlClass)
        UITableViewCellEditControlClass = NSClassFromString(@"UITableViewCellEditControl");
    
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        CGRect contentBounds = self.contentView.bounds;
        
        // Initialize and position icon button
        if (!iconButton)
        {
            iconButton = [UIButton new];
            iconButton.adjustsImageWhenDisabled = NO;
            iconButton.adjustsImageWhenHighlighted = NO;
            iconButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
            iconButton.frame = CGRectMake(0, 0, contentBounds.size.height, contentBounds.size.height);
            [self.contentView addSubview:iconButton];
        }
        iconButton.enabled = NO;
        
        // Initialize and position text field
        if (!textField)
        {
            textField = [UITextField new];
            textField.backgroundColor = [UIColor clearColor];
            textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.spellCheckingType = UITextSpellCheckingTypeNo;
            textField.adjustsFontSizeToFitWidth = YES;
            textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            textField.frame = CGRectMake(contentBounds.size.height, 0, contentBounds.size.width - contentBounds.size.height, contentBounds.size.height);
            textField.textColor = [UIColor styleForegroundColor];
            [self.contentView addSubview:textField];
        }
        textField.enabled = NO;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!UIEdgeInsetsEqualToEdgeInsets(contentInsets, UIEdgeInsetsZero))
    {
        CGPoint center;
        if (self.isEditing)
        {
            for (UIView *view in self.subviews)
            {
                if ([view isKindOfClass:UITableViewCellEditControlClass]) {
                    center = view.center;
                    center.x += contentInsets.left;
                    view.center = center;
                }
                else if ([view isKindOfClass:UITableViewCellReorderControlClass]) {
                    center = view.center;
                    center.x -= contentInsets.right;
                    view.center = center;
                }
            }
        }
        
        self.contentView.frame = UIEdgeInsetsInsetRect(self.contentView.frame, contentInsets);
        
        center = self.accessoryView.center;
        center.x -= contentInsets.right;
        self.accessoryView.center = center;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // Enabling content editing
    iconButton.enabled = editing;
    textField.enabled = editing;
    
    // Restyling internal controls
    if (editing)
    {
        for (UIView *view in self.subviews)
        {
            // Save a reference to the left editing image
            if ([view isKindOfClass:UITableViewCellEditControlClass]) {
                for (UIView *eview in view.subviews) {
                    if ([eview isKindOfClass:[UIImageView class]]) {
                        checkMarkImageView = (UIImageView *)eview;
                        break;
                    }
                }
            }
            // TODO uncomment for custom reorder image
//            else if ([view isKindOfClass:UITableViewCellReorderControlClass]) {
//                for (UIView *eview in view.subviews) {
//                    if ([eview isKindOfClass:[UIImageView class]]) {
//                        [(UIImageView *)eview setImage:[UIImage styleReorderControlImage]];
//                        break;
//                    }
//                }
//            }
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted && checkMarkImageView)
        checkMarkImageView.image = [UIImage styleCheckMarkImage];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected && checkMarkImageView)
        checkMarkImageView.image = [UIImage styleCheckMarkImage];
}

@end
