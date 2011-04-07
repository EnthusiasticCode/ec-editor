//
//  AppController.h
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class RootController;
@class ProjectController;

@interface AppController : UINavigationController <UIApplicationDelegate>
@property (nonatomic, retain) IBOutlet UIWindow *window;
- (NSString *)applicationDocumentsDirectory;
@end
