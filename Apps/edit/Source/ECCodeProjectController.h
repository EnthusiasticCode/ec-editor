//
//  ECCodeProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECCodeView;
@class ECCodeIndex;
@class ECCodeProject;

@interface ECCodeProjectController : UISplitViewController <UITableViewDataSource, UITableViewDelegate>
{
@private
    NSDictionary *textStyles_;
    NSDictionary *diagnosticOverlayStyles_;
    UITapGestureRecognizer *focusRecognizer;
}
@property (nonatomic, retain) ECCodeProject *project;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) IBOutlet ECCodeView *codeView;
@property (nonatomic, retain) ECCodeIndex *codeIndexer;

- (void)loadProjectFromRootDirectory:(NSURL *)rootDirectory;
- (void)loadFile:(NSURL *)file;
- (NSArray *)contentsOfRootDirectory;

- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer;
@end
