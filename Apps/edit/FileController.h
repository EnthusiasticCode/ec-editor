//
//  FileViewController.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECCodeView;

@interface FileController : UIViewController
@property (nonatomic, strong) IBOutlet ECCodeView *codeView;
- (IBAction)complete:(id)sender;
@end
