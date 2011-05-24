//
//  FileViewController.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView.h"

@interface FileController : UIViewController {
    UIBarButtonItem *completionButton;
}


@property (nonatomic, retain) IBOutlet ECCodeView *codeView;
@property (nonatomic, retain) NSString *file;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *completionButton;

- (void)loadFile:(NSString *)file;
- (IBAction)complete:(id)sender;

@end
