//
//  FileViewController.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECEditCodeView.h>
#import <ECCodeIndexing/ECCodeUnit.h>

@interface FileController : UIViewController

@property (nonatomic, retain) IBOutlet ECEditCodeView *codeView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

- (void)loadFile:(NSString *)file withCodeUnit:(ECCodeUnit *)codeUnit;

@end
