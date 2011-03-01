//
//  ECCodeViewController.h
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView.h"
#import "ECCodeScrollView.h"

@interface ECCodeViewController : UIViewController {

    ECCodeView *codeView;
    ECCodeScrollView *codeScrollView;
}

@property (nonatomic, retain) IBOutlet ECCodeView *codeView;
@property (nonatomic, retain) IBOutlet ECCodeScrollView *codeScrollView;

@end
