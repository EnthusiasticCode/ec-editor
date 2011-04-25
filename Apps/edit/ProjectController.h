//
//  ProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECItemView.h>
@class Project, NSManagedObjectContext;

@interface ProjectController : UIViewController <ECItemViewDataSource, ECItemViewDelegate>
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet ECItemView *tableView;
- (IBAction)edit:(id)sender;
- (IBAction)done:(id)sender;
- (void)loadProject:(NSString *)projectRoot;
- (void)loadFile:(NSString *)file;
@end
