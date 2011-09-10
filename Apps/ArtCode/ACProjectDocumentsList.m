//
//  ACState.m
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectDocumentsList.h"
#import "ACProject.h"
#import "ACProjectDocument.h"
#import "ECArchive.h"
#import "ECURL.h"

static NSString * const ACLocalProjectsSubdirectory = @"ACLocalProjects";
static void * const ACStateProjectURLObservingContext;

@interface ACProjectDocumentsList ()
{
    NSMutableDictionary *_projectDocuments;
    NSMutableOrderedSet *_projectNames;
}

// Load / save ordered list of project URLs from/to app preferences plist
- (void)loadProjects;
- (void)saveProjects;

// Returns the local projects directory
+ (NSURL *)localProjectsDirectory;

// Returns a file URL to the bundle of the project referenced by or containing the node referenced by the ACURL
- (NSURL *)bundleURLForLocalProjectWithName:(NSString *)projectName;

@end

@implementation ACProjectDocumentsList

#pragma mark - Application Level

+ (ACProjectDocumentsList *)sharedList
{
    static ACProjectDocumentsList *sharedList = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedList = [[self alloc] init];
    });
    return sharedList;
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
    _projectDocuments = [NSMutableDictionary dictionary];
    _projectNames = [NSMutableOrderedSet orderedSet];
    for (NSString *projectName in [defaults arrayForKey:@"projects"])
        [_projectNames addObject:projectName];
    for (NSString *projectName in _projectNames)
    {
        ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:[self bundleURLForLocalProjectWithName:projectName]];
        [_projectDocuments setObject:document forKey:projectName];
    }
}

- (void)saveProjects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[_projectNames array] forKey:@"projects"];
    [defaults synchronize];
}

- (NSOrderedSet *)projectDocuments
{
    // TODO: if this is a bottleneck pass a proxy to optimize access to often used methods (i.e. count)
    NSMutableOrderedSet *projectDocuments = [NSMutableOrderedSet orderedSetWithCapacity:[_projectDocuments count]];
    for (NSString *projectName in _projectNames)
        [projectDocuments addObject:[_projectDocuments objectForKey:projectName]];
    return projectDocuments;
}

- (ACProjectDocument *)projectDocumentWithName:(NSString *)projectName
{
    ECASSERT(projectName);
    return [_projectDocuments objectForKey:projectName];
}

- (void)deleteProjectWithName:(NSString *)projectName
{
    ECASSERT([_projectDocuments objectForKey:projectName]);
    ECASSERT([_projectNames containsObject:projectName]);
    NSUInteger index = [_projectNames indexOfObject:projectName];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    [_projectNames removeObjectAtIndex:index];
    [self saveProjects];
    [_projectDocuments removeObjectForKey:projectName];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:[self bundleURLForLocalProjectWithName:projectName] error:NULL];
}

- (void)renameProjectWithName:(NSString *)projectName toName:(NSString *)newProjectName
{
    ECASSERT([_projectDocuments objectForKey:projectName]);
    ECASSERT([_projectNames containsObject:projectName]);
    NSUInteger index = [_projectNames indexOfObject:projectName];
    [_projectNames replaceObjectAtIndex:index withObject:newProjectName];
    ACProjectDocument *projectDocument = [_projectDocuments objectForKey:projectName];
    [_projectDocuments removeObjectForKey:projectName];
    [_projectDocuments setObject:projectDocument forKey:newProjectName];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    // TODO: check if this is ok when the project is open, or if the document needs to be resaved
    [fileManager moveItemAtURL:[self bundleURLForLocalProjectWithName:projectName] toURL:[self bundleURLForLocalProjectWithName:newProjectName] error:NULL];
    [self saveProjects];
}

- (void)moveProjectsAtIndexes:(NSIndexSet *)indexes toIndex:(NSUInteger)index
{
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"projects"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [indexes count])] forKey:@"projects"];
    [_projectNames moveObjectsAtIndexes:indexes toIndex:index];
    [self saveProjects];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"projects"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, [indexes count])] forKey:@"projects"];
}

- (void)exchangeProjectAtIndex:(NSUInteger)fromIndex withProjectAtIndex:(NSUInteger)toIndex
{
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] forKey:@"projects"];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:toIndex] forKey:@"projects"];
    [_projectNames exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
    [self saveProjects];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] forKey:@"projects"];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:toIndex] forKey:@"projects"];
}

- (void)addNewProjectWithName:(NSString *)projectName atIndex:(NSUInteger)index fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(projectName);
    ECASSERT(index <= [_projectDocuments count] || index == NSNotFound);
    ECASSERT(![_projectDocuments objectForKey:projectName]);
    ECASSERT(![_projectNames containsObject:projectName]);
    if (index == NSNotFound)
        index = [_projectDocuments count];
    NSURL *fileURL = [self bundleURLForLocalProjectWithName:projectName];
    ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:fileURL];
    [document saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        if (!success)
        {
            if (completionHandler)
                completionHandler(NO);
            return;
        }
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
        [_projectNames insertObject:projectName atIndex:index];
        [self saveProjects];
        [_projectDocuments setObject:document forKey:projectName];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
        if (completionHandler)
            completionHandler(YES);
        NSLog(@"document is: %d", [document documentState]);
    }];
}

- (void)addNewProjectWithName:(NSString *)projectName atIndex:(NSUInteger)index fromACZ:(NSURL *)ACZFileURL withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(projectName);
    ECASSERT(index <= [_projectDocuments count] || index == NSNotFound);
    ECASSERT(![_projectDocuments objectForKey:projectName]);
    ECASSERT(![_projectNames containsObject:projectName]);
    ECASSERT(ACZFileURL);
    NSURL *fileURL = [self bundleURLForLocalProjectWithName:projectName];
    ECArchive *archive = [[ECArchive alloc] initWithFileURL:ACZFileURL];
    [archive extractToDirectory:fileURL withCompletionHandler:^(BOOL success) {
        if (!success)
        {
            if (completionHandler)
                completionHandler(NO);
            return;
        }
        ACProjectDocument *document = [[ACProjectDocument alloc] initWithFileURL:fileURL];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
        [_projectNames insertObject:projectName atIndex:index];
        [self saveProjects];
        [_projectDocuments setObject:document forKey:projectName];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"projects"];
        if (completionHandler)
            completionHandler(YES);
    }];
}

#pragma mark - Private methods

+ (NSURL *)localProjectsDirectory
{
    return [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACLocalProjectsSubdirectory];
}

- (NSURL *)bundleURLForLocalProjectWithName:(NSString *)projectName
{
    ECASSERT(projectName);
    return [[[[self class] localProjectsDirectory] URLByAppendingPathComponent:projectName] URLByAppendingPathExtension:ACProjectBundleExtension];
}

@end
