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
@property (nonatomic, retain) ECCodeIndexer *codeIndexer;
// popovertable used to display completions
@property (nonatomic, retain) ECPopoverTableController *completionPopover;
@property (nonatomic, retain) NSMutableArray *possibleCompletions;

// display the completion popovertable if possible
- (void)showCompletions;

- (void)loadProject:(NSString *)name from:(NSString *)rootDirectory;
- (void)loadFile:(NSString *)file;
- (NSArray *)contentsOfRootDirectory;

@end
