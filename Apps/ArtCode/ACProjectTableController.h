//
//  ACProjectsTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "ECGridView.h"
#import "ECDirectoryPresenter.h"

@class ACApplication, ACTab, ACProjectCell;


@interface ACProjectTableController : UIViewController <ECGridViewDataSource, ECGridViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, ECDirectoryPresenterDelegate>

@property (nonatomic, strong) NSURL *projectsDirectory;
@property (nonatomic, strong) ACTab *tab;

@end


@interface ACProjectCell : ECGridViewCell

@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIImageView *icon;

@end
