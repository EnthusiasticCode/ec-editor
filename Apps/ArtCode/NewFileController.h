//
//  NewFilePopoverController.h
//  ArtCode
//
//  Created by Uri Baghin on 9/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NewFileController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *fileNameTextField;

- (IBAction)createAction:(id)sender;

@end
