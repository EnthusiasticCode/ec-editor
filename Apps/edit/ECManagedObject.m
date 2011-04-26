//
//  ECManagedObject.m
//  edit
//
//  Created by Uri Baghin on 4/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECManagedObject.h"

static NSString *ECManagedObjectIndex = @"index";

@interface ECManagedObjectProxy : NSMutableArray
@end

@implementation ECManagedObjectProxy
@end

@implementation ECManagedObject

- (NSMutableArray *)mutableArrayValueForKey:(NSString *)key
{
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setEntity:[[[[self entity] relationshipsByName] objectForKey:key] destinationEntity]];
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:ECManagedObjectIndex ascending:YES] autorelease];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSArray *array = [[self managedObjectContext] executeFetchRequest:fetchRequest error:NULL];
    return [NSMutableArray arrayWithArray:array];
}

@end
