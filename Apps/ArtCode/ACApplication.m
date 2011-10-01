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

- (id)objectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    switch ([URL ACObjectType])
    {
        case ACObjectTypeApplication:
        {
            return self;
            break;
        }
        case ACObjectTypeProject:
        {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ProjectListItem"];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"projectURL", URL];
            NSArray *projectListItems = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
            if (![projectListItems count])
            {
                return nil;
            }
            else if ([projectListItems count] > 1)
                ECASSERT(NO); // TODO: malformed core data, fix it
            else
                return [projectListItems lastObject];
            break;
        }
        case ACObjectTypeUnknown:
        default:
        {
            ECASSERT(NO); // TODO: error handling?
        }
    }
}

- (id)addObjectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    switch ([URL ACObjectType])
    {
        case ACObjectTypeProject:
        {
            ECASSERT(![self objectWithURL:URL]);
            return nil;
            break;
        }
        case ACObjectTypeApplication:
        case ACObjectTypeUnknown:
        default:
        {
            ECASSERT(NO); // TODO: error handling
            return nil;
        }
    }
}

- (void)deleteObjectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    UNIMPLEMENTED_VOID();
}

@end
