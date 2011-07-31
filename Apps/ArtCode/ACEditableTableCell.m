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
static Class UITableViewCellDeleteConfirmationControlClass = nil;

@implementation ACEditableTableCell {
    __weak UIImageView *checkMarkImageView;
    UIButton *customDeleteActivation;
    ACEditableTableCellCustomDeleteContainerView *customDeleteContainer;
    UIButton *customDeleteButton;
}


@synthesize iconButton, textField;
@synthesize contentInsets, editingContentInsets;
@synthesize customDelete;

#pragma mark - Private Methods

- (void)toggleCustomDeleteAction:(id)sender
{
    CGRect bounds = self.bounds;
    if (!customDeleteContainer)
    {
        customDeleteContainer = [[ACEditableTableCellCustomDeleteContainerView alloc] initWithFrame:bounds];
        //
        customDeleteButton = [[UIButton alloc] initWithFrame:CGRectMake(bounds.size.width - 75 - editingContentInsets.right, editingContentInsets.top, 75, bounds.size.height - editingContentInsets.top - editingContentInsets.bottom)];
        customDeleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [customDeleteButton setTitle:@"Delete" forState:UIControlStateNormal];
        [customDeleteContainer addSubview:customDeleteButton];
        //
        customDeleteButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
        customDeleteButton.titleLabel.font = [UIFont styleFontWithSize:16];
    }
    
    if (customDeleteContainer.superview)
    {
        // Hide
        customDeleteContainer.clipsToBounds = YES;
        [UIView animateWithDuration:0.25 animations:^(void) {
            customDeleteContainer.frame = CGRectMake(bounds.size.width, 0, 0, bounds.size.height);
            customDeleteActivation.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [customDeleteContainer removeFromSuperview];
            customDeleteContainer.clipsToBounds = NO;
        }];
    }
    else
    {
        // Show
        customDeleteContainer.frame = CGRectMake(bounds.size.width, 0, 0, bounds.size.height);
        customDeleteContainer.clipsToBounds = YES;
        [self addSubview:customDeleteContainer];
        [UIView animateWithDuration:0.25 animations:^(void) {
            customDeleteContainer.frame = CGRectMake(bounds.size.width - 80, 0, 80, bounds.size.height);
            customDeleteActivation.transform = CGAffineTransformMakeRotation(M_PI_2);
        } completion:^(BOOL finished) {
            customDeleteContainer.clipsToBounds = NO;
        }];
    }
}

#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (!UITableViewCellReorderControlClass)
        UITableViewCellReorderControlClass = NSClassFromString(@"UITableViewCellReorderControl");
    if (!UITableViewCellEditControlClass)
        UITableViewCellEditControlClass = NSClassFromString(@"UITableViewCellEditControl");
    if (!UITableViewCellDeleteConfirmationControlClass)
        UITableViewCellDeleteConfirmationControlClass = NSClassFromString(@"UITableViewCellDeleteConfirmationControl");
    
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
    
    CGPoint center;
    
    if (!UIEdgeInsetsEqualToEdgeInsets(contentInsets, UIEdgeInsetsZero))
    {        
        self.contentView.frame = UIEdgeInsetsInsetRect(self.contentView.frame, contentInsets);
        
        center = self.accessoryView.center;
        center.x -= contentInsets.right;
        self.accessoryView.center = center;
    }
    
    if (self.isEditing && !UIEdgeInsetsEqualToEdgeInsets(editingContentInsets, UIEdgeInsetsZero))
    {
        for (UIView *view in self.subviews)
        {
            if ([view isKindOfClass:UITableViewCellEditControlClass]) {
                center = view.center;
                center.x += editingContentInsets.left;
                view.center = center;
            }
            else if ([view isKindOfClass:UITableViewCellReorderControlClass]) {
                center = view.center;
                center.x -= editingContentInsets.right;
                view.center = center;
            }
        }
    }
}

#pragma mark - Cell Methods

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
                if (customDelete && self.editingStyle == UITableViewCellEditingStyleNone)
                {
                    if (!customDeleteActivation)
                    {
                        customDeleteActivation = [UIButton new];
                        [customDeleteActivation setImage:[UIImage styleDeleteActivationImage] forState:UIControlStateNormal];
                        [customDeleteActivation addTarget:self action:@selector(toggleCustomDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
                    }
                    CGRect frame = view.frame;
                    [self addSubview:customDeleteActivation];
                    [view removeFromSuperview];
                    if (animated)
                    {
                        frame.origin.x -= frame.size.width;
                        customDeleteActivation.frame = frame;
                        customDeleteActivation.alpha = 0;
                        [UIView animateWithDuration:0.25 animations:^(void) {
                            customDeleteActivation.frame = view.frame;
                            customDeleteActivation.alpha = 1;
                        }];
                    }
                    else
                    {
                       customDeleteActivation.frame = frame; 
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
    else
    {
        if (animated)
        {
            CGRect frame = customDeleteActivation.frame;
            frame.origin.x -= frame.size.width;
            [UIView animateWithDuration:0.25 animations:^(void) {
                customDeleteActivation.frame = frame;
                customDeleteActivation.alpha = 0;
            } completion:^(BOOL finished) {
                [customDeleteActivation removeFromSuperview];
            }];
        }
        else
        {
            [customDeleteActivation removeFromSuperview];
        }
        
        if (customDeleteContainer.superview)
            [self toggleCustomDeleteAction:nil];
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

@implementation ACEditableTableCellCustomDeleteContainerView

@end
