//
//  ACCodeFileSearchBarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCodeFileController;

@interface ACCodeFileSearchBarController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) ACCodeFileController *targetCodeFileController;

@property (strong, nonatomic) IBOutlet UITextField *findTextField;
@property (strong, nonatomic) IBOutlet UITextField *replaceTextField;

- (IBAction)moveResultAction:(id)sender;
- (IBAction)toggleReplaceAction:(id)sender;
- (IBAction)closeBarAction:(id)sender;

- (IBAction)replaceAllAction:(id)sender;

@end
