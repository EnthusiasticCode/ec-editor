//
//  ArtCodeAppDelegate.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNavigationController.h"

@interface ArtCodeAppDelegate : UIResponder <UIApplicationDelegate, ACNavigationControllerDelegate>

@property (nonatomic, strong) UIWindow *window;

@end