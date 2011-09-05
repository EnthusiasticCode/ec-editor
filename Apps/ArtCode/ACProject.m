//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACNode.h"
#import "ACURL.h"
#import "ACState.h"
#import "ACStateInternal.h"
#import "ACProjectDocument.h"

static NSString * const ACLocalProjectsSubdirectory = @"ACLocalProjects";

@interface ACProject ()
{
    BOOL _isDeleted;
}
// Designated initializer, returns the ACProject referenced by the ACURL
- (id)initWithURL:(NSURL *)URL;
@property (nonatomic, strong, readonly) ACProjectDocument *document;

// Returns the local projects directory
+ (NSURL *)localProjectsDirectory;

/// Returns a file URL to the bundle of the project referenced by or containing the node referenced by the ACURL
+ (NSURL *)bundleURLForLocalProjectWithURL:(NSURL *)URL;

/// Returns a file URL to the content directory of the project referenced by or containing the node referenced by the ACURL
+ (NSURL *)contentDirectoryURLForLocalProjectWithURL:(NSURL *)URL;

@end

@implementation ACProject

@synthesize expanded = _expanded;
@synthesize document = _document;
@synthesize URL = _URL;
@synthesize rootNode = _rootNode;

- (NSUInteger)tag
{
    if (_isDeleted)
        return 0;
    return 0;
}

- (void)setTag:(NSUInteger)tag
{
    if (_isDeleted)
        return;
}

- (NSString *)name
{
    if (_isDeleted)
        return nil;
    return [[self.URL lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)setName:(NSString *)name
{
    ECASSERT(name);
    ECASSERT([name length]);
    if (_isDeleted)
        return;
    if ([name isEqualToString:self.name])
        return;
    [[ACState sharedState] renameProjectWithURL:self.URL to:name];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *newURL = [NSURL ACURLWithPathComponents:[NSArray arrayWithObject:name]];
    NSURL *documentURL = [[self class] bundleURLForLocalProjectWithURL:self.URL];
    NSURL *newDocumentURL = [[self class] bundleURLForLocalProjectWithURL:newURL];
    [fileManager moveItemAtURL:documentURL toURL:newDocumentURL error:NULL];
    _URL = newURL;
}

- (NSUInteger)index
{
    if (_isDeleted)
        return NSNotFound;
    return [[ACState sharedState] indexOfProjectWithURL:self.URL];
}

- (void)setIndex:(NSUInteger)index
{
    if (_isDeleted)
        return;
    [[ACState sharedState] setIndex:index forProjectWithURL:self.URL];
}

- (NSURL *)URL
{
    if (_isDeleted)
        return nil;
    return _URL;
}

- (ACProjectDocument *)document
{
    if (_isDeleted)
        return nil;
    if (!_document)
    {
        NSURL *documentURL = [[self class] bundleURLForLocalProjectWithURL:self.URL];
        _document = [[ACProjectDocument alloc] initWithFileURL:documentURL];
    }
    return _document;
}

- (NSString *)nodeType
{
    return ACStateNodeTypeProject;
}

- (id)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (!self)
        return nil;
    _URL = URL;
    return self;
}

- (void)delete
{
    [[ACState sharedState] removeProjectWithURL:self.URL];
    _rootNode = nil;
    [_document closeWithCompletionHandler:NULL];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:[[self class] bundleURLForLocalProjectWithURL:self.URL] error:NULL];
    _isDeleted = YES;
}

- (BOOL)isDeleted
{
    return _isDeleted;
}

- (id<ACStateNode>)rootNode
{
    if (_isDeleted)
        return nil;
    if (!_rootNode)
    {
        _rootNode = self.document.rootNode;
        _rootNode.name = self.name;
    }
    return _rootNode;
}

- (NSOrderedSet *)children
{
    return [self.rootNode children];
}

- (id<ACStateNode>)nodeForURL:(NSURL *)URL
{
    if ([URL isEqual:self.URL])
        return self;
    if (![URL isDescendantOfACURL:self.URL])
        return nil;
    NSArray *pathComponents = [URL pathComponents];
    NSUInteger pathComponentsCount = [pathComponents count];
    ACNode *node = self.document.rootNode;
    for (NSUInteger currentPathComponent = 2; currentPathComponent < pathComponentsCount; ++currentPathComponent)
        node = [node childNodeWithName:[pathComponents objectAtIndex:currentPathComponent]];
    return node;
}

+ (id)projectWithURL:(NSURL *)URL withCompletionHandler:(void (^)(BOOL))completionHandler
{
    id project = [[self alloc] initWithURL:URL];
    [[project document] openWithCompletionHandler:completionHandler];
    return project;
}

+ (id)projectWithURL:(NSURL *)URL fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL))completionHandler
{
    id project = [[self alloc] initWithURL:URL];
    [[project document] saveToURL:[[self class] bundleURLForLocalProjectWithURL:URL] forSaveOperation:UIDocumentSaveForCreating completionHandler:completionHandler];
    return project;
}

+ (id)projectWithURL:(NSURL *)URL fromACZAtURL:(NSURL *)ACZFileURL withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(NO);
    return nil;
}

+ (id)projectWithURL:(NSURL *)URL fromZIPAtURL:(NSURL *)ZIPFileURL withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT(NO);
    return nil;
}

#pragma mark - Private methods

+ (void)initialize
{
    // Setup all directiories
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:[[[self class] localProjectsDirectory] path]])
        [fileManager createDirectoryAtURL:[[self class] localProjectsDirectory] withIntermediateDirectories:YES attributes:nil error:NULL];
}

+ (NSURL *)ACLocalProjectsDirectory
{
    return [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ACLocalProjectsSubdirectory];
}

+ (NSURL *)bundleURLForLocalProjectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    return [[[[self class] ACLocalProjectsDirectory] URLByAppendingPathComponent:[[[URL pathComponents] objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] URLByAppendingPathExtension:ACProjectBundleExtension];
}

+ (NSURL *)contentDirectoryURLForLocalProjectWithURL:(NSURL *)URL
{
    ECASSERT([URL isACURL]);
    return [[[[[self class] ACLocalProjectsDirectory] URLByAppendingPathComponent:[[[URL pathComponents] objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] URLByAppendingPathExtension:ACProjectBundleExtension] URLByAppendingPathComponent:ACProjectContentDirectory isDirectory:YES];
}

@end
