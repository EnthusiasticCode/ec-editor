//
//  ArtCodeAppDelegate.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import "ArtCodeAppDelegate.h"

#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECUIKit/ECCodeViewBase.h>
#import <ECUIKit/UIControl+BlockAction.h>

#import "AppStyle.h"
#import <ECUIKit/ECTabController.h>

#import "ACSingleTabController.h"

#import <ECUIKit/ECTabBar.h>
#import "ACTopBarToolbar.h"
#import "ACTopBarTitleControl.h"
#import "ACCodeFileSearchBarController.h"

#import "ACApplication.h"
#import "ACTab.h"

@implementation ArtCodeAppDelegate

@synthesize window = _window;
@synthesize tabController = _tabController;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize application = _application;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIFont *defaultFont = [UIFont styleFontWithSize:14];    

    ////////////////////////////////////////////////////////////////////////////
    // Generic text field
    id textFieldAppearance = [UITextField appearance];
    [textFieldAppearance setTextColor:[UIColor styleForegroundColor]];
    [textFieldAppearance setFont:defaultFont];
    
    ////////////////////////////////////////////////////////////////////////////
    // Generic popover
    id popoverAppearance = [ACShapePopoverBackgroundView appearance];
//    [popoverAppearance setBackgroundColor:[UIColor colorWithRed:57.0/255.0 green:58.0/255.0 blue:62.0/255.0 alpha:1.0]];
    [popoverAppearance setBackgroundColor:[UIColor colorWithRed:67.0/255.0 green:68.0/255.0 blue:72.0/255.0 alpha:1.0]];
    [(ACShapePopoverBackgroundView *)popoverAppearance setStrokeColor:[UIColor colorWithWhite:0.34 alpha:1]];
    [popoverAppearance setShadowOpacity:0.7];
    [popoverAppearance setShadowRadius:4];
    [popoverAppearance setShadowOffsetForArrowDirectionUpToAutoOrient:CGSizeMake(0, 1)];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"topBar_BackButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 10)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:[[UIImage imageNamed:@"topBar_ToolButton_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 10, 10, 10)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIColor blackColor], UITextAttributeTextShadowColor, [NSValue valueWithUIOffset:UIOffsetMake(0, -1)], UITextAttributeTextShadowOffset, nil]];

    ////////////////////////////////////////////////////////////////////////////
    // Tab Bar    
    id buttonInTabBarAppearance = [ECTabBarButton appearance];
    [buttonInTabBarAppearance setBackgroundImage:[[UIImage imageNamed:@"tabBar_TabBackground_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateNormal];
    [buttonInTabBarAppearance setBackgroundImage:[[UIImage imageNamed:@"tabBar_TabBackground_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateSelected];
    [buttonInTabBarAppearance setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
    [buttonInTabBarAppearance setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [buttonInTabBarAppearance setTitleShadowColor:[UIColor colorWithWhite:0.1 alpha:1] forState:UIControlStateNormal];
    
    [[ECTabBarButtonCloseButton appearance] setImage:[UIImage imageNamed:@"tabBar_TabCloseButton"] forState:UIControlStateNormal];
    
    ////////////////////////////////////////////////////////////////////////////
    // Top bar
    [[ACTopBarToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"topBar_Background"]];
    
    id ACTopBarTitleControlAppearance = [ACTopBarTitleControl appearance];
    [ACTopBarTitleControlAppearance setBackgroundImage:[[UIImage imageNamed:@"topBar_TitleButton_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateNormal];
    [ACTopBarTitleControlAppearance setBackgroundImage:[[UIImage imageNamed:@"topBar_TitleButton_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)] forState:UIControlStateSelected];
    [ACTopBarTitleControlAppearance setBackgroundImage:[UIImage imageNamed:@"topBar_Background"] forState:UIControlStateDisabled];
    [ACTopBarTitleControlAppearance setGapBetweenFragments:3];
    [ACTopBarTitleControlAppearance setContentInsets:UIEdgeInsetsMake(3, 10, 3, 10)];
    [ACTopBarTitleControlAppearance setSelectedTitleFragmentsTint:[UIColor whiteColor]];
    [ACTopBarTitleControlAppearance setSecondaryTitleFragmentsTint:[UIColor colorWithWhite:0.7 alpha:1]];
    [ACTopBarTitleControlAppearance setSelectedFragmentFont:[UIFont boldSystemFontOfSize:20]];
    [ACTopBarTitleControlAppearance setSecondaryFragmentFont:[UIFont systemFontOfSize:14]];
   
    [[ACTopBarToolButton appearance] setBackgroundImage:[[UIImage imageNamed:@"topBar_ToolButton_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(27, 10, 5, 10)] forState:UIControlStateNormal];
    [[ACTopBarToolButton appearance] setBackgroundImage:[[UIImage imageNamed:@"topBar_ToolButton_Selected"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forState:UIControlStateSelected];
    [[ACTopBarToolButton appearanceWhenContainedIn:[ACCodeFileSearchBarView class], nil] setBackgroundImage:[[UIImage imageNamed:@"searchBar_Button_Normal"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)] forState:UIControlStateNormal];
    
    ////////////////////////////////////////////////////////////////////////////
    // Code view elements
    [[ECCodeFlashView appearance] setBackgroundColor:[UIColor redColor]];
    
    ////////////////////////////////////////////////////////////////////////////
    // Creating main tab controllers
    self.tabController = [[ECTabController alloc] init];
    self.tabController.tabBar.backgroundColor = [UIColor blackColor];
    self.tabController.tabBar.tabControlInsets = UIEdgeInsetsMake(3, 3, 0, 3);
    self.tabController.definesPresentationContext = YES;
    // Add tab button
    UIButton *addTabButton = [UIButton new];
    [addTabButton setImage:[UIImage imageNamed:@"tabBar_TabAddButton"] forState:UIControlStateNormal];
    [addTabButton setActionBlock:^(id sender) {
        // Duplicate current tab
        ACSingleTabController *singleTabController = [[ACSingleTabController alloc] init];
        [self.application insertTabAtIndex:[self.application.tabs count] withInitialURL:[(ACSingleTabController *)self.tabController.selectedViewController tab].currentURL];
        singleTabController.tab = [self.application.tabs lastObject];
        [self.tabController addChildViewController:singleTabController animated:YES];
    } forControlEvent:UIControlEventTouchUpInside];
    self.tabController.tabBar.additionalControls = [NSArray arrayWithObject:addTabButton];
    
    ////////////////////////////////////////////////////////////////////////////
    // Setup window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.tabController;

    ////////////////////////////////////////////////////////////////////////////
    // Resume tabs
    if (![self.application.tabs count])
        [self.application insertTabAtIndex:0 withInitialURL:[self.application projectsDirectory]];
    for (ACTab *tab in self.application.tabs)
    {
        ACSingleTabController *singleTabController = [[ACSingleTabController alloc] init];
        singleTabController.tab = tab;
        [self.tabController addChildViewController:singleTabController];
    }
    [self.tabController setTabBarVisible:NO];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (ACApplication *)application
{
    if (_application)
        return _application;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Application"];
    NSArray *applications = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    if ([applications count] == 1)
    {
        _application = [applications lastObject];
    }
    else if ([applications count] > 1)
    {
        ECASSERT(NO); // TODO: handle error by merging application objects together
    }
    else
    {
        _application = [NSEntityDescription insertNewObjectForEntityForName:@"Application" inManagedObjectContext:self.managedObjectContext];
    }
    return _application;
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Application" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:@"com.enthusiasticcode.ArtCode.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager new] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

@end
