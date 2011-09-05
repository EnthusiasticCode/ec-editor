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
    NSMutableDictionary *_projectObjects;
    NSMutableArray *_projectURLs;
}

// Load / save ordered list of project URLs
- (void)loadProjects;
- (void)saveProjects;

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
    [self loadProjects];
    return self;
}

- (void)loadProjects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _projectObjects = [NSMutableDictionary dictionary];
    _projectURLs = [NSMutableArray array];
    for (NSString *projectURL in [defaults arrayForKey:@"projects"])
        [_projectURLs addObject:[NSURL URLWithString:projectURL]];
    for (NSURL *projectURL in _projectURLs)
    {
        ACProject *project = [ACProject projectWithURL:projectURL withCompletionHandler:NULL];
        ECASSERT(project);
        [project addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:ACStateProjectURLObservingContext];
        [_projectObjects setObject:project forKey:projectURL];
    }
}

- (void)saveProjects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *projectURLs = [NSMutableArray arrayWithCapacity:[_projectURLs count]];
    for (NSURL *projectURL in _projectURLs)
        [projectURLs addObject:[projectURL absoluteString]];
    [defaults setObject:projectURLs forKey:@"projects"];
    [defaults synchronize];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != ACStateProjectURLObservingContext)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    NSURL *oldURL = [change objectForKey:NSKeyValueChangeOldKey];
    NSURL *newURL = [change objectForKey:NSKeyValueChangeNewKey];
    ECASSERT(oldURL && newURL && [self indexOfProjectWithURL:oldURL] != NSNotFound);
    NSUInteger index = [_projectURLs indexOfObject:oldURL];
    [_projectURLs removeObjectAtIndex:index];
    [_projectURLs insertObject:newURL atIndex:index];
    [self saveProjects];
}

#pragma mark - Project Level

- (NSArray *)projects
{
    // TODO: if this is a bottleneck pass a proxy to optimize access to often used methods (i.e. count)
    NSMutableArray *projects = [NSMutableArray arrayWithCapacity:[_projectObjects count]];
    for (NSURL *projectURL in _projectURLs)
        [projects addObject:[_projectObjects objectForKey:projectURL]];
    return projects;
}

- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(URL);
    ECASSERT(index <= [_projectObjects count] || index == NSNotFound);
    if (index == NSNotFound)
        index = [_projectObjects count];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    ACProject *project = [ACProject projectWithURL:URL fromTemplate:templateName withCompletionHandler:completionHandler];
    [_projectURLs insertObject:URL atIndex:index];
    [self saveProjects];
    [project addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:ACStateProjectURLObservingContext];
    [_projectObjects setObject:project forKey:URL];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
}

- (void)removeProjectWithURL:(NSURL *)URL
{
    ECASSERT(URL && [URL isACURL]);
    ECASSERT(URL && [self indexOfProjectWithURL:URL] != NSNotFound);
    NSUInteger index = [self indexOfProjectWithURL:URL];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [_projectURLs removeObjectAtIndex:index];
    [self saveProjects];
    ACProject *project = [_projectObjects objectForKey:URL];
    [project removeObserver:self forKeyPath:@"URL" context:ACStateProjectURLObservingContext];
    [_projectObjects removeObjectForKey:URL];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
}

- (void)renameProjectWithURL:(NSURL *)URL to:(NSString *)name
{
    ECASSERT(URL && [self indexOfProjectWithURL:URL] != NSNotFound);
    ECASSERT(name);
    ECASSERT([name length]);
    NSUInteger index = [self indexOfProjectWithURL:URL];
    [_projectURLs replaceObjectAtIndex:index withObject:name];
    [self saveProjects];
}

- (id<ACStateNode>)nodeForURL:(NSURL *)URL
{
    ECASSERT(URL && [URL isACURL]);
    id node = [_projectObjects objectForKey:URL];
    if (node)
        return node;
    return [[_projectObjects objectForKey:[URL ACProjectURL]] nodeForURL:URL];
}

#pragma mark - Internal methods

- (NSUInteger)indexOfProjectWithURL:(NSURL *)URL
{
    ECASSERT(URL && [URL isACURL]);
    return [_projectURLs indexOfObject:URL];
}

- (void)setIndex:(NSUInteger)index forProjectWithURL:(NSURL *)URL
{
    ECASSERT(URL && [URL isACURL]);
    ECASSERT(index < [_projectObjects count]);
    NSUInteger oldIndex = [self indexOfProjectWithURL:URL];
    NSString *projectName = [_projectURLs objectAtIndex:oldIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] forKey:@"projects"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [_projectURLs removeObjectAtIndex:oldIndex];
    [_projectURLs insertObject:projectName atIndex:index];
    [self saveProjects];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:oldIndex] forKey:@"projects"];
}

@end
