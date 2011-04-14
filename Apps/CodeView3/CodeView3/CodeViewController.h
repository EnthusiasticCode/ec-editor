//
//  CodeViewController.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView4.h"

@interface CodeViewController : UIViewController

@property (nonatomic, retain) IBOutlet ECCodeView4 *codeView;

- (IBAction)loadTestFileToCodeView:(id)sender;

@end
