//
//  Project.h
//  edit
//
//  Created by Uri Baghin on 5/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Node, File, NSManagedObjectContext, NSManagedObjectModel, NSPersistentStoreCoordinator;

@interface Project : NSObject
@property (nonatomic, strong) NSString *bundle;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) Node *rootNode;
- (id)initWithBundle:(NSString *)bundle;
- (void)saveContext;
@end
