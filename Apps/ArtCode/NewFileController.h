//
//  NewFilePopoverController.h
//  ArtCode
//
//  Created by Uri Baghin on 9/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NewFileController : UIViewController <UITextFieldDelegate>

#pragma mark IB outlets

@property (weak, nonatomic) IBOutlet UITextField *fileNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

- (IBAction)createAction:(id)sender;

#pragma mark Customizable actions

/// URL pointing to a directory containing an ArtCode template.
/// TODO: define ArtCode template.
@property (strong, nonatomic) NSURL *templateDirectoryURL;

@end
