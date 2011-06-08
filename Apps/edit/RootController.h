//
//  ProjectBrowser.h
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootController : UITableViewController
@property (nonatomic, strong) IBOutlet UIBarButtonItem *addProjectButton;
@property (nonatomic, strong) IBOutlet UIViewController *addProjectController;
- (void)browseFolder:(NSString *)folder;
- (IBAction)addProject:(id)sender;
@end
