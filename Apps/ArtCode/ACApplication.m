//
//  ACApplication.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACApplication.h"
#import "ACTab.h"
#import "ACURL.h"
#import "ACProjectListItem.h"
#import "ACProject.h"

@implementation ACApplication

@dynamic tabs;
@dynamic projects;

- (void)insertTabAtIndex:(NSUInteger)index
{
    ACTab *tab = [NSEntityDescription insertNewObjectForEntityForName:@"Tab" inManagedObjectContext:self.managedObjectContext];
    NSMutableOrderedSet *tabs = [self mutableOrderedSetValueForKey:@"tabs"];
    [tabs insertObject:tab atIndex:index];
}

- (void)removeTabAtIndex:(NSUInteger)index
{
    [self.managedObjectContext deleteObject:[self.tabs objectAtIndex:index]];
}

- (void)moveTabsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [[self mutableOrderedSetValueForKey:@"tabs"] moveObjectsAtIndexes:indexes toIndex:index];
}

- (void)exchangeTabAtIndex:(NSUInteger)fromIndex withTabAtIndex:(NSUInteger)toIndex
{
    [[self mutableOrderedSetValueForKey:@"tabs"] exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
}

- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [[self mutableOrderedSetValueForKey:@"projects"] moveObjectsAtIndexes:indexes toIndex:index];
}

- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex
{
    [[self mutableOrderedSetValueForKey:@"projects"] exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
}

- (void)objectWithURL:(NSURL *)URL withCompletionHandler:(void (^)(id))completionHandler
{
    ECASSERT([URL isACURL]);
    switch ([URL ACObjectType])
    {
        case ACObjectTypeApplication:
        {
            completionHandler(self);
            break;
        }
        case ACObjectTypeProject:
        {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ProjectListItem"];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"projectURL", URL];
            NSArray *projectListItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
            if (![projectListItems count])
                completionHandler(nil);
            else if ([projectListItems count] > 1)
                ECASSERT(NO); // TODO: malformed core data, fix it
            else
                [[projectListItems lastObject] loadProjectWithCompletionHandler:^(ACProject *project) {
                    completionHandler(project);
                }];
            break;
        }
        case ACObjectTypeUnknown:
        default:
        {
            ECASSERT(NO); // TODO: error handling?
        }
    }
}

- (void)addObjectWithURL:(NSURL *)URL withCompletionHandler:(void (^)(id))completionHandler
{
    ECASSERT([URL isACURL]);
    switch ([URL ACObjectType])
    {
        case ACObjectTypeProject:
        case ACObjectTypeApplication:
        case ACObjectTypeUnknown:
        default:
        {
            ECASSERT(NO); // TODO: error handling
        }
    }
}

- (void)deleteObjectWithURL:(NSURL *)URL withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT([URL isACURL]);
    UNIMPLEMENTED_VOID();
}

@end
