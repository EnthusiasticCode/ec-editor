//
//  ACProjectsTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <ECUIKit/ECGridView.h>

@class ACApplication, ACTab, ACProjectCell;


@interface ACProjectTableController : UIViewController <UITextFieldDelegate, ECGridViewDataSource, ECGridViewDelegate>

@property (nonatomic, strong) NSURL *projectsDirectory;
@property (nonatomic, strong) ACTab *tab;

@end


@interface ACProjectCell : ECGridViewCell

@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIImageView *icon;

@end
