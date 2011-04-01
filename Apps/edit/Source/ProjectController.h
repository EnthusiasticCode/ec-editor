//
//  ProjectController.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECCodeView;
@class ECCodeIndex;
@class Project;

@interface ProjectController : UISplitViewController <UITableViewDataSource, UITableViewDelegate>
{
@private
    NSDictionary *textStyles_;
    NSDictionary *diagnosticOverlayStyles_;
    UITapGestureRecognizer *focusRecognizer;
    UIScrollView *_codeScrollView;
}
@property (nonatomic, retain) Project *project;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) IBOutlet ECCodeView *codeView;
@property (nonatomic, retain) ECCodeIndex *codeIndexer;
@property (nonatomic, retain) IBOutlet UIScrollView *codeScrollView;

- (void)loadProjectFromRootDirectory:(NSURL *)rootDirectory;
- (void)loadFile:(NSURL *)file;
- (NSArray *)contentsOfRootDirectory;

- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer;
@end
