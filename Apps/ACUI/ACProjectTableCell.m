//
//  ACProjectTableCell.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectTableCell.h"
#import "ACThemeView.h"

#import "AppStyle.h"

static NSCache *imagesCache = nil;

@implementation ACProjectTableCell

- (BOOL)isEditing
{
    return editingInternal;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        // TODO make this more efficient
        ACThemeView *themeView = [ACThemeView new];
        themeView.borderColor = [UIColor styleForegroundColor];
        themeView.borderInsets = UIEdgeInsetsMake(4.5, 7.5, 4.5, 7.5);
        themeView.backgroundColor = [UIColor styleBackgroundColor];
        self.backgroundView = themeView;
        
        //
        ACThemeView *selectedThemeView = [ACThemeView new];
        selectedThemeView.borderColor = [UIColor styleForegroundColor];
        selectedThemeView.borderInsets = UIEdgeInsetsMake(4.5, 7.5, 4.5, 7.5);
        selectedThemeView.backgroundColor = [UIColor styleBackgroundColor];
        selectedThemeView.backgroundInternalColor = [UIColor styleHighlightColor];
        self.selectedBackgroundView = selectedThemeView;
        
        //
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        // TODO why this make the textlabel background disapear?
        self.textLabel.backgroundColor = [UIColor blueColor];
        self.textLabel.font = [UIFont styleFontWithSize:18];
        self.textLabel.textColor = [UIColor styleForegroundColor];
        self.textLabel.highlightedTextColor = [UIColor styleForegroundColor];
        self.textLabel.shadowColor = [UIColor styleForegroundShadowColor];
        self.textLabel.shadowOffset = CGSizeMake(0, 1);
        
        //
        if (!imagesCache)
            imagesCache = [NSCache new];
        UIImage *image = [imagesCache objectForKey:[UIColor styleForegroundColor]];
        if (!image)
        {
            image = [UIImage styleProjectImageWithSize:CGSizeMake(32, 33) labelColor:[UIColor styleForegroundColor]];
            [imagesCache setObject:image forKey:[UIColor styleForegroundColor]];
        }
        self.imageView.image = image;
        [self.imageView sizeToFit];
        
        //
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage styleDisclosureImage]];
        [self addSubview:self.accessoryView];
        
        //
//        additionalAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
//        additionalAccessoryView.backgroundColor = [UIColor redColor];
//        [self addSubview:additionalAccessoryView];
        
        // Editing

    }
    return self;
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    CGFloat middleY = CGRectGetMidY(bounds);
    
    //
    CGFloat imageCenter = editingInternal ? 33 : 30;
    CGFloat textPosition = 60;
    CGFloat accessoryCenter = editingInternal ? bounds.size.width + 20.5 : bounds.size.width - 30.5;
    
    //
    self.backgroundView.frame = bounds;
    self.selectedBackgroundView.frame = bounds;
    
    //
    self.imageView.center = CGPointMake(imageCenter, middleY);
    
    //
    self.textLabel.frame = CGRectMake(textPosition, 0, bounds.size.width - 120, bounds.size.height);
    
    // 
    self.accessoryView.center = CGPointMake(accessoryCenter, middleY - .5);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    editingInternal = editing;
    
    if (!editing)
    {
        [self addSubview:self.accessoryView];
        [self.editingAccessoryView removeFromSuperview];
    }
    void (^finalizeEditingIn)() = ^() {
        [self.accessoryView removeFromSuperview];
        [self addSubview:self.editingAccessoryView];
    };
    
    if (animated)
    {
        [UIView animateWithDuration:0.10 animations:^(){
            [self layoutSubviews];
        } completion:^(BOOL finished) {
            if (editing) 
                finalizeEditingIn();
        }];
    }
    else
    {
        [self layoutSubviews];
        if (editing)
            finalizeEditingIn();
    }
}

@end
