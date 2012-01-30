//
//  FileTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "DirectoryPresenter.h"

@class ToolFiltersView, Group, ArtCodeTab;


@interface FileTableController : UITableViewController <UISearchBarDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, DirectoryPresenterDelegate>

@property (nonatomic, strong) ArtCodeTab *tab;
@property (nonatomic, strong) NSURL *directory;

@end
