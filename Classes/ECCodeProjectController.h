//
//  ECCodeProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeProject.h"
#import "ECCodeIndexer.h"
#import "ECPopoverTableController.h"

@interface ECCodeProjectController : UISplitViewController <UITableViewDataSource, UITableViewDelegate> {
    
}
@property (nonatomic, retain, readonly) ECCodeProject *project;
@property (nonatomic, retain, readonly) NSFileManager *fileManager;
@property (nonatomic, retain) IBOutlet UITextView *codeView;
/* An array of all currently loaded completion providers. */
@property (nonatomic, readonly, copy) NSArray *codeIndexers;
// popovertable used to display completions
@property (nonatomic, retain) ECPopoverTableController *completionPopover;

/* Add a new code indexer. It is not checked for duplicity. */
- (void)addCodeIndexer:(id<ECCodeIndexer>)codeIndexer;
// display the completion popovertable if possible
- (void)showCompletions;

- (void)loadProject:(NSString *)name from:(NSString *)rootDirectory;
- (NSArray *)contentsOfRootDirectory;

@end
