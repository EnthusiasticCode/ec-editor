//
//  ProjectsTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "GridView.h"

@class Application, ArtCodeTab, ProjectCell;


@interface ProjectBrowserController : UIViewController <GridViewDataSource, GridViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSURL *projectsDirectory;

@end


@interface ProjectCell : GridViewCell

@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIImageView *icon;

@end
