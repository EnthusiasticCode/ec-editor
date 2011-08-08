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
@end

@implementation ACProject

@synthesize document = _document;
@synthesize URL = _URL;
@synthesize deleted = _isDeleted;

- (NSUInteger)tag
{
    return 0;
}

- (void)setTag:(NSUInteger)tag
{
    
}

- (NSString *)name
{
    return [self.URL ACProjectName];
}

- (void)setName:(NSString *)name
{
    self.URL = [NSURL ACURLForProjectWithName:name];
}

- (NSUInteger)index
{
    return [[ACState sharedState] indexOfProjectWithURL:self.URL];
}

- (void)setIndex:(NSUInteger)index
{
    [[ACState sharedState] setIndex:index forProjectWithURL:self.URL];
}

- (void)setURL:(NSURL *)URL
{
    ECASSERT(false); // NYI
}

- (ACProjectDocument *)document
{
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
    ECASSERT(false); // NYI
}

- (NSOrderedSet *)children
{
    return [_document children];
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
    [_document openWithCompletionHandler:completionHandler];
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
