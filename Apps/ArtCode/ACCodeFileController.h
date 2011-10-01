//
//  ACCodeFileController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNavigationTarget.h"

@class ECCodeView, ACFileDocument;

@interface ACCodeFileController : UIViewController <ACNavigationTarget, UITextFieldDelegate>

@property (nonatomic, strong) ACFileDocument *fileDocument;

@property (nonatomic, strong) ECCodeView *codeView;

@end
