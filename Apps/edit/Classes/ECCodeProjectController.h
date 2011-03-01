//
//  ECCodeProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECCodeIndexer;
@class ECCodeProject;

@interface ECCodeProjectController : UISplitViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain) ECCodeProject *project;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) IBOutlet UITextView *codeView;
@property (nonatomic, retain) ECCodeIndexer *codeIndexer;

- (void)applyCompletion:(NSString *)completion;
// display the completion popovertable if possible
- (void)showCompletions;

- (void)loadProjectFromRootDirectory:(NSURL *)rootDirectory;
- (void)loadFile:(NSURL *)file;
- (NSArray *)contentsOfRootDirectory;

@end
