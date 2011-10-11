//
//  ACCodeFileController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNavigationTarget.h"

@class ECCodeView, ACTab;

@interface ACCodeFileController : UIViewController <ACNavigationTarget, UITextFieldDelegate>

@property (nonatomic, strong) NSURL *fileURL;

@property (nonatomic, strong) ACTab *tab;

@property (nonatomic, strong, readonly) ECCodeView *codeView;

@end
