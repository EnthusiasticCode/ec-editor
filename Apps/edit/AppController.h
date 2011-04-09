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
@class FileController;

@interface AppController : UINavigationController <UIApplicationDelegate>
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RootController *rootController;
@property (nonatomic, retain) IBOutlet ProjectController *projectController;
@property (nonatomic, retain) IBOutlet FileController *fileController;
- (NSString *)applicationDocumentsDirectory;
@end
