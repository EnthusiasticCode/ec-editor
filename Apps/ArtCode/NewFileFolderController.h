//
//  NewFileFolderController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 31/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewFileFolderController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *folderNameTextField;

- (IBAction)createAction:(id)sender;

@end
