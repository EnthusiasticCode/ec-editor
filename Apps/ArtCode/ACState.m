//
//  ACState.m
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateInternal.h"
#import "ACStateProject.h"
#import "ACStateNodeInternal.h"
#import "ACProject.h"
#import "ACURL.h"

static void * const ACStateProjectURLObservingContext;
static void * const ACStateProjectDeletedObservingContext;

@interface ACState ()
{
    NSMutableArray *_projectProxies;
}

/// Adds and removes a project proxy with a given name to the list
- (void)insertProjectProxyWithURL:(NSURL *)URL atIndex:(NSUInteger)index;
- (void)removeProjectProxyWithURL:(NSURL *)URL;

/// Load / save ordered list of projects
- (NSMutableArray *)loadProjectNames;
- (void)saveProjectNames:(NSArray *)projectNames;

@end

@implementation ACState

#pragma mark - Application Level

+ (ACState *)sharedState
{
    static ACState *sharedState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedState = [[self alloc] init];
    });
    return sharedState;
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _projectProxies = [NSMutableOrderedSet orderedSet];
    for (NSString *projectName in [self loadProjectNames])
        [self insertProjectProxyWithURL:[NSURL ACURLForProjectWithName:projectName] atIndex:NSNotFound];
    [self scanForProjects];
    return self;
}

- (NSURL *)stateProjectsDirectory
{
    return [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]];
}

- (void)scanForProjects
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSMutableArray *projectNames = [self loadProjectNames];
    NSArray *projectURLs = [fileManager contentsOfDirectoryAtURL:[self stateProjectsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
    BOOL projectListHasChanged = NO;
    for (NSURL *projectURL in projectURLs)
    {
        if (![[projectURL pathExtension] isEqualToString:ACProjectBundleExtension])
            continue;
        NSString *projectName = [projectURL lastPathComponent];
        if ([projectNames containsObject:projectName])
            continue;
        if (!projectListHasChanged)
        {
            projectListHasChanged = YES;
            [self willChangeValueForKey:@"projects"];
        }
        [projectNames addObject:projectName];
        [self insertProjectProxyWithURL:[NSURL ACURLForProjectWithName:projectName] atIndex:NSNotFound];
    }
    if (projectListHasChanged)
    {
        [self saveProjectNames:projectNames];
        [self didChangeValueForKey:@"projects"];
    }
}

- (NSMutableArray *)loadProjectNames
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [NSMutableArray arrayWithArray:[defaults arrayForKey:@"projects"]];
}

- (void)saveProjectNames:(NSArray *)projectNames
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:projectNames forKey:@"projects"];
    [defaults synchronize];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == ACStateProjectURLObservingContext) {
        NSURL *oldURL = [change objectForKey:NSKeyValueChangeOldKey];
        NSURL *newURL = [change objectForKey:NSKeyValueChangeNewKey];
        ECASSERT(oldURL && newURL && [self indexOfProjectWithURL:oldURL] != NSNotFound);
        NSMutableArray *projectNames = [self loadProjectNames];
        NSUInteger index = [projectNames indexOfObject:[oldURL ACProjectName]];
        [projectNames removeObjectAtIndex:index];
        [projectNames insertObject:[newURL ACProjectName] atIndex:index];
        [self saveProjectNames:projectNames];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Project Level

- (NSArray *)projects
{
    return [_projectProxies copy];
}

- (NSUInteger)indexOfProjectWithURL:(NSURL *)URL
{
    ECASSERT(URL);
    NSUInteger index = 0;
    for (ACStateProject *project in _projectProxies)
        if ([project.name isEqualToString:[URL ACProjectName]])
            return index;
        else
            ++index;
    return NSNotFound;
}

- (void)setIndex:(NSUInteger)index forProjectWithURL:(NSURL *)URL
{
    ECASSERT(URL);
    ECASSERT(index < [_projectProxies count]);
    NSUInteger oldIndex = [self indexOfProjectWithURL:URL];
    NSMutableArray *projectNames = [self loadProjectNames];
    NSString *projectName = [projectNames objectAtIndex:oldIndex];
    ACStateProject *project = [_projectProxies objectAtIndex:oldIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] forKey:@"projects"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [projectNames removeObjectAtIndex:oldIndex];
    [projectNames insertObject:projectName atIndex:index];
    [self saveProjectNames:projectNames];
    [_projectProxies removeObjectAtIndex:oldIndex];
    [_projectProxies insertObject:project atIndex:index];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] forKey:@"projects"];
}

- (void)insertProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index
{
    ECASSERT(URL && [self indexOfProjectWithURL:URL] == NSNotFound);
    ECASSERT(index <= [_projectProxies count] || index == NSNotFound);
    if (index == NSNotFound)
        index = [_projectProxies count];
    NSMutableArray *projectNames = [self loadProjectNames];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [projectNames insertObject:[URL ACProjectName] atIndex:index];
    [self saveProjectNames:projectNames];
    [self insertProjectWithURL:URL atIndex:index];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
}

- (void)deleteProjectWithURL:(NSURL *)URL
{
    ECASSERT(URL && [self indexOfProjectWithURL:URL] != NSNotFound);
    NSUInteger index = [self indexOfProjectWithURL:URL];
    ACStateProject *project = [_projectProxies objectAtIndex:index];
    NSMutableArray *projectNames = [self loadProjectNames];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [projectNames removeObjectAtIndex:index];
    [self saveProjectNames:projectNames];
    [self removeProjectProxyWithURL:URL];
    [project delete];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
}

#pragma mark - Internal methods

- (void)insertProjectProxyWithURL:(NSURL *)URL atIndex:(NSUInteger)index
{
    ECASSERT(URL);
    ECASSERT(index <= [_projectProxies count] || index == NSNotFound);
    if (index == NSNotFound)
        index = [_projectProxies count];
    ACStateProject *project = [[ACStateProject alloc] initWithURL:URL];
    [project addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:ACStateProjectURLObservingContext];
    [project addObserver:self forKeyPath:@"deleted" options:NSKeyValueObservingOptionNew context:ACStateProjectDeletedObservingContext];
    [_projectProxies insertObject:project atIndex:index];
}

- (void)removeProjectProxyWithURL:(NSURL *)URL
{
    ECASSERT(URL && [self indexOfProjectWithURL:URL] != NSNotFound);
    NSUInteger index = [self indexOfProjectWithURL:URL];
    ACStateProject *project = [_projectProxies objectAtIndex:index];
    [project removeObserver:self forKeyPath:@"URL" context:ACStateProjectURLObservingContext];
    [project removeObserver:self forKeyPath:@"deleted" context:ACStateProjectDeletedObservingContext];
    [_projectProxies removeObjectAtIndex:index];
}

@end
