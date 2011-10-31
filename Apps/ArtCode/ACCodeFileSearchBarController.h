//
//  ACCodeFileSearchBarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACCodeFileSearchBarController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *findTextField;

- (IBAction)moveResultAction:(id)sender;
- (IBAction)toggleReplaceAction:(id)sender;
- (IBAction)closeBarAction:(id)sender;

@end
