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
@property (nonatomic, strong, readonly) ACProjectDocument *document;
@property (nonatomic, getter = isDeleted) BOOL deleted;
@end

@implementation ACProject

@synthesize document = _document;
@synthesize URL = _URL;
@synthesize deleted = _isDeleted;

- (NSUInteger)tag
{
    if (self.deleted)
        return 0;
    return 0;
}

- (void)setTag:(NSUInteger)tag
{
    if (self.deleted)
        return;
}

- (NSString *)name
{
    if (self.deleted)
        return nil;
    return [self.URL ACProjectName];
}

- (void)setName:(NSString *)name
{
    if (self.deleted)
        return;
    self.URL = [NSURL ACURLForProjectWithName:name];
}

- (NSUInteger)index
{
    if (self.deleted)
        return NSNotFound;
    return [[ACState localState] indexOfProjectWithURL:self.URL];
}

- (void)setIndex:(NSUInteger)index
{
    if (self.deleted)
        return;
    [[ACState localState] setIndex:index forProjectWithURL:self.URL];
}

- (NSURL *)URL
{
    if (self.deleted)
        return nil;
    return _URL;
}

- (void)setURL:(NSURL *)URL
{
    if (self.deleted)
        return;
    ECASSERT(false); // NYI
}

- (ACProjectDocument *)document
{
    if (self.deleted)
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
    return self;
}

- (void)delete
{
    [_document closeWithCompletionHandler:NULL];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    [fileManager removeItemAtURL:self.URL error:NULL];
    self.deleted = YES;
}

- (NSOrderedSet *)children
{
    if (self.deleted)
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
