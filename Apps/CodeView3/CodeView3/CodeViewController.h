//
//  CodeViewController.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView4.h"

@interface CodeViewController : UIViewController {
    
    UIScrollView *scrollView;
    ECCodeView4 *codeView;
}

@property (nonatomic, retain) IBOutlet ECCodeView4 *codeView;
@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;

- (IBAction)loadTestFileToCodeView:(id)sender;

- (void)updateLayout;

@end
