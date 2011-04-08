//
//  ECPersistentDocument.m
//  edit
//
//  Created by Uri Baghin on 2/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPersistentDocument.h"
#import <CoreData/CoreData.h>

@implementation ECPersistentDocument

- (BOOL)readFromURL:(NSURL *)fileURL ofType:(NSString *)fileType error:(NSError **)error
{
    return [self configurePersistentStoreCoordinatorForURL:fileURL ofType:fileType modelConfiguration:nil storeOptions:nil error:error];
}

- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError **)error
{
    return NO;
}

- (NSManagedObjectContext *)managedObjectContext
{
    return nil;
}

- (id)managedObjectModel
{
    return nil;
}

@end
