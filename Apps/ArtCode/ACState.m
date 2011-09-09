//
//  ACState.m
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"
#import "ACProject.h"
#import "ACProjectDocument.h"
#import "ACURL.h"
#import "ECArchive.h"

static NSString * const ACLocalProjectsSubdirectory = @"ACLocalProjects";
static void * const ACStateProjectURLObservingContext;

@interface ACState ()
{
    NSMutableDictionary *_projectObjects;
    NSMutableOrderedSet *_projectURLs;
}

// Load / save ordered list of project URLs from/to app preferences plist
- (void)loadProjects;
- (void)saveProjects;

// Setup / teardown project objects in the project object dictionary
- (void)setupExistingProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index;
- (void)setupProject:(ACProject *)project forURL:(NSURL *)URL atIndex:(NSUInteger)index;

// Deletes a project
- (void)deleteProjectWithURL:(NSURL *)URL;

// Returns the local projects directory
+ (NSURL *)localProjectsDirectory;

// Returns a file URL to the bundle of the project referenced by or containing the node referenced by the ACURL
- (NSURL *)bundleURLForLocalProjectWithURL:(NSURL *)URL;

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

+ (void)initialize
{
    // Setup all directiories
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:[[[self class] localProjectsDirectory] path]])
        [fileManager createDirectoryAtURL:[[self class] localProjectsDirectory] withIntermediateDirectories:YES attributes:nil error:NULL];
}

- (void)loadProjects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _projectObjects = [NSMutableDictionary dictionary];
    _projectURLs = [NSMutableOrderedSet orderedSet];
    for (NSString *projectURL in [defaults arrayForKey:@"projects"])
        [_projectURLs addObject:[NSURL URLWithString:projectURL]];
    for (NSURL *projectURL in _projectURLs)
        [self setupExistingProjectWithURL:projectURL atIndex:NSNotFound];
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
    ECASSERT(oldURL && newURL);
    ECASSERT([_projectObjects objectForKey:oldURL]);
    ECASSERT([_projectURLs containsObject:oldURL]);
    NSUInteger index = [_projectURLs indexOfObject:oldURL];
    [_projectURLs replaceObjectAtIndex:index withObject:newURL];
    ACProject *project = [_projectObjects objectForKey:oldURL];
    [_projectObjects removeObjectForKey:oldURL];
    [_projectObjects setObject:project forKey:newURL];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    // TODO: check if this is ok when the project is open, or if the document needs to be resaved
    [fileManager moveItemAtURL:[self bundleURLForLocalProjectWithURL:oldURL] toURL:[self bundleURLForLocalProjectWithURL:newURL] error:NULL];
    [self saveProjects];
}

#pragma mark - Project Level

- (NSOrderedSet *)projects
{
    // TODO: if this is a bottleneck pass a proxy to optimize access to often used methods (i.e. count)
    NSMutableOrderedSet *projects = [NSMutableOrderedSet orderedSetWithCapacity:[_projectObjects count]];
    for (NSURL *projectURL in _projectURLs)
        [projects addObject:[_projectObjects objectForKey:projectURL]];
    return projects;
}

- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"projects"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [indexes count])] forKey:@"projects"];
    [_projectURLs moveObjectsAtIndexes:indexes toIndex:index];
    [self saveProjects];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"projects"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [indexes count])] forKey:@"projects"];
}

- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex
{
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] forKey:@"projects"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:toIndex] forKey:@"projects"];
    [_projectURLs exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
    [self saveProjects];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] forKey:@"projects"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:toIndex] forKey:@"projects"];
}

- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(URL);
    ECASSERT(index <= [_projectObjects count] || index == NSNotFound);
    if (index == NSNotFound)
        index = [_projectObjects count];
    NSURL *fileURL = [self bundleURLForLocalProjectWithURL:URL];
    ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:fileURL];
    document.projectURL = URL;
    [document saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (!success)
            ECASSERT(NO); // TODO: implement error handling
        ACProject *project = document.project;
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
        [_projectURLs insertObject:URL atIndex:index];
        [self saveProjects];
        [self setupProject:project forURL:URL atIndex:index];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
        if (completionHandler)
            completionHandler(YES);
    }];
}

- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromACZ:(NSURL *)ACZFileURL withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT([URL isACURL]);
    ECASSERT(ACZFileURL);    
    NSURL *fileURL = [self bundleURLForLocalProjectWithURL:URL];
    ECArchive *archive = [[ECArchive alloc] initWithFileURL:ACZFileURL];
    [archive extractToDirectory:fileURL withCompletionHandler:^(BOOL success) {
        if (!success)
            ECASSERT(NO); // TODO: error handling
        ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:fileURL];
        document.projectURL = URL;
        [document openWithCompletionHandler:^(BOOL success) {
            if (!success)
                ECASSERT(NO); // TODO: error handling
            ACProject *project = document.project;
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
            [_projectURLs insertObject:URL atIndex:index];
            [self saveProjects];
            [self setupProject:project forURL:URL atIndex:index];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
            if (completionHandler)
                completionHandler(YES);
        }];
    }];
}

- (void)addNewProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index fromZIP:(NSURL *)ZIPFileURL withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(URL);
    ECASSERT(index <= [_projectObjects count] || index == NSNotFound);
    if (index == NSNotFound)
        index = [_projectObjects count];
    NSURL *fileURL = [self bundleURLForLocalProjectWithURL:URL];
    ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:fileURL];
    document.projectURL = URL;
    [document saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (!success)
            ECASSERT(NO); // TODO: implement error handling
        ACProject *project = document.project;
        [project importFilesFromZIP:ZIPFileURL withCompletionHandler:^(BOOL success) {
            if (!success)
                ECASSERT(NO); // TODO: implement error handling
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
            [_projectURLs insertObject:URL atIndex:index];
            [self saveProjects];
            [self setupProject:project forURL:URL atIndex:index];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
            if (completionHandler)
                completionHandler(YES);
        }];
    }];
}

#pragma mark - Node level

- (ACNode *)nodeWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    id node = [_projectObjects objectForKey:URL];
    if (node)
        return node;
    return [[_projectObjects objectForKey:[URL ACProjectURL]] nodeWithURL:URL];
}

- (void)deleteNodeWithURL:(NSURL *)URL
{
    if ([_projectURLs containsObject:URL])
        return [self deleteProjectWithURL:URL];
}

#pragma mark - Private methods

- (void)setupExistingProjectWithURL:(NSURL *)URL atIndex:(NSUInteger)index
{
    ECASSERT([URL isACURL]);
    ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:[self bundleURLForLocalProjectWithURL:URL]];
    document.projectURL = URL;
    ACProject *project = document.project;
    [self setupProject:project forURL:URL atIndex:index];
}

- (void)setupProject:(ACProject *)project forURL:(NSURL *)URL atIndex:(NSUInteger)index
{
    ECASSERT(project);
    ECASSERT([URL isACURL]);
    [project addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:ACStateProjectURLObservingContext];
    [_projectObjects setObject:project forKey:URL];
}

- (void)deleteProjectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    ECASSERT([_projectObjects objectForKey:URL]);
    ECASSERT([_projectURLs containsObject:URL]);
    NSUInteger index = [_projectURLs indexOfObject:URL];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [_projectURLs removeObjectAtIndex:index];
    [self saveProjects];
    ACProject *project = [_projectObjects objectForKey:URL];
    [project removeObserver:self forKeyPath:@"URL" context:ACStateProjectURLObservingContext];
    [_projectObjects removeObjectForKey:URL];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:[self bundleURLForLocalProjectWithURL:URL] error:NULL];
}

+ (NSURL *)localProjectsDirectory
{
    return [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACLocalProjectsSubdirectory];
}

- (NSURL *)bundleURLForLocalProjectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    return [[[[self class] localProjectsDirectory] URLByAppendingPathComponent:[[[URL pathComponents] objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] URLByAppendingPathExtension:ACProjectBundleExtension];
}

@end
