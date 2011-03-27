//
//  Project.h
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NSManagedObjectContext;
@class NSManagedObjectModel;
@class NSPersistentStoreCoordinator;


@interface Project : NSObject
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSURL *rootDirectory;
@property (nonatomic, readonly) NSString *name;

- (id)initWithRootDirectory:(NSURL *)rootDirectory;
+ (id)projectWithRootDirectory:(NSURL *)rootDirectory;
@end
