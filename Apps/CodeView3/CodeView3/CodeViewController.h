//
//  CodeViewController.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView3.h"

@interface CodeViewController : UIViewController {
    
    UIScrollView *scrollView;
    ECCodeView3 *codeView;
}

@property (nonatomic, retain) IBOutlet ECCodeView3 *codeView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

- (IBAction)loadTestFileToCodeView:(id)sender;

- (void)updateLayout;

@end
