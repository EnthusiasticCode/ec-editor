//
//  ECCodeViewController.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECEditCodeView.h>

@interface ECCodeViewController : UIViewController {
@private
    ECEditCodeView *codeView;
    
    UITapGestureRecognizer *focusRecognizer;
}

@property (nonatomic, retain) IBOutlet ECEditCodeView *codeView;

- (IBAction)doSomething:(id)sender;

@end
