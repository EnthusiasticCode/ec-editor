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
#import "DirectoryPresenter.h"

@class Application, ArtCodeTab, ProjectCell;


@interface ProjectTableController : UIViewController <GridViewDataSource, GridViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, DirectoryPresenterDelegate>

@property (nonatomic, strong) NSURL *projectsDirectory;
@property (nonatomic, strong) ArtCodeTab *tab;

@end


@interface ProjectCell : GridViewCell

@property (strong, nonatomic) IBOutlet UILabel *title;
@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIImageView *icon;

@end
