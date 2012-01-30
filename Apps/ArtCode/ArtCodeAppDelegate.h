//
//  ArtCodeAppDelegate.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Application;
@class SplitViewController, TabController;
@class ToolPanelController;

@interface ArtCodeAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) TabController *tabController;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong, readonly) Application *application;

- (void)saveContext;

@end
