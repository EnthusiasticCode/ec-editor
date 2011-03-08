//
//  ECCodeViewController.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECCodeView.h>

@interface ECCodeViewController : UIViewController {
@private
    ECCodeView *codeView;
    
    UITapGestureRecognizer *focusRecognizer;
}

@property (nonatomic, retain) IBOutlet ECCodeView *codeView;

- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer;

@end
