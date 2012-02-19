//
//  FileTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "BrowserController.h"

@class DirectoryPresenter, SmartFilteredDirectoryPresenter;


@interface FileBrowserController : BrowserController <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSURL *directory;
@property (nonatomic, strong, readonly) DirectoryPresenter *directoryPresenter;
@property (nonatomic, strong, readonly) SmartFilteredDirectoryPresenter *openQuicklyPresenter;

@end
