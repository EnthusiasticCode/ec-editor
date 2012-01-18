//
//  ACDirectoryBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Controller used to manage a table view display a drill-down navigation
/// in folders starting from a base URL.
@interface ACDirectoryBrowserController : UITableViewController

/// URL used as base. The controller will not drill-up from this point.
@property (nonatomic, strong) NSURL *baseURL;

/// URL that the controller is currently displaying in its table view.
@property (nonatomic, strong, readonly) NSURL *currentURL;

/// Moves the currentURL back if possible.
- (IBAction)moveBackOneLevelAction:(id)sender;

@end
