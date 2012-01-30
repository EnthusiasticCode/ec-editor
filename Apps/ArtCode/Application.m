//
//  Application.m
//  ArtCode
//
//  Created by Uri Baghin on 9/16/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Application.h"
#import "ArtCodeTab.h"
#import "NSURL+Utilities.h"


@interface Application ()
@property (nonatomic) NSUInteger _projectsDirectoryPathComponentsCount;
@end

@implementation Application

@dynamic tabs;

@synthesize _projectsDirectoryPathComponentsCount = __projectsDirectoryPathComponentsCount;

- (ArtCodeTab *)insertTabAtIndex:(NSUInteger)index withInitialURL:(NSURL *)url
{
    ECASSERT(url);
    ArtCodeTab *tab = [NSEntityDescription insertNewObjectForEntityForName:@"Tab" inManagedObjectContext:self.managedObjectContext];
    NSMutableOrderedSet *tabs = [self mutableOrderedSetValueForKey:@"tabs"];
    [tabs insertObject:tab atIndex:index];
    [tab pushURL:url];
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

@end
