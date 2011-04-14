//
//  ProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECItemView.h>
@class FileController;
@class ECCodeIndex;
@class Project;

@interface ProjectController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, ECItemViewDelegate>
@property (nonatomic, retain) NSArray *extensionsToShow;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) ECCodeIndex *codeIndex;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet UITableView *tableView;

- (IBAction)edit:(id)sender;
- (IBAction)done:(id)sender;
- (void)loadProject:(NSString *)projectRoot;
@end
