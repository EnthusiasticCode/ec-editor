//
//  Project.h
//  edit
//
//  Created by Uri Baghin on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObjectContext, NSManagedObjectModel, NSPersistentStoreCoordinator;

@interface Project : NSObject
@property (nonatomic, retain) NSString *bundle;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
- (id)initWithBundle:(NSString *)bundle;
- (void)saveContext;
- (NSArray *)nodesInProjectRoot;
@end
