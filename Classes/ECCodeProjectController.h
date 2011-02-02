//
//  ECCodeProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECPopoverTableController;
@class ECCodeIndexer;
@class ECCodeProject;

@interface ECCodeProjectController : UISplitViewController <UITableViewDataSource, UITableViewDelegate> {
    
}
@property (nonatomic, retain) ECCodeProject *project;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) IBOutlet UITextView *codeView;
@property (nonatomic, readonly, retain) NSString *text;
@property (nonatomic, retain) ECCodeIndexer *codeIndexer;
// popovertable used to display completions
@property (nonatomic, retain) ECPopoverTableController *completionPopover;

- (void)applyCompletion:(NSString *)completion;
// display the completion popovertable if possible
- (void)showCompletions;

- (void)loadProject:(NSString *)name from:(NSString *)rootDirectory;
- (void)loadFile:(NSString *)file;
- (NSArray *)contentsOfRootDirectory;

@end
