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

@class RCIOItem;

@interface FileBrowserController : SearchableTableBrowserController <MFMailComposeViewControllerDelegate>

#pragma mark - Synchronization UI

- (void)scrollToFileSystemItem:(RCIOItem *)item highlight:(BOOL)shouldHighlight;

@end
