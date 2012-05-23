//
//  ArtCodeAppDelegate.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TabController;

@interface ArtCodeAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) TabController *tabController;

- (void)saveApplicationStateToDisk;

@end
