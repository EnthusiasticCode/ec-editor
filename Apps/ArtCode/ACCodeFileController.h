//
//  ACCodeFileController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECCodeView;

@interface ACCodeFileController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) ECCodeView *codeView;

@end
