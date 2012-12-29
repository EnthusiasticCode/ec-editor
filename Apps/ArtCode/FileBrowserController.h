//
//  FileTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SearchableTableBrowserController.h"


@interface FileBrowserController : SearchableTableBrowserController <MFMailComposeViewControllerDelegate>

#pragma mark - Synchronization UI

@property (strong, nonatomic) IBOutlet UILabel *bottomToolBarDetailLabel;
@property (strong, nonatomic) IBOutlet BottomToolBarButton *bottomToolBarSyncButton;

@end
