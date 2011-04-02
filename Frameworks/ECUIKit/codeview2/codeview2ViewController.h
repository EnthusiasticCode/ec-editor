//
//  codeview2ViewController.h
//  codeview2
//
//  Created by Nicola Peduzzi on 02/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView.h"


@interface codeview2ViewController : UIViewController {
    
    UIScrollView *scrollView;
    ECCodeView *codeView;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet ECCodeView *codeView;

- (IBAction)loadSomething:(id)sender;

@end
