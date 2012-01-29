//
//  ACFileTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <ECFoundation/ECDirectoryPresenter.h>

@class ACToolFiltersView, ACGroup, ACTab;


@interface ACFileTableController : UITableViewController <UISearchBarDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, ECDirectoryPresenterDelegate>

@property (nonatomic, strong) ACTab *tab;
@property (nonatomic, strong) NSURL *directory;

@end
