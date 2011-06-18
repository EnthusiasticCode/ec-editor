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
        self.indentationLevel = 1;
        self.indentationWidth = 5;

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
        
        //
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.accessoryView = [[UIImageView alloc] initWithImage:[UIImage styleDisclosureImage]];
        
        //
//        additionalAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
//        additionalAccessoryView.backgroundColor = [UIColor redColor];
//        [self addSubview:additionalAccessoryView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Repositioning accessory view to account for background insets
    CGPoint accessoryViewCenter = self.accessoryView.center;
    accessoryViewCenter.x -= 5;
    self.accessoryView.center = accessoryViewCenter;
    
//    additionalAccessoryView.center = CGPointMake(100, 10);
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

@end
