//
//  FileTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@class ToolFiltersView, Group, ArtCodeTab;


@interface FileTableController : UITableViewController <UISearchBarDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) ArtCodeTab *tab;
@property (nonatomic, strong) NSURL *directory;

@end
