//
//  ACUITestViewController.h
//  ArtCodeUITest
//
//  Created by Nicola Peduzzi on 16/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ACUITestViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *toolbarView;
- (IBAction)changeToolbar:(id)sender;

@end
