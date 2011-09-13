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
    [archive extractToDirectory:fileURL completionHandler:^(BOOL success) {
        if (!success)
        {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            [fileManager removeItemAtURL:fileURL error:NULL];
            if (completionHandler)
                completionHandler(NO);
            return;
        }
        ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:fileURL];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projectURLs"];
        [_projectURLs insertObject:projectURL atIndex:index];
        [self saveProjects];
        [_projectDocuments setObject:document forKey:projectURL];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projectURLs"];
        if (completionHandler)
            completionHandler(YES);
    }];
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
            [project importFilesFromZIP:ZIPFileURL completionHandler:^(BOOL success) {
                if (!success)
                {
                    [this deleteObjectWithURL:projectURL completionHandler:^(BOOL success) {
                        if (completionHandler)
                            completionHandler(NO);
                    }];
                    return;
                }
                if (completionHandler)
                    completionHandler(YES);
            }];
        };
        if (document.documentState & UIDocumentStateClosed)
            [document openWithCompletionHandler:block];
        else
            block(YES);
    }];
}

#pragma mark - Node level

- (void)objectWithURL:(NSURL *)URL completionHandler:(void (^)(id, ACObjectType))completionHandler
{
    if (![URL isACURL])
        return completionHandler(nil, ACObjectTypeUnknown);
    ACProjectDocument *document = [_projectDocuments objectForKey:[URL ACProjectURL]];
    [document objectWithURL:URL completionHandler:completionHandler];
}

- (void)deleteObjectWithURL:(NSURL *)URL completionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(NO); // NYI
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

/*
 - (ACProjectDocument *)projectDocumentWithURL:(NSURL *)projectURL
 {
 ECASSERT(projectURL);
 return [_projectDocuments objectForKey:projectURL];
 }
 
 - (void)deleteProjectWithURL:(NSURL *)projectURL
 {
 ECASSERT([_projectDocuments objectForKey:projectURL]);
 ECASSERT([_projectURLs containsObject:projectURL]);
 NSUInteger index = [_projectURLs indexOfObject:projectURL];
 [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projectURLs"];
 [_projectURLs removeObjectAtIndex:index];
 [self saveProjects];
 [_projectDocuments removeObjectForKey:projectURL];
 [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projectURLs"];
 NSFileManager *fileManager = [[NSFileManager alloc] init];
 [fileManager removeItemAtURL:[self bundleURLForLocalProjectWithURL:projectURL] error:NULL];
 }
 
 - (void)renameProjectWithURL:(NSURL *)projectURL toName:(NSString *)newProjectName
 {
 ECASSERT([_projectDocuments objectForKey:projectURL]);
 ECASSERT([_projectURLs containsObject:projectURL]);
 NSUInteger index = [_projectURLs indexOfObject:projectURL];
 [_projectURLs replaceObjectAtIndex:index withObject:newProjectName];
 ACProjectDocument *projectDocument = [_projectDocuments objectForKey:projectURL];
 [_projectDocuments removeObjectForKey:projectURL];
 [_projectDocuments setObject:projectDocument forKey:newProjectName];
 NSFileManager *fileManager = [[NSFileManager alloc] init];
 // TODO: check if this is ok when the project is open, or if the document needs to be resaved
 [fileManager moveItemAtURL:[self bundleURLForLocalProjectWithURL:projectURL] toURL:[self bundleURLForLocalProjectWithURL:newProjectName] error:NULL];
 [self saveProjects];
 }
 
*/
