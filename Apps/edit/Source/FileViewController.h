//
//  FileViewController.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ECCodeUnit;
@class ECEditCodeView;

@interface FileViewController : UIViewController
@property (nonatomic, retain) IBOutlet ECEditCodeView *codeView;
- (void)loadFile:(NSURL *)fileURL withCodeUnit:(ECCodeUnit *)codeUnit;
@end
