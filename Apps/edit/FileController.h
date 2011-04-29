//
//  FileViewController.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECCodeView.h>

@interface FileController : UIViewController

@property (nonatomic, retain) IBOutlet ECCodeView *codeView;
@property (nonatomic, retain) NSString *file;

- (void)loadFile:(NSString *)file;

@end
