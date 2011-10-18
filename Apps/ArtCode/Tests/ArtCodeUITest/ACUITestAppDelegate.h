//
//  ACUITestAppDelegate.h
//  ArtCodeUITest
//
//  Created by Nicola Peduzzi on 16/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTopBarController;

@interface ACUITestAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ACTopBarController *topBarController;

@end
