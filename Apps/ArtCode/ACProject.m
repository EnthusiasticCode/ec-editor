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

@interface ACProject ()
{
    BOOL _isDeleted;
}
/// Designated initializer, returns the ACProject referenced by the ACURL
- (id)initWithURL:(NSURL *)URL;
@property (nonatomic, strong, readonly) ACProjectDocument *document;
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
    return [self.URL ACProjectName];
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
    NSURL *newURL = [NSURL ACURLForLocalProjectWithName:name];
    NSURL *documentURL = [self.URL ACProjectBundleURL];
    NSURL *newDocumentURL = [newURL ACProjectBundleURL];
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
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSURL *documentURL = [self.URL ACProjectBundleURL];
        _document = [[ACProjectDocument alloc] initWithFileURL:documentURL];
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        _document.persistentStoreOptions = options;
        if ([fileManager fileExistsAtPath:[documentURL path]]) {
            [_document openWithCompletionHandler:^(BOOL success){
                if (!success) {
                    abort();
                }
            }];
        }
        else {
            [_document saveToURL:documentURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success){
                if (!success) {
                    abort();
                }
            }];
        }
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
    [self document]; // access document immediately so files are created if they don't exist
    return self;
}

- (void)delete
{
    [[ACState sharedState] removeProjectWithURL:self.URL error:NULL];
    _rootNode = nil;
    [_document closeWithCompletionHandler:NULL];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:[self.URL ACProjectBundleURL] error:NULL];
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
    NSArray *pathComponents = [URL pathComponents];
    NSUInteger pathComponentsCount = [pathComponents count];
    if (pathComponentsCount < 2)
        return nil;
    if (![[URL ACProjectName] isEqualToString:self.name])
        return nil;
    if (pathComponentsCount == 2)
        return self;
    if (!self.document)
        return nil;
    ACNode *node = self.document.rootNode;
    for (NSUInteger currentPathComponent = 2; currentPathComponent < pathComponentsCount; ++currentPathComponent)
        node = [node childNodeWithName:[pathComponents objectAtIndex:currentPathComponent]];
    return node;
}

+ (id)projectWithURL:(NSURL *)URL
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:[[URL ACProjectBundleURL] path]])
        return nil;
    return [[self alloc] initWithURL:URL];
}

+ (id)projectWithURL:(NSURL *)URL fromTemplate:(NSString *)templateName withCompletionHandler:(void (^)(BOOL))completionHandler
{
    id project = [[self alloc] initWithURL:URL];
    if (completionHandler)
        completionHandler(project ? YES : NO);
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

@end
