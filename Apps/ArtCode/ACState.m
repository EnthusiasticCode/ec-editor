//
//  ACState.m
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"
#import "ACStateInternal.h"
#import "ACProject.h"
#import "ACURL.h"

NSString * const ACStateNodeTypeProject = @"ACStateNodeTypeProject";
NSString * const ACStateNodeTypeFolder = @"ACStateNodeTypeFolder";
NSString * const ACStateNodeTypeGroup = @"ACStateNodeTypeGroup";
NSString * const ACStateNodeTypeSourceFile = @"ACStateNodeTypeSourceFile";

static void * const ACStateProjectURLObservingContext;

@interface ACState ()
{
    NSMutableArray *_projectObjects;
}

/// Adds and removes a project object to the list
- (void)insertProjectObjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index;
- (void)removeProjectObjectWithURL:(NSURL *)URL;

/// Load / save ordered list of projects
- (NSMutableArray *)loadProjectNames;
- (void)saveProjectNames:(NSArray *)projectNames;

@end

@implementation ACState

#pragma mark - Application Level

+ (ACState *)localState
{
    static ACState *localState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localState = [[self alloc] init];
    });
    return localState;
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _projectObjects = [NSMutableArray array];
    [self scanForProjects];
    for (NSString *projectName in [self loadProjectNames])
        [self insertProjectObjectWithURL:[NSURL ACURLForLocalProjectWithName:projectName] atIndex:NSNotFound];
    return self;
}

- (void)scanForProjects
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSMutableArray *projectNames = [self loadProjectNames];
    NSArray *projectURLs = [fileManager contentsOfDirectoryAtURL:[NSURL ACLocalProjectsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:NULL];
    BOOL projectListHasChanged = NO;
    NSMutableArray *deletedProjectsNames = nil;
    for (NSString *projectName in projectNames)
    {
        if ([fileManager fileExistsAtPath:[[[[NSURL ACLocalProjectsDirectory] path] stringByAppendingPathComponent:projectName] stringByAppendingPathExtension:ACProjectBundleExtension]])
            continue;
        if (!projectListHasChanged)
        {
            projectListHasChanged = YES;
            [self willChangeValueForKey:@"projects"];
        }
        if (!deletedProjectsNames)
            deletedProjectsNames = [[NSMutableArray alloc] init];
        [deletedProjectsNames addObject:projectName];
    }
    if (deletedProjectsNames)
        [projectNames removeObjectsInArray:deletedProjectsNames];
    for (NSURL *projectURL in projectURLs)
    {
        if (![[projectURL pathExtension] isEqualToString:ACProjectBundleExtension])
            continue;
        NSString *projectName = [[projectURL lastPathComponent] stringByDeletingPathExtension];
        if ([projectNames containsObject:projectName])
            continue;
        if (!projectListHasChanged)
        {
            projectListHasChanged = YES;
            [self willChangeValueForKey:@"projects"];
        }
        [projectNames addObject:projectName];
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
    if (context == ACStateProjectURLObservingContext)
    {
        NSURL *oldURL = [change objectForKey:NSKeyValueChangeOldKey];
        NSURL *newURL = [change objectForKey:NSKeyValueChangeNewKey];
        ECASSERT(oldURL && newURL && [self indexOfProjectWithURL:oldURL] != NSNotFound);
        NSMutableArray *projectNames = [self loadProjectNames];
        NSUInteger index = [projectNames indexOfObject:[oldURL ACProjectName]];
        [projectNames removeObjectAtIndex:index];
        [projectNames insertObject:[newURL ACProjectName] atIndex:index];
        [self saveProjectNames:projectNames];
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Project Level

- (NSArray *)projects
{
    return [_projectObjects copy];
}

- (BOOL)insertProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index error:(NSError *__autoreleasing *)error
{
    ECASSERT(URL);
    ECASSERT(index <= [_projectObjects count] || index == NSNotFound);
    if (index == NSNotFound)
        index = [_projectObjects count];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:[[[[NSURL ACLocalProjectsDirectory] path] stringByAppendingPathComponent:[URL ACProjectName]] stringByAppendingPathExtension:ACProjectBundleExtension]])
        return NO;
    NSMutableArray *projectNames = [self loadProjectNames];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [projectNames insertObject:[URL ACProjectName] atIndex:index];
    [self saveProjectNames:projectNames];
    [self insertProjectObjectWithURL:URL atIndex:index];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    return YES;
}

- (BOOL)removeProjectWithURL:(NSURL *)URL error:(NSError *__autoreleasing *)error
{
    ECASSERT(URL && [self indexOfProjectWithURL:URL] != NSNotFound);
    NSUInteger index = [self indexOfProjectWithURL:URL];
    NSMutableArray *projectNames = [self loadProjectNames];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [projectNames removeObjectAtIndex:index];
    [self saveProjectNames:projectNames];
    [self removeProjectObjectWithURL:URL];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    return YES;
}

- (id<ACStateNode>)nodeForURL:(NSURL *)URL
{
    for (id<ACStateProject> project in _projectObjects)
        if ([project.name isEqualToString:[URL ACProjectName]])
            return [project nodeForURL:URL];
    return nil;
}

#pragma mark - Internal methods

- (NSUInteger)indexOfProjectWithURL:(NSURL *)URL
{
    ECASSERT(URL);
    NSUInteger index = 0;
    for (id<ACStateProject> project in _projectObjects)
        if ([project.name isEqualToString:[URL ACProjectName]])
            return index;
        else
            ++index;
    return NSNotFound;
}

- (void)setIndex:(NSUInteger)index forProjectWithURL:(NSURL *)URL
{
    ECASSERT(URL);
    ECASSERT(index < [_projectObjects count]);
    NSUInteger oldIndex = [self indexOfProjectWithURL:URL];
    NSMutableArray *projectNames = [self loadProjectNames];
    NSString *projectName = [projectNames objectAtIndex:oldIndex];
    ACProject *project = [_projectObjects objectAtIndex:oldIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] forKey:@"projects"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [projectNames removeObjectAtIndex:oldIndex];
    [projectNames insertObject:projectName atIndex:index];
    [self saveProjectNames:projectNames];
    [_projectObjects removeObjectAtIndex:oldIndex];
    [_projectObjects insertObject:project atIndex:index];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] forKey:@"projects"];
}

#pragma mark - Private methods

- (void)insertProjectObjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index
{
    ECASSERT(URL);
    ECASSERT(index <= [_projectObjects count] || index == NSNotFound);
    if (index == NSNotFound)
        index = [_projectObjects count];
    NSObject<ACStateProject> *project = [[ACProject alloc] initWithURL:URL];
    [project addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:ACStateProjectURLObservingContext];
    [_projectObjects insertObject:project atIndex:index];
}

- (void)removeProjectObjectWithURL:(NSURL *)URL
{
    ECASSERT(URL && [self indexOfProjectWithURL:URL] != NSNotFound);
    NSUInteger index = [self indexOfProjectWithURL:URL];
    NSObject<ACStateProject> *project = [_projectObjects objectAtIndex:index];
    [project removeObserver:self forKeyPath:@"URL" context:ACStateProjectURLObservingContext];
    [_projectObjects removeObjectAtIndex:index];
}

@end
