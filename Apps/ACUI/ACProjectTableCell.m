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


//@interface ACProjectTableCell () {
//@private
//    BOOL editingInternal;
//}
//@end
//

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
//        self.editingAccessoryView = [[UIImageView alloc] initWithImage:[UIImage styleDisclosureImage]];
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
    
//    NSLog(@"-");
    for (UIView *view in self.subviews)
    {
//        NSLog(@"%@", [view class]);
        if ([view isKindOfClass:NSClassFromString(@"UITableViewCellReorderControl")]) { //UITableViewCellEditControl
            // TODO also change image
            view.center = CGPointMake(bounds.size.width - 35, middleY);
        }
    }
    
    self.editingAccessoryView.frame = CGRectMake(0, 0, 100, 100);
}

@end
