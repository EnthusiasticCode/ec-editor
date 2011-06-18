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


@implementation ACProjectTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
    {
        ACThemeView *themeView = [ACThemeView new];
        themeView.borderColor = [UIColor styleForegroundColor];
        themeView.borderInsets = UIEdgeInsetsMake(7.5, 6.5, 3.5, 7.5);
        themeView.backgroundColor = [UIColor styleBackgroundColor];
        self.backgroundView = themeView;

        // TODO why this make the textlabel background disapear?
        self.textLabel.backgroundColor = [UIColor blueColor];
    }
    return self;
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

@end
