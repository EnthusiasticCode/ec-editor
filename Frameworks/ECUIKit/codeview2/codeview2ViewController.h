//
//  codeview2ViewController.h
//  codeview2
//
//  Created by Nicola Peduzzi on 02/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECEditCodeView.h"


@interface codeview2ViewController : UIViewController {
    
    UIScrollView *scrollView;
    ECEditCodeView *codeView;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet ECEditCodeView *codeView;

@end
