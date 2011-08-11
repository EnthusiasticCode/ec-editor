//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACModelNode.h"
#import "ACURL.h"
#import "ACState.h"
#import "ACStateInternal.h"
#import "ACProjectDocument.h"

@interface ACProject ()
{
    BOOL _isDeleted;
}
@property (nonatomic, strong, readonly) ACProjectDocument *document;
@end

@implementation ACProject

@synthesize document = _document;
@synthesize URL = _URL;

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
    if (_isDeleted)
        return;
    self.URL = [NSURL ACURLForProjectWithName:name];
}

- (NSUInteger)index
{
    if (_isDeleted)
        return NSNotFound;
    return [[ACState localState] indexOfProjectWithURL:self.URL];
}

- (void)setIndex:(NSUInteger)index
{
    if (_isDeleted)
        return;
    [[ACState localState] setIndex:index forProjectWithURL:self.URL];
}

- (NSURL *)URL
{
    if (_isDeleted)
        return nil;
    return _URL;
}

- (void)setURL:(NSURL *)URL
{
    if (_isDeleted)
        return;
    ECASSERT(false); // NYI
}

- (ACProjectDocument *)document
{
    if (_isDeleted)
        return nil;
    if (!_document)
        _document = [[ACProjectDocument alloc] initWithFileURL:[self.URL ACProjectBundleURL]];
    return _document;
}

- (id)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (!self)
        return nil;
    _URL = URL;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if (![fileManager fileExistsAtPath:[[URL ACProjectBundleURL] path]])
        [fileManager createDirectoryAtURL:[URL ACProjectBundleURL] withIntermediateDirectories:YES attributes:nil error:NULL];
    return self;
}

- (void)delete
{
    [[ACState localState] removeProjectWithURL:self.URL error:NULL];
    _isDeleted = YES;
    [_document closeWithCompletionHandler:NULL];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:self.URL error:NULL];
}

- (BOOL)isDeleted
{
    return _isDeleted;
}

- (NSOrderedSet *)children
{
    if (_isDeleted)
        return nil;
    return [self.document children];
}

- (NSURL *)documentDirectory
{
    return [self.URL ACProjectBundleURL];
}

- (NSURL *)contentDirectory
{
    return [self.URL ACProjectContentURL];
}

- (void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    [self.document openWithCompletionHandler:completionHandler];
}

- (void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    if (!_document)
    {
        completionHandler(YES);
        return;
    }
    [_document closeWithCompletionHandler:completionHandler];
    _document = nil;
}

@end
