//
//  ACApplication.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACApplication.h"
#import "ACTab.h"
#import <ECFoundation/NSURL+ECAdditions.h>

static NSString * const ACProjectListDirectoryName = @"ACLocalProjects.weakpkg";

@implementation ACApplication

@dynamic tabs;

- (ACTab *)insertTabAtIndex:(NSUInteger)index
{
    ACTab *tab = [NSEntityDescription insertNewObjectForEntityForName:@"Tab" inManagedObjectContext:self.managedObjectContext];
    NSMutableOrderedSet *tabs = [self mutableOrderedSetValueForKey:@"tabs"];
    [tabs insertObject:tab atIndex:index];
    [tab pushURL:[self projectsDirectory]];
    return tab;
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

- (NSURL *)projectsDirectory
{
    return [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACProjectListDirectoryName];
}

@end
