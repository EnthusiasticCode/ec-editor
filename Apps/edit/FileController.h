//
//  FileViewController.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CompletionController;
@class File;
@class ECCodeView;

@interface FileController : UIViewController

@property (nonatomic, retain) IBOutlet ECCodeView *codeView;
@property (nonatomic, retain) File *file;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *completionButton;

- (void)loadFile:(File *)file;
- (IBAction)complete:(id)sender;

@end
