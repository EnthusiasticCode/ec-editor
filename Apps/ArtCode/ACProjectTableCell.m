//
//  ACProjectTableCell.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectTableCell.h"
#import "AppStyle.h"


static NSCache *imagesCache = nil;

@implementation ACProjectTableCell
@synthesize iconButton, iconLabelColor;

- (void)setIconLabelColor:(UIColor *)color
{
    iconLabelColor = color;
    
    UIImage *image = [imagesCache objectForKey:color];
    if (!image)
    {
        image = [UIImage styleProjectImageWithSize:CGSizeMake(32, 33) labelColor:color];
        [imagesCache setObject:image forKey:color];
    }
    
    [iconButton setImage:image forState:UIControlStateNormal];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        //
        
        if (!imagesCache) imagesCache = [NSCache new];
        UIImage *image = [imagesCache objectForKey:[UIColor styleForegroundColor]];
        if (!image)
        {
            image = [UIImage styleProjectImageWithSize:CGSizeMake(32, 33) labelColor:[UIColor styleForegroundColor]];
            [imagesCache setObject:image forKey:[UIColor styleForegroundColor]];
        }
        
        // 
        if (!iconButton)
        {
            iconButton = [UIButton new];
            iconButton.adjustsImageWhenDisabled = NO;
            iconButton.adjustsImageWhenHighlighted = NO;
            [self addSubview:iconButton];
        }
        [iconButton setImage:image forState:UIControlStateNormal];
        [iconButton sizeToFit];
        iconButton.enabled = NO;
        
        //
        static UIFont *cellFont = nil;
        if (!cellFont) cellFont = [UIFont styleFontWithSize:18];

        //
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = cellFont;
        self.textLabel.textColor = [UIColor styleForegroundColor];
        self.textLabel.highlightedTextColor = [UIColor styleForegroundColor];
        self.textLabel.shadowColor = [UIColor styleForegroundShadowColor];
        self.textLabel.shadowOffset = CGSizeMake(0, 1);
        
        //
        static UIImage *disclosureImage = nil;
        if (!disclosureImage)
            disclosureImage = [UIImage styleTableDisclosureImageWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]];
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        self.accessoryView = [[UIImageView alloc] initWithImage:disclosureImage];
        [self addSubview:self.accessoryView];
        
        //
        self.showsReorderControl = YES;
        
        //
//        deleteButton = [ECButton new];
//        deleteButton.cornersToRound = UIRectCornerTopRight | UIRectCornerBottomRight;
//        deleteButton.titleLabel.font = [UIFont styleFontWithSize:14];
//        deleteButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
//        [deleteButton setTitleColor:[UIColor styleForegroundColor] forState:UIControlStateNormal];
//        [deleteButton setTitleShadowColor:[UIColor styleForegroundShadowColor] forState:UIControlStateNormal];
////        [deleteButton setBackgroundColor:[UIColor styleDeleteColor] forState:UIControlStateNormal];
//        [deleteButton setTitle:@"prova" forState:UIControlStateNormal];
        
//        self.editingAccessoryView = deleteButton;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    BOOL editing = self.isEditing;
    CGRect bounds = self.bounds;
    CGFloat middleY = CGRectGetMidY(bounds);
    
    self.contentView.frame = CGRectInset(bounds, 5, 0);
    
    self.accessoryView.center = CGPointMake(bounds.size.width - (editing ? 0 : 35.5), middleY + .5);
    
    for (UIView *view in self.subviews)
    {
        if ([view isKindOfClass:NSClassFromString(@"UITableViewCellReorderControl")]) { //UITableViewCellEditControl
            // TODO also change image
            view.center = CGPointMake(bounds.size.width - 35, middleY);
        }
    }
    
    self.editingAccessoryView.frame = CGRectMake(0, 0, 100, 100);
    
    iconButton.center = CGPointMake(editing ? 35 : 30, middleY);
    
    self.textLabel.frame = CGRectMake(editing ? 60 : 50, 0, bounds.size.width - 100, bounds.size.height);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    iconButton.enabled = editing;
}

@end
