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
#import "ACProject.h"

@implementation ACApplication

@dynamic bookmarks;
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

- (void)exchangeTabsAtIndex:(NSUInteger)fromIndex withTabsAtIndex:(NSUInteger)toIndex
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
        }
        case ACObjectTypeProject:
        {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Project"];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @"name", [URL ACObjectName]];
            fetchRequest.predicate = predicate;
            NSArray *projects = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
            id object = nil;
            if ([projects count] > 1)
            {
                ECASSERT(NO); // TODO: handle error by merging project objects together, then set object = newly merged project
            }
            else if ([projects count] == 1)
                object = [projects lastObject];
            return object;
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
            ACProject *project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.managedObjectContext];
            project.name = [URL ACObjectName];
            project.application = self;
            return project;
        }
        case ACObjectTypeApplication:
        case ACObjectTypeUnknown:
        default:
        {
            ECASSERT(NO); // TODO: error handling
        }
    }
}

- (void)deleteObjectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    UNIMPLEMENTED_VOID();
}

@end
