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
#import "ECArchive.h"
#import "ECURL.h"
#import "ACURL.h"

static NSString * const ACLocalProjectsSubdirectory = @"ACLocalProjects";
static void * const ACStateProjectURLObservingContext;
static NSString * const ACProjectBundleExtension = @"acproj";

@interface ACState ()
{
    NSMutableDictionary *_projectDocuments;
    NSMutableOrderedSet *_projectURLs;
}

// Load / save ordered list of project URLs from/to app preferences plist
- (void)loadProjects;
- (void)saveProjects;

// Returns the local projects directory
+ (NSURL *)localProjectsDirectory;

// Returns a file URL to the bundle of the project referenced by or containing the node referenced by the ACURL
- (NSURL *)bundleURLForLocalProjectWithURL:(NSURL *)projectURL;

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
    if (![fileManager fileExistsAtPath:[[self localProjectsDirectory] path]])
        [fileManager createDirectoryAtURL:[self localProjectsDirectory] withIntermediateDirectories:YES attributes:nil error:NULL];
}

- (NSOrderedSet *)projectURLs
{
    return [_projectURLs copy];
}

- (void)loadProjectDocumentIfNeededForURL:(NSURL *)URL completionHandler:(void (^)(BOOL))completionHandler
{
    ACProjectDocument *document = [_projectDocuments objectForKey:[URL ACProjectURL]];
    if (document.documentState & UIDocumentStateClosed)
        [document openWithCompletionHandler:completionHandler];
    else
        completionHandler(YES);
}

- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"projectURLs"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [indexes count])] forKey:@"projectURLs"];
    [_projectURLs moveObjectsAtIndexes:indexes toIndex:index];
    [self saveProjects];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"projectURLs"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [indexes count])] forKey:@"projectURLs"];
}

- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex
{
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] forKey:@"projectURLs"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:toIndex] forKey:@"projectURLs"];
    [_projectURLs exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
    [self saveProjects];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] forKey:@"projectURLs"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:toIndex] forKey:@"projectURLs"];
}

- (void)addNewProjectWithURL:(NSURL *)projectURL atIndex:(NSUInteger)index fromTemplate:(NSString *)templateName completionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(projectURL);
    ECASSERT(index <= [_projectDocuments count] || index == NSNotFound);
    ECASSERT(![_projectDocuments objectForKey:projectURL]);
    ECASSERT(![_projectURLs containsObject:projectURL]);
    if (index == NSNotFound)
        index = [_projectDocuments count];
    NSURL *fileURL = [self bundleURLForLocalProjectWithURL:projectURL];
    ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:fileURL];
    document.projectURL = projectURL;
    [document saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (!success)
        {
            if (completionHandler)
                completionHandler(NO);
            return;
        }
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projectURLs"];
        [_projectURLs insertObject:projectURL atIndex:index];
        [self saveProjects];
        [_projectDocuments setObject:document forKey:projectURL];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projectURLs"];
        if (completionHandler)
            completionHandler(YES);
    }];
}

- (void)addNewProjectWithURL:(NSURL *)projectURL atIndex:(NSUInteger)index fromACZ:(NSURL *)ACZFileURL completionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(projectURL);
    ECASSERT(index <= [_projectDocuments count] || index == NSNotFound);
    ECASSERT(![_projectDocuments objectForKey:projectURL]);
    ECASSERT(![_projectURLs containsObject:projectURL]);
    ECASSERT(ACZFileURL);
    NSURL *fileURL = [self bundleURLForLocalProjectWithURL:projectURL];
    ECArchive *archive = [[ECArchive alloc] initWithFileURL:ACZFileURL];
    [archive extractToDirectory:fileURL];
    ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:fileURL];
    document.projectURL = projectURL;
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projectURLs"];
    [_projectURLs insertObject:projectURL atIndex:index];
    [self saveProjects];
    [_projectDocuments setObject:document forKey:projectURL];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projectURLs"];
    if (completionHandler)
        completionHandler(YES);
}

- (void)addNewProjectWithURL:(NSURL *)projectURL atIndex:(NSUInteger)index fromZIP:(NSURL *)ZIPFileURL completionHandler:(void (^)(BOOL))completionHandler
{
    __weak ACState *this = self;
    [self addNewProjectWithURL:projectURL atIndex:index fromTemplate:nil completionHandler:^(BOOL success) {
        if (!success)
        {
            if (completionHandler)
                completionHandler(NO);
            return;
        }
        ACProjectDocument *document = [this->_projectDocuments objectForKey:projectURL];
        ECASSERT(document);
        void(^block)(BOOL) = ^(BOOL success)
        {
            if (!success)
            {
                if (completionHandler)
                    completionHandler(NO);
                return;
            }
            ACProject *project = document.project;
            [project importFilesFromZIP:ZIPFileURL];
            if (completionHandler)
                completionHandler(YES);
        };
        if (document.documentState & UIDocumentStateClosed)
            [document openWithCompletionHandler:block];
        else
            block(YES);
    }];
}

#pragma mark - Node level

- (id)objectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    ACProjectDocument *document = [_projectDocuments objectForKey:[URL ACProjectURL]];
    return [document objectWithURL:URL];
}

- (void)deleteObjectWithURL:(NSURL *)URL
{
    if ([_projectURLs containsObject:URL])
    {
        [[_projectDocuments objectForKey:URL] closeWithCompletionHandler:NULL];
        [self willChangeValueForKey:@"projectURLs"];
        [_projectURLs removeObject:URL];
        [_projectDocuments removeObjectForKey:URL];
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtURL:[self bundleURLForLocalProjectWithURL:URL] error:NULL];
        [self didChangeValueForKey:@"projectURLs"];
    }
    else
        [[_projectDocuments objectForKey:[URL ACProjectURL]] deleteObjectWithURL:URL];
}

- (void)moveObjectAtURL:(NSURL *)fromURL toURL:(NSURL *)toURL
{
    ECASSERT(NO);
}

- (void)moveObjectsAtURLs:(NSArray *)fromURLs toURLs:(NSArray *)toURLs
{
    ECASSERT(NO);
}

- (void)copyObjectAtURL:(NSURL *)fromURL toURL:(NSURL *)toURL
{
    ECASSERT(NO);
}

- (void)copyObjectsAtURLs:(NSArray *)fromURLs toURLs:(NSArray *)toURLs
{
    ECASSERT(NO);
}

#pragma mark - Private methods

- (void)loadProjects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _projectDocuments = [NSMutableDictionary dictionary];
    _projectURLs = [NSMutableOrderedSet orderedSet];
    for (NSString *projectURLAbsoluteString in [defaults arrayForKey:@"projectURLs"])
        [_projectURLs addObject:[NSURL URLWithString:projectURLAbsoluteString]];
    for (NSURL *projectURL in _projectURLs)
    {
        ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:[self bundleURLForLocalProjectWithURL:projectURL]];
        document.projectURL = projectURL;
        [_projectDocuments setObject:document forKey:projectURL];
    }
}

- (void)saveProjects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *projectURLsAbsoluteStrings = [NSMutableArray arrayWithCapacity:[_projectURLs count]];
    for (NSURL *projectURL in _projectURLs)
        [projectURLsAbsoluteStrings addObject:projectURL.absoluteString];
    [defaults setObject:projectURLsAbsoluteStrings forKey:@"projectURLs"];
    [defaults synchronize];
}
+ (NSURL *)localProjectsDirectory
{
    return [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACLocalProjectsSubdirectory];
}

- (NSURL *)bundleURLForLocalProjectWithURL:(NSURL *)projectURL
{
    ECASSERT(projectURL);
    return [[[[self class] localProjectsDirectory] URLByAppendingPathComponent:[projectURL ACProjectName]] URLByAppendingPathExtension:ACProjectBundleExtension];
}

@end
