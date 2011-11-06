//
//  ACCodeFileKeyboardAccessoryController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACCodeFileKeyboardAccessoryView.h"

@class ACCodeFileController;

@interface ACCodeFileKeyboardAccessoryController : UIViewController

@property (weak, nonatomic) ACCodeFileController *targetCodeFileController;

@property (nonatomic, readonly, strong) ACCodeFileKeyboardAccessoryView *keyboardAccessoryView;

@end
