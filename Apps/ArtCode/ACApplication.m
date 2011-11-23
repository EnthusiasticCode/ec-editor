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

static NSString * const ACProjectListDirectoryName = @"ACLocalProjects";

@interface ACApplication ()
@property (nonatomic) NSUInteger _projectsDirectoryPathComponentsCount;
@end

@implementation ACApplication

@dynamic tabs;

@synthesize _projectsDirectoryPathComponentsCount = __projectsDirectoryPathComponentsCount;

- (ACTab *)insertTabAtIndex:(NSUInteger)index withInitialURL:(NSURL *)url
{
    ECASSERT(url);
    ACTab *tab = [NSEntityDescription insertNewObjectForEntityForName:@"Tab" inManagedObjectContext:self.managedObjectContext];
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

- (NSURL *)projectsDirectory
{
    return [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACProjectListDirectoryName isDirectory:YES];
}

- (NSString *)pathRelativeToProjectsDirectory:(NSURL *)fileURL
{
    if (![fileURL isFileURL])
        return nil;
    NSArray *pathComponents = [[fileURL URLByStandardizingPath] pathComponents];
    if (![[pathComponents subarrayWithRange:NSMakeRange(0, self._projectsDirectoryPathComponentsCount)] isEqualToArray:[[self projectsDirectory] pathComponents]])
        return nil;
    pathComponents = [pathComponents subarrayWithRange:NSMakeRange(self._projectsDirectoryPathComponentsCount, [pathComponents count] - self._projectsDirectoryPathComponentsCount)];
    return [NSString pathWithComponents:pathComponents];
}

- (NSUInteger)_projectsDirectoryPathComponentsCount
{
    if (!__projectsDirectoryPathComponentsCount)
    {
        __projectsDirectoryPathComponentsCount = [[[self projectsDirectory] pathComponents] count];
    }
    return __projectsDirectoryPathComponentsCount;
}

@end
