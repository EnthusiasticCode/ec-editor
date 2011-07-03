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
@synthesize titleLabel;
@synthesize iconView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        // TODO Remove when storyboarding reuse identifier is fixed
        //
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.textLabel.backgroundColor = [UIColor clearColor];
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
        self.iconView.image = image;
        self.imageView.image = image;
        [self.imageView sizeToFit];
        
        //
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        static UIImage *disclosureImage = nil;
        if (!disclosureImage)
            disclosureImage = [UIImage styleTableDisclosureImageWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]];
        
        self.accessoryView = [[UIImageView alloc] initWithImage:disclosureImage];
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
